import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/network/api_config.dart';
import 'package:subscription_track/core/network/internet_checker.dart';

/// สถานะการเชื่อมต่อเครือข่ายและเซิร์ฟเวอร์
enum NetworkStatus {
  /// เชื่อมต่ออินเทอร์เน็ตและเซิร์ฟเวอร์ได้ตามปกติ
  online,

  /// ไม่มีการเชื่อมต่ออินเทอร์เน็ต (ไม่มี Wi-Fi / Cellular)
  noInternet,

  /// เซิร์ฟเวอร์กำลังปิดปรับปรุง (Maintenance Mode)
  serverMaintenance,

  /// มีอินเทอร์เน็ต แต่ไม่สามารถติดต่อกับเซิร์ฟเวอร์ได้ (Server Down / Unreachable)
  serverUnreachable,
}

/// ข้อมูลสถานะการเชื่อมต่อปัจจุบัน
@immutable
class ConnectivityState {
  const ConnectivityState({
    this.status = NetworkStatus.online,
    this.message,
    this.lastChecked,
    this.isChecking = false,
  });

  final NetworkStatus status;
  final String? message;
  final DateTime? lastChecked;
  final bool isChecking;

  bool get isOnline => status == NetworkStatus.online;
  bool get isNoInternet => status == NetworkStatus.noInternet;
  bool get isMaintenance => status == NetworkStatus.serverMaintenance;
  bool get isServerUnreachable => status == NetworkStatus.serverUnreachable;
  bool get hasIssue => status != NetworkStatus.online;

  ConnectivityState copyWith({
    NetworkStatus? status,
    String? message,
    DateTime? lastChecked,
    bool? isChecking,
  }) {
    return ConnectivityState(
      status: status ?? this.status,
      message: message ?? this.message,
      lastChecked: lastChecked ?? this.lastChecked,
      isChecking: isChecking ?? this.isChecking,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectivityState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          message == other.message &&
          isChecking == other.isChecking;

  @override
  int get hashCode => Object.hash(status, message, isChecking);
}

bool get isRunningInFlutterTest =>
    !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

class _TestAlwaysOnlineInternetChecker implements InternetChecker {
  const _TestAlwaysOnlineInternetChecker();

  @override
  Future<bool> hasInternet() async => true;
}

final internetCheckerProvider = Provider<InternetChecker>((ref) {
  if (isRunningInFlutterTest) {
    return const _TestAlwaysOnlineInternetChecker();
  }
  return createInternetChecker();
});

final networkClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

class NetworkStatusNotifier extends Notifier<ConnectivityState> {
  Timer? _pollingTimer;

  static const String defaultMaintenanceMessage =
      'เซิร์ฟเวอร์กำลังปิดปรับปรุงชั่วคราว กรุณาลองใหม่อีกครั้งในภายหลัง';
  static const String defaultNoInternetMessage =
      'ไม่มีการเชื่อมต่ออินเทอร์เน็ต กรุณาเชื่อมต่อ Wi-Fi หรือ Cellular';
  static const String defaultServerUnreachableMessage =
      'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ กรุณาลองใหม่อีกครั้ง';

  @override
  ConnectivityState build() {
    ref.onDispose(() {
      _pollingTimer?.cancel();
    });

    return const ConnectivityState();
  }

  /// เริ่มต้นตรวจสอบเป็นระยะ (Polling)
  void startPolling([Duration interval = const Duration(seconds: 30)]) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) => checkStatus());
  }

  /// ตรวจสอบการเชื่อมต่อกับเซิร์ฟเวอร์และอินเทอร์เน็ต
  Future<void> checkStatus() async {
    if (state.isChecking) return;

    state = state.copyWith(isChecking: true);
    final client = ref.read(networkClientProvider);
    final internetChecker = ref.read(internetCheckerProvider);

    // 1. ตรวจสอบการเชื่อมต่ออินเทอร์เน็ตจริงเป็นอันดับแรกเสมอ
    final hasInternet = await internetChecker.hasInternet();
    if (!hasInternet) {
      state = state.copyWith(
        status: NetworkStatus.noInternet,
        message: defaultNoInternetMessage,
        lastChecked: DateTime.now(),
        isChecking: false,
      );
      return;
    }

    // 2. เมื่อมีอินเทอร์เน็ตแล้ว จึงตรวจสอบสถานะของเซิร์ฟเวอร์
    try {
      final healthUri = Uri.parse('${ApiConfig.baseUrl}/health');
      final response = await client.get(healthUri).timeout(
            const Duration(seconds: 4),
          );

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final data = decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded;
            final isMaintenance = data['status'] == 'maintenance' ||
                decoded['status'] == 'maintenance' ||
                (data['checks'] is Map &&
                    data['checks']['maintenance'] == true) ||
                (decoded['checks'] is Map &&
                    decoded['checks']['maintenance'] == true);
            if (isMaintenance) {
              final maintenanceMsg = (data['message'] as String?) ??
                  (decoded['message'] as String?) ??
                  defaultMaintenanceMessage;
              state = state.copyWith(
                status: NetworkStatus.serverMaintenance,
                message: maintenanceMsg,
                lastChecked: DateTime.now(),
                isChecking: false,
              );
              return;
            }
          }
        } catch (_) {
          // ถ้า body ไม่ใช่ JSON แต่ 200 ให้ถือว่า online
        }

        state = state.copyWith(
          status: NetworkStatus.online,
          message: null,
          lastChecked: DateTime.now(),
          isChecking: false,
        );
        return;
      }

      if (response.statusCode == 503) {
        String msg = defaultMaintenanceMessage;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final serverMsg = decoded['message'];
            if (serverMsg is String && serverMsg.isNotEmpty) {
              msg = serverMsg;
            }
          }
        } catch (_) {}

        state = state.copyWith(
          status: NetworkStatus.serverMaintenance,
          message: msg,
          lastChecked: DateTime.now(),
          isChecking: false,
        );
        return;
      }

      // สถานะ error อื่น ๆ ของ server
      state = state.copyWith(
        status: NetworkStatus.serverUnreachable,
        message: 'ไม่สามารถติดต่อเซิร์ฟเวอร์ได้ (HTTP ${response.statusCode})',
        lastChecked: DateTime.now(),
        isChecking: false,
      );
    } catch (_) {
      // เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์ (แต่อินเทอร์เน็ตมีอยู่)
      state = state.copyWith(
        status: NetworkStatus.serverUnreachable,
        message: defaultServerUnreachableMessage,
        lastChecked: DateTime.now(),
        isChecking: false,
      );
    }
  }

  /// แจ้งผล Failure ที่ได้รับจาก API call ให้ controller อัปเดตสถานะทันที
  void reportFailure(Failure failure) {
    failure.when(
      serverError: (message) {
        if (message.contains('ปิดปรับปรุง') || message.contains('maintenance')) {
          state = state.copyWith(
            status: NetworkStatus.serverMaintenance,
            message: message.isNotEmpty ? message : defaultMaintenanceMessage,
            lastChecked: DateTime.now(),
          );
        } else if (message.contains('ไม่สามารถเชื่อมต่อกับ Server') ||
            message.contains('ไม่สามารถเชื่อมต่อ')) {
          state = state.copyWith(
            status: NetworkStatus.serverUnreachable,
            message: defaultServerUnreachableMessage,
            lastChecked: DateTime.now(),
          );
        }
      },
      networkError: () {
        state = state.copyWith(
          status: NetworkStatus.noInternet,
          message: defaultNoInternetMessage,
          lastChecked: DateTime.now(),
        );
      },
      notFound: () {},
      unauthorized: () {},
      validationError: (_, __) {},
      cacheError: (_) {},
      unknown: (_) {},
    );
  }
}

final networkStatusProvider =
    NotifierProvider<NetworkStatusNotifier, ConnectivityState>(
  NetworkStatusNotifier.new,
);
