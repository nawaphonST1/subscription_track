import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/admin/application/admin_controller.dart';
import 'package:subscription_track/features/admin/domain/admin_package.dart';
import 'package:subscription_track/features/admin/domain/admin_stats.dart';
import 'package:subscription_track/features/admin/domain/admin_user.dart';
import 'package:subscription_track/features/admin/presentation/admin_portal_screen.dart';

void main() {
  testWidgets('AdminPortalScreen renders tabs, stats cards, and user list',
      (WidgetTester tester) async {
    final mockStats = const AdminStats(
      totalUsers: 12,
      totalSubscriptions: 45,
      totalCards: 18,
      totalPackages: 8,
    );

    final mockUsers = [
      AdminUser(
        id: 'user_1',
        email: 'somchai@test.com',
        name: 'สมชาย สายเปย์',
        subscriptionsCount: 3,
        cardsCount: 1,
        createdAt: DateTime(2026, 1, 1),
      ),
    ];

    final mockPackages = [
      const AdminPackage(
        id: 'pkg_1',
        name: 'Netflix Premium',
        category: 'Entertainment',
        defaultPrice: 419.0,
        billingCycle: 'MONTHLY',
        brandColor: '#E50914',
        isActive: true,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminControllerProvider.overrideWith(
            () => _FakeNotifier(
              AdminState(
                isLoading: false,
                isAdminAuthenticated: true,
                stats: mockStats,
                users: mockUsers,
                packages: mockPackages,
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: AdminPortalScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('จัดการระบบ (Admin)'), findsOneWidget);

    // Verify Stat Cards
    expect(find.text('ผู้ใช้ทั้งหมด'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('45'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);

    // Verify Users tab content
    expect(find.text('สมชาย สายเปย์'), findsOneWidget);
    expect(find.text('somchai@test.com'), findsOneWidget);

    // Switch to Packages tab
    await tester.tap(find.text('บริการ & แพ็กเกจ'));
    await tester.pumpAndSettle();

    // Verify Package content
    expect(find.text('Netflix Premium'), findsOneWidget);
    expect(find.text('Entertainment • ฿419/เดือน'), findsOneWidget);
  });

  testWidgets('AdminPortalScreen renders login form when unauthenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminControllerProvider.overrideWith(
            () => _FakeNotifier(
              const AdminState(
                isLoading: false,
                isAdminAuthenticated: false,
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: AdminPortalScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('เข้าสู่ระบบแอดมิน (Admin Portal)'), findsOneWidget);
    expect(find.text('ระบบจัดการผู้ดูแล (Admin)'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบผู้ดูแล'), findsOneWidget);
    expect(find.text('admin@subtracker.com'), findsWidgets);
  });
}

class _FakeNotifier extends AdminController {
  final AdminState initialState;
  _FakeNotifier(this.initialState);

  @override
  AdminState build() => initialState;

  @override
  Future<void> loadAll() async {}
}
