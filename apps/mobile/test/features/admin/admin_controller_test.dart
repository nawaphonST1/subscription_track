import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/features/admin/application/admin_controller.dart';
import 'package:subscription_track/features/admin/data/admin_repository.dart';
import 'package:subscription_track/features/admin/domain/admin_package.dart';
import 'package:subscription_track/features/admin/domain/admin_stats.dart';
import 'package:subscription_track/features/admin/domain/admin_user.dart';
import 'package:subscription_track/features/admin/domain/admin_user_detail.dart';
import 'package:subscription_track/features/subscriptions/domain/preset_plan.dart';

class FakeAdminRepository implements AdminRepository {
  FakeAdminRepository() {
    users = [
      AdminUser(
        id: 'u1',
        email: 'alice@example.com',
        name: 'Alice',
        subscriptionsCount: 3,
        cardsCount: 2,
        createdAt: DateTime(2026, 1, 1),
      ),
      AdminUser(
        id: 'u2',
        email: 'bob@example.com',
        name: 'Bob',
        subscriptionsCount: 2,
        cardsCount: 1,
        createdAt: DateTime(2026, 1, 2),
      ),
    ];

    packages = [
      const AdminPackage(
        id: 'p1',
        name: 'Netflix Premium',
        category: 'Entertainment',
        defaultPrice: 419.0,
        billingCycle: 'MONTHLY',
        brandColor: '#E50914',
        isActive: true,
      ),
    ];
  }

  AdminStats stats = const AdminStats(
    totalUsers: 2,
    totalSubscriptions: 5,
    totalCards: 3,
    totalPackages: 4,
  );

  late List<AdminUser> users;
  late List<AdminPackage> packages;
  bool shouldFail = false;

  @override
  Future<Either<Failure, AdminStats>> getStats() async {
    if (shouldFail) return left(const Failure.serverError('Error fetching stats'));
    return right(stats);
  }

  @override
  Future<Either<Failure, List<AdminUser>>> getUsers() async {
    if (shouldFail) return left(const Failure.serverError('Error fetching users'));
    return right(List.from(users));
  }

  @override
  Future<Either<Failure, void>> deleteUser(String id) async {
    if (shouldFail) return left(const Failure.serverError('Error deleting user'));
    users.removeWhere((u) => u.id == id);
    return right(null);
  }

  @override
  Future<Either<Failure, List<AdminPackage>>> getPackages() async {
    if (shouldFail) return left(const Failure.serverError('Error fetching packages'));
    return right(List.from(packages));
  }

  @override
  Future<Either<Failure, AdminPackage>> createPackage({
    required String name,
    required String category,
    required double defaultPrice,
    String billingCycle = 'MONTHLY',
    String brandColor = '#3B82F6',
    String? iconUrl,
    String? description,
    List<PresetPlan>? plans,
  }) async {
    if (shouldFail) return left(const Failure.serverError('Error creating package'));
    final newPkg = AdminPackage(
      id: 'p_new',
      name: name,
      category: category,
      defaultPrice: defaultPrice,
      billingCycle: billingCycle,
      brandColor: brandColor,
      iconUrl: iconUrl,
      description: description,
      isActive: true,
      plans: plans ?? const [],
    );
    packages.add(newPkg);
    return right(newPkg);
  }

  @override
  Future<Either<Failure, AdminPackage>> updatePackage(
    String id, {
    String? name,
    String? category,
    double? defaultPrice,
    String? billingCycle,
    String? brandColor,
    String? iconUrl,
    String? description,
    List<PresetPlan>? plans,
  }) async {
    if (shouldFail) return left(const Failure.serverError('Error updating package'));
    final idx = packages.indexWhere((p) => p.id == id);
    if (idx != -1) {
      final updated = AdminPackage(
        id: id,
        name: name ?? packages[idx].name,
        category: category ?? packages[idx].category,
        defaultPrice: defaultPrice ?? packages[idx].defaultPrice,
        billingCycle: billingCycle ?? packages[idx].billingCycle,
        brandColor: brandColor ?? packages[idx].brandColor,
        iconUrl: iconUrl ?? packages[idx].iconUrl,
        description: description ?? packages[idx].description,
        isActive: packages[idx].isActive,
        plans: plans ?? packages[idx].plans,
      );
      packages[idx] = updated;
      return right(updated);
    }
    return left(const Failure.notFound());
  }

  @override
  Future<Either<Failure, AdminPackage>> togglePackageActive(
    String id,
    bool isActive,
  ) async {
    if (shouldFail) return left(const Failure.serverError('Error toggling package'));
    final idx = packages.indexWhere((p) => p.id == id);
    if (idx != -1) {
      final updated = packages[idx].copyWith(isActive: isActive);
      packages[idx] = updated;
      return right(updated);
    }
    return left(const Failure.notFound());
  }

  @override
  Future<Either<Failure, void>> deletePackage(
    String id, {
    bool permanent = false,
  }) async {
    if (shouldFail) return left(const Failure.serverError('Error deleting package'));
    packages.removeWhere((p) => p.id == id);
    return right(null);
  }

  @override
  Future<Either<Failure, AdminUserDetail>> getUserDetail(String id) async {
    if (shouldFail) return left(const Failure.serverError('Error fetching user detail'));
    return right(AdminUserDetail(
      id: id,
      email: 'alice@example.com',
      name: 'Alice',
      role: 'USER',
      monthlyIncome: 30000,
      createdAt: DateTime(2026, 1, 1),
      subscriptions: [
        const AdminUserSubscriptionDetail(
          id: 'sub1',
          name: 'Netflix Premium',
          category: 'Entertainment',
          price: 419.0,
          billingCycle: 'MONTHLY',
          status: 'ACTIVE',
        ),
      ],
      paymentCards: [],
    ));
  }

  @override
  Future<Either<Failure, void>> updateUser(
    String id, {
    String? name,
    String? role,
    double? monthlyIncome,
  }) async {
    if (shouldFail) return left(const Failure.serverError('Error updating user'));
    return right(null);
  }

  @override
  Future<Either<Failure, void>> createSubscription(
    String userId, {
    required String name,
    required String category,
    required double price,
    String billingCycle = 'MONTHLY',
    String? planTier,
    String? presetId,
    String? paymentCardId,
    DateTime? nextRenewalDate,
    String? status,
    String? notes,
    String? brandColor,
  }) async {
    if (shouldFail) return left(const Failure.serverError('Error creating subscription'));
    return right(null);
  }

  @override
  Future<Either<Failure, void>> updateSubscription(
    String subId, {
    String? name,
    String? category,
    double? price,
    String? billingCycle,
    String? status,
    DateTime? nextRenewalDate,
    String? notes,
    String? brandColor,
    String? planTier,
    String? presetId,
    String? paymentCardId,
  }) async {
    if (shouldFail) return left(const Failure.serverError('Error updating subscription'));
    return right(null);
  }

  @override
  Future<Either<Failure, void>> deleteSubscription(String subId) async {
    if (shouldFail) return left(const Failure.serverError('Error deleting subscription'));
    return right(null);
  }
}

void main() {
  group('AdminController Unit Tests', () {
    late FakeAdminRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = FakeAdminRepository();
      container = ProviderContainer(
        overrides: [
          adminRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('loadAll populates stats, users, and packages', () async {
      final controller = container.read(adminControllerProvider.notifier);
      await controller.loadAll();

      final state = container.read(adminControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.stats.totalUsers, 2);
      expect(state.stats.totalSubscriptions, 5);
      expect(state.users.length, 2);
      expect(state.packages.length, 1);
      expect(state.errorMessage, isNull);
    });

    test('createPackage successfully prepends new package and updates stats', () async {
      final controller = container.read(adminControllerProvider.notifier);
      await controller.loadAll();

      final success = await controller.createPackage(
        name: 'Disney+ Hotstar',
        category: 'Entertainment',
        defaultPrice: 289.0,
      );

      expect(success, isTrue);
      final state = container.read(adminControllerProvider);
      expect(state.packages.length, 2);
      expect(state.packages.first.name, 'Disney+ Hotstar');
      expect(state.stats.totalPackages, 5);
      expect(state.successMessage, contains('Disney+ Hotstar'));
    });

    test('updatePackage updates existing package successfully', () async {
      final controller = container.read(adminControllerProvider.notifier);
      await controller.loadAll();

      final success = await controller.updatePackage(
        'p1',
        name: 'Netflix Premium 4K',
        defaultPrice: 449.0,
      );
      expect(success, isTrue);

      final state = container.read(adminControllerProvider);
      final updated = state.packages.firstWhere((p) => p.id == 'p1');
      expect(updated.name, 'Netflix Premium 4K');
      expect(updated.defaultPrice, 449.0);
      expect(state.successMessage, contains('สำเร็จ'));
    });

    test('togglePackageActive updates active status of package', () async {
      final controller = container.read(adminControllerProvider.notifier);
      await controller.loadAll();

      final success = await controller.togglePackageActive('p1', false);
      expect(success, isTrue);

      final state = container.read(adminControllerProvider);
      expect(state.packages.firstWhere((p) => p.id == 'p1').isActive, isFalse);
    });

    test('deletePackage removes package and decrements stats', () async {
      final controller = container.read(adminControllerProvider.notifier);
      await controller.loadAll();

      final success = await controller.deletePackage('p1');
      expect(success, isTrue);

      final state = container.read(adminControllerProvider);
      expect(state.packages.any((p) => p.id == 'p1'), isFalse);
      expect(state.stats.totalPackages, 3);
    });

    test('deleteUser removes user and decrements totalUsers', () async {
      final controller = container.read(adminControllerProvider.notifier);
      await controller.loadAll();

      final success = await controller.deleteUser('u1');
      expect(success, isTrue);

      final state = container.read(adminControllerProvider);
      expect(state.users.any((u) => u.id == 'u1'), isFalse);
      expect(state.stats.totalUsers, 1);
    });

    test('getUserDetail returns user detail successfully', () async {
      final controller = container.read(adminControllerProvider.notifier);
      final detail = await controller.getUserDetail('u1');
      expect(detail, isNotNull);
      expect(detail!.email, 'alice@example.com');
      expect(detail.subscriptions.length, 1);
      expect(detail.subscriptions.first.name, 'Netflix Premium');
    });

    test('updateUser succeeds and sets success message', () async {
      final controller = container.read(adminControllerProvider.notifier);
      final success = await controller.updateUser('u1', name: 'Alice Updated', role: 'ADMIN');
      expect(success, isTrue);
      expect(container.read(adminControllerProvider).successMessage, contains('สำเร็จ'));
    });

    test('createSubscription succeeds with packet planTier and sets success message', () async {
      final controller = container.read(adminControllerProvider.notifier);
      final success = await controller.createSubscription(
        'u1',
        name: 'YouTube Premium',
        category: 'Entertainment',
        price: 179,
        planTier: 'Individual',
        presetId: 'p1',
      );
      expect(success, isTrue);
      expect(container.read(adminControllerProvider).successMessage, contains('สำเร็จ'));
    });

    test('updateSubscription succeeds with planTier and sets success message', () async {
      final controller = container.read(adminControllerProvider.notifier);
      final success = await controller.updateSubscription(
        'sub1',
        name: 'YouTube Premium Family',
        price: 339,
        planTier: 'Family',
      );
      expect(success, isTrue);
      expect(container.read(adminControllerProvider).successMessage, contains('สำเร็จ'));
    });

    test('deleteSubscription succeeds and sets success message', () async {
      final controller = container.read(adminControllerProvider.notifier);
      final success = await controller.deleteSubscription('sub1');
      expect(success, isTrue);
      expect(container.read(adminControllerProvider).successMessage, contains('เรียบร้อย'));
    });

    test('error handling sets errorMessage when action fails', () async {
      final controller = container.read(adminControllerProvider.notifier);
      await controller.loadAll();
      fakeRepo.shouldFail = true;

      final success = await controller.deleteUser('u1');
      expect(success, isFalse);

      final state = container.read(adminControllerProvider);
      expect(state.errorMessage, isNotNull);
    });
  });
}
