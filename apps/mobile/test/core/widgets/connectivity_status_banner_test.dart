import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/core/network/network_status.dart';
import 'package:subscription_track/core/widgets/connectivity_status_banner.dart';

class _FakeNetworkStatusNotifier extends NetworkStatusNotifier {
  _FakeNetworkStatusNotifier(this._initial);
  final ConnectivityState _initial;
  int checkStatusCallCount = 0;

  @override
  ConnectivityState build() => _initial;

  @override
  Future<void> checkStatus() async {
    checkStatusCallCount++;
  }
}

void main() {
  Widget buildTestWidget(ConnectivityState state, {NetworkStatusNotifier? customNotifier}) {
    return ProviderScope(
      overrides: [
        networkStatusProvider.overrideWith(
          () => customNotifier ?? _FakeNetworkStatusNotifier(state),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: ConnectivityStatusBanner(),
        ),
      ),
    );
  }

  testWidgets('ไม่แสดงผลแบนเนอร์เมื่อเชื่อมต่อ online ปกติ', (tester) async {
    await tester.pumpWidget(buildTestWidget(
      const ConnectivityState(status: NetworkStatus.online),
    ));

    expect(find.byType(ConnectivityStatusBanner), findsOneWidget);
    expect(find.text('ไม่มีการเชื่อมต่ออินเทอร์เน็ต'), findsNothing);
    expect(find.text('เซิร์ฟเวอร์กำลังปิดปรับปรุง'), findsNothing);
    expect(find.text('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้'), findsNothing);
  });

  testWidgets('แสดงแบนเนอร์สีแดงเมื่อไม่มีอินเทอร์เน็ต (noInternet)', (tester) async {
    await tester.pumpWidget(buildTestWidget(
      const ConnectivityState(
        status: NetworkStatus.noInternet,
        message: 'กรุณาเชื่อมต่ออินเทอร์เน็ต',
      ),
    ));

    expect(find.text('ไม่มีการเชื่อมต่ออินเทอร์เน็ต'), findsOneWidget);
    expect(find.text('กรุณาเชื่อมต่ออินเทอร์เน็ต'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
  });

  testWidgets('แสดงแบนเนอร์เมื่อเซิร์ฟเวอร์ปิดปรับปรุง (serverMaintenance)', (tester) async {
    await tester.pumpWidget(buildTestWidget(
      const ConnectivityState(
        status: NetworkStatus.serverMaintenance,
        message: 'เซิร์ฟเวอร์กำลังปิดปรับปรุงชั่วคราว',
      ),
    ));

    expect(find.text('เซิร์ฟเวอร์กำลังปิดปรับปรุง'), findsOneWidget);
    expect(find.text('เซิร์ฟเวอร์กำลังปิดปรับปรุงชั่วคราว'), findsOneWidget);
    expect(find.byIcon(Icons.construction_rounded), findsOneWidget);
  });

  testWidgets('แสดงแบนเนอร์เมื่อไม่สามารถติดต่อเซิร์ฟเวอร์ได้ (serverUnreachable)', (tester) async {
    await tester.pumpWidget(buildTestWidget(
      const ConnectivityState(
        status: NetworkStatus.serverUnreachable,
        message: 'ไม่สามารถเชื่อมต่อได้',
      ),
    ));

    expect(find.text('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้'), findsOneWidget);
    expect(find.text('ไม่สามารถเชื่อมต่อได้'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
  });

  testWidgets('กดปุ่ม "ลองใหม่" แล้วเรียก checkStatus()', (tester) async {
    final notifier = _FakeNetworkStatusNotifier(
      const ConnectivityState(status: NetworkStatus.noInternet),
    );

    await tester.pumpWidget(buildTestWidget(
      const ConnectivityState(status: NetworkStatus.noInternet),
      customNotifier: notifier,
    ));

    expect(find.text('ลองใหม่'), findsOneWidget);
    await tester.tap(find.text('ลองใหม่'));
    await tester.pump();

    expect(notifier.checkStatusCallCount, 1);
  });
}
