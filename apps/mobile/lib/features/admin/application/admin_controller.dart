import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/admin/data/admin_repository.dart';
import 'package:subscription_track/features/admin/domain/admin_package.dart';
import 'package:subscription_track/features/admin/domain/admin_stats.dart';
import 'package:subscription_track/features/admin/domain/admin_user.dart';
import 'package:subscription_track/features/admin/domain/admin_user_detail.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';
import 'package:subscription_track/features/auth/data/remote_auth_repository.dart';

@immutable
class AdminState {
  const AdminState({
    this.isLoading = false,
    this.isActionLoading = false,
    this.isAdminAuthenticated = false,
    this.stats = const AdminStats(),
    this.users = const [],
    this.packages = const [],
    this.errorMessage,
    this.successMessage,
  });

  final bool isLoading;
  final bool isActionLoading;
  final bool isAdminAuthenticated;
  final AdminStats stats;
  final List<AdminUser> users;
  final List<AdminPackage> packages;
  final String? errorMessage;
  final String? successMessage;

  AdminState copyWith({
    bool? isLoading,
    bool? isActionLoading,
    bool? isAdminAuthenticated,
    AdminStats? stats,
    List<AdminUser>? users,
    List<AdminPackage>? packages,
    String? errorMessage,
    String? successMessage,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      isAdminAuthenticated: isAdminAuthenticated ?? this.isAdminAuthenticated,
      stats: stats ?? this.stats,
      users: users ?? this.users,
      packages: packages ?? this.packages,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return RemoteAdminRepository();
});

bool isTokenAdmin(String? token) {
  if (token == null || token.isEmpty) return false;
  try {
    final parts = token.split('.');
    if (parts.length < 2) return false;
    final normalized = base64Url.normalize(parts[1]);
    final payloadJson = utf8.decode(base64Url.decode(normalized));
    final Map<String, dynamic> payload =
        jsonDecode(payloadJson) as Map<String, dynamic>;
    return payload['role'] == 'ADMIN';
  } catch (_) {
    return false;
  }
}

/// ตรวจสอบว่าผู้ใช้ปัจจุบันมีบทบาทระดับ ADMIN หรือไม่ โดยดูจาก token ปัจจุบัน
final isAdminUserProvider = FutureProvider<bool>((ref) async {
  // รีรันเมื่อสถานะการล็อกอินของผู้ใช้เปลี่ยน
  ref.watch(authProvider);

  final token = await RemoteAuthRepository.readStoredAuthToken();
  return isTokenAdmin(token);
});

class AdminController extends Notifier<AdminState> {
  @override
  AdminState build() {
    ref.listen(authProvider, (_, __) {
      Future.microtask(loadAll);
    });
    Future.microtask(_initialLoad);
    return const AdminState(isLoading: true);
  }

  AdminRepository get _repo => ref.read(adminRepositoryProvider);
  bool _initialized = false;
  bool _isLoadingAll = false;

  Future<void> _initialLoad() async {
    if (_initialized) return;
    await loadAll();
  }

  Future<void> loadAll() async {
    if (_isLoadingAll) return;
    _initialized = true;
    _isLoadingAll = true;
    final repo = _repo;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final statsRes = await repo.getStats();
      if (!ref.mounted) return;
      final usersRes = await repo.getUsers();
      if (!ref.mounted) return;
      final packagesRes = await repo.getPackages();
      if (!ref.mounted) return;

      final stats = statsRes.fold((_) => state.stats, (s) => s);
      final users = usersRes.fold((_) => state.users, (u) => u);
      final packages = packagesRes.fold((_) => state.packages, (p) => p);

      final hasSuccess = statsRes.isRight() && usersRes.isRight() && packagesRes.isRight();
      final hasFailure = statsRes.isLeft() || usersRes.isLeft() || packagesRes.isLeft();

      String? error;
      if (hasFailure && hasSuccess) {
        error = 'ไม่สามารถโหลดข้อมูลผู้ดูแลระบบบางส่วนได้ กรุณาตรวจสอบการเชื่อมต่อ';
      }

      state = state.copyWith(
        isLoading: false,
        isAdminAuthenticated: hasSuccess,
        stats: stats,
        users: users,
        packages: packages,
        errorMessage: error,
      );
    } finally {
      _isLoadingAll = false;
    }
  }

  Future<bool> loginAsAdmin({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isActionLoading: true, errorMessage: null);
    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.loginWithEmail(
      email: email,
      password: password,
    );

    if (!ref.mounted) return false;

    return result.fold(
      (failure) {
        state = state.copyWith(
          isActionLoading: false,
          errorMessage: 'อีเมลหรือรหัสผ่านไม่ถูกต้อง หรือไม่มีสิทธิ์เข้าถึงผู้ดูแล',
        );
        return false;
      },
      (user) async {
        await loadAll();
        if (!ref.mounted) return false;
        if (!state.isAdminAuthenticated) {
          state = state.copyWith(
            isActionLoading: false,
            errorMessage: 'บัญชีนี้ไม่มีสิทธิ์เข้าถึงระบบผู้ดูแล (ไม่ใช่ระดับ ADMIN)',
          );
          return false;
        }
        state = state.copyWith(
          isActionLoading: false,
          successMessage: 'ยินดีต้อนรับผู้ดูแลระบบ ${user.name}',
        );
        return true;
      },
    );
  }

  Future<void> logoutAdmin() async {
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.logout();
    if (!ref.mounted) return;
    state = const AdminState(
      isAdminAuthenticated: false,
      successMessage: 'ออกจากระบบผู้ดูแลเรียบร้อยแล้ว',
    );
  }

  Future<bool> createPackage({
    required String name,
    required String category,
    required double defaultPrice,
    String billingCycle = 'MONTHLY',
    String brandColor = '#3B82F6',
    String? iconUrl,
    String? description,
  }) async {
    final repo = _repo;
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    final result = await repo.createPackage(
      name: name,
      category: category,
      defaultPrice: defaultPrice,
      billingCycle: billingCycle,
      brandColor: brandColor,
      iconUrl: iconUrl,
      description: description,
    );

    if (!ref.mounted) return false;

    return result.fold(
      (failure) {
        state = state.copyWith(
          isActionLoading: false,
          errorMessage: 'ไม่สามารถเพิ่มบริการได้: ${failure.toString()}',
        );
        return false;
      },
      (newPkg) {
        final updatedPackages = [newPkg, ...state.packages];
        final updatedStats = AdminStats(
          totalUsers: state.stats.totalUsers,
          totalSubscriptions: state.stats.totalSubscriptions,
          totalCards: state.stats.totalCards,
          totalPackages: state.stats.totalPackages + 1,
        );

        state = state.copyWith(
          isActionLoading: false,
          packages: updatedPackages,
          stats: updatedStats,
          successMessage: 'เพิ่มบริการ ${newPkg.name} สำเร็จ',
        );
        return true;
      },
    );
  }

  Future<bool> updatePackage(
    String id, {
    String? name,
    String? category,
    double? defaultPrice,
    String? billingCycle,
    String? brandColor,
    String? iconUrl,
    String? description,
  }) async {
    final repo = _repo;
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    final result = await repo.updatePackage(
      id,
      name: name,
      category: category,
      defaultPrice: defaultPrice,
      billingCycle: billingCycle,
      brandColor: brandColor,
      iconUrl: iconUrl,
      description: description,
    );

    if (!ref.mounted) return false;

    return result.fold(
      (failure) {
        state = state.copyWith(
          isActionLoading: false,
          errorMessage: 'แก้ไขบริการไม่สำเร็จ: ${failure.toString()}',
        );
        return false;
      },
      (updatedPkg) {
        final updatedPackages = state.packages.map((p) {
          return p.id == id ? updatedPkg : p;
        }).toList();

        state = state.copyWith(
          isActionLoading: false,
          packages: updatedPackages,
          successMessage: 'บันทึกการแก้ไขบริการ ${updatedPkg.name} สำเร็จ',
        );
        return true;
      },
    );
  }

  Future<bool> togglePackageActive(String id, bool isActive) async {
    final repo = _repo;
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    final result = await repo.togglePackageActive(id, isActive);
    if (!ref.mounted) return false;

    return result.fold(
      (failure) {
        state = state.copyWith(
          isActionLoading: false,
          errorMessage: 'เปลี่ยนสถานะบริการไม่สำเร็จ',
        );
        return false;
      },
      (updatedPkg) {
        final updatedPackages = state.packages.map((p) {
          return p.id == id ? updatedPkg : p;
        }).toList();

        state = state.copyWith(
          isActionLoading: false,
          packages: updatedPackages,
          successMessage: isActive
              ? 'เปิดใช้งานบริการเรียบร้อยแล้ว'
              : 'ปิดการใช้งานบริการเรียบร้อยแล้ว',
        );
        return true;
      },
    );
  }

  Future<bool> deletePackage(String id, {bool permanent = true}) async {
    final repo = _repo;
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    final result = await repo.deletePackage(id, permanent: permanent);
    if (!ref.mounted) return false;

    return result.fold(
      (failure) {
        state = state.copyWith(
          isActionLoading: false,
          errorMessage: 'ลบบริการไม่สำเร็จ',
        );
        return false;
      },
      (_) {
        final updatedPackages = state.packages.where((p) => p.id != id).toList();
        final updatedStats = AdminStats(
          totalUsers: state.stats.totalUsers,
          totalSubscriptions: state.stats.totalSubscriptions,
          totalCards: state.stats.totalCards,
          totalPackages: state.stats.totalPackages > 0
              ? state.stats.totalPackages - 1
              : 0,
        );

        state = state.copyWith(
          isActionLoading: false,
          packages: updatedPackages,
          stats: updatedStats,
          successMessage: 'ลบบริการเรียบร้อยแล้ว',
        );
        return true;
      },
    );
  }

  Future<bool> deleteUser(String id) async {
    final repo = _repo;
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    final result = await repo.deleteUser(id);
    if (!ref.mounted) return false;

    return result.fold(
      (failure) {
        state = state.copyWith(
          isActionLoading: false,
          errorMessage: 'ลบผู้ใช้ไม่สำเร็จ',
        );
        return false;
      },
      (_) {
        final updatedUsers = state.users.where((u) => u.id != id).toList();
        final updatedStats = AdminStats(
          totalUsers: state.stats.totalUsers > 0
              ? state.stats.totalUsers - 1
              : 0,
          totalSubscriptions: state.stats.totalSubscriptions,
          totalCards: state.stats.totalCards,
          totalPackages: state.stats.totalPackages,
        );

        state = state.copyWith(
          isActionLoading: false,
          users: updatedUsers,
          stats: updatedStats,
          successMessage: 'ลบผู้ใช้เรียบร้อยแล้ว',
        );
        return true;
      },
    );
  }

  Future<AdminUserDetail?> getUserDetail(String id) async {
    final repo = _repo;
    final result = await repo.getUserDetail(id);
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: 'ไม่สามารถโหลดข้อมูลผู้ใช้ได้');
        return null;
      },
      (detail) => detail,
    );
  }

  Future<bool> updateUser(
    String id, {
    String? name,
    String? role,
    double? monthlyIncome,
  }) async {
    final repo = _repo;
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    final result = await repo.updateUser(
      id,
      name: name,
      role: role,
      monthlyIncome: monthlyIncome,
    );
    if (!ref.mounted) return false;

    return result.fold(
      (failure) {
        state = state.copyWith(
          isActionLoading: false,
          errorMessage: 'แก้ไขข้อมูลผู้ใช้ไม่สำเร็จ',
        );
        return false;
      },
      (_) async {
        state = state.copyWith(
          isActionLoading: false,
          successMessage: 'บันทึกข้อมูลผู้ใช้สำเร็จ',
        );
        await loadAll();
        return true;
      },
    );
  }

  Future<bool> updateSubscription(
    String subId, {
    String? name,
    String? category,
    double? price,
    String? billingCycle,
    String? status,
    DateTime? nextRenewalDate,
    String? notes,
    String? brandColor,
  }) async {
    final repo = _repo;
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    final result = await repo.updateSubscription(
      subId,
      name: name,
      category: category,
      price: price,
      billingCycle: billingCycle,
      status: status,
      nextRenewalDate: nextRenewalDate,
      notes: notes,
      brandColor: brandColor,
    );
    if (!ref.mounted) return false;

    return result.fold(
      (failure) {
        state = state.copyWith(
          isActionLoading: false,
          errorMessage: 'แก้ไข Subscription ไม่สำเร็จ',
        );
        return false;
      },
      (_) async {
        state = state.copyWith(
          isActionLoading: false,
          successMessage: 'บันทึกการแก้ไข Subscription สำเร็จ',
        );
        await loadAll();
        return true;
      },
    );
  }

  Future<bool> deleteSubscription(String subId) async {
    final repo = _repo;
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    final result = await repo.deleteSubscription(subId);
    if (!ref.mounted) return false;

    return result.fold(
      (failure) {
        state = state.copyWith(
          isActionLoading: false,
          errorMessage: 'ลบ Subscription ไม่สำเร็จ',
        );
        return false;
      },
      (_) async {
        state = state.copyWith(
          isActionLoading: false,
          successMessage: 'ลบ Subscription เรียบร้อยแล้ว',
        );
        await loadAll();
        return true;
      },
    );
  }
}


final adminControllerProvider =
    NotifierProvider<AdminController, AdminState>(AdminController.new);
