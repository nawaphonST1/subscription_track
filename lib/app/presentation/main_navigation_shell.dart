import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/layout/app_breakpoints.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/features/subscriptions/presentation/subscriptions_tab.dart';
import 'package:subscription_track/app/application/current_tab_controller.dart';
import 'package:subscription_track/features/dashboard/presentation/dashboard_tab.dart';
import 'package:subscription_track/features/profile/application/user_income_controller.dart';
import 'package:subscription_track/features/profile/presentation/profile_tab.dart';
import 'package:subscription_track/features/savings/presentation/savings_tab.dart';
import 'package:subscription_track/features/settings/presentation/settings_tab.dart';

class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({super.key});

  static const _destinations = <_MainDestination>[
    _MainDestination(
      label: 'หน้าแรก',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
    ),
    _MainDestination(
      label: 'รายการ',
      icon: Icons.subscriptions_outlined,
      selectedIcon: Icons.subscriptions_rounded,
    ),
    _MainDestination(
      label: 'ประหยัด',
      icon: Icons.savings_outlined,
      selectedIcon: Icons.savings_rounded,
    ),
    _MainDestination(
      label: 'ตั้งค่า',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
    _MainDestination(
      label: 'โปรไฟล์',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);
    final income = ref.watch(userIncomeProvider);

    Future<void> editIncome() =>
        _showIncomeBottomSheet(context: context, currentIncome: income);

    final pages = <Widget>[
      const DashboardTab(),
      const SubscriptionsTab(),
      const SavingsTab(),
      const SettingsTab(),
      ProfileTab(onEditIncome: editIncome),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useNavigationRail =
            constraints.maxWidth >= AppBreakpoints.desktop;
        final expandNavigation =
            constraints.maxWidth >= AppBreakpoints.expandedNavigation;

        return Scaffold(
          appBar: _MainHeader(onEditIncome: editIncome),
          body: useNavigationRail
              ? Row(
                  children: [
                    NavigationRail(
                      key: const Key('main-navigation-rail'),
                      selectedIndex: currentTab,
                      extended: expandNavigation,
                      labelType: expandNavigation
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.all,
                      onDestinationSelected: ref
                          .read(currentTabProvider.notifier)
                          .select,
                      backgroundColor: AppColors.bgSecondary,
                      indicatorColor: AppColors.primary.withValues(alpha: 0.18),
                      destinations: [
                        for (final destination in _destinations)
                          NavigationRailDestination(
                            icon: Icon(destination.icon),
                            selectedIcon: Icon(destination.selectedIcon),
                            label: Text(destination.label),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: IndexedStack(index: currentTab, children: pages),
                    ),
                  ],
                )
              : IndexedStack(index: currentTab, children: pages),
          floatingActionButton: currentTab == 1
              ? FloatingActionButton.extended(
                  key: const Key('add-subscription-button'),
                  onPressed: () => _showFeatureComingSoon(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('เพิ่มบริการ'),
                )
              : null,
          bottomNavigationBar: useNavigationRail
              ? null
              : NavigationBar(
                  key: const Key('main-bottom-navigation'),
                  selectedIndex: currentTab,
                  onDestinationSelected: ref
                      .read(currentTabProvider.notifier)
                      .select,
                  backgroundColor: AppColors.bgSecondary,
                  indicatorColor: AppColors.primary.withValues(alpha: 0.18),
                  destinations: [
                    for (final destination in _destinations)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: destination.label,
                      ),
                  ],
                ),
        );
      },
    );
  }

  void _showFeatureComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('แบบฟอร์มเพิ่มบริการจะเชื่อมในงานถัดไป')),
    );
  }
}

class _MainHeader extends ConsumerWidget implements PreferredSizeWidget {
  const _MainHeader({required this.onEditIncome});

  final VoidCallback onEditIncome;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(userIncomeProvider);
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.bgPrimary,
      titleSpacing: 16,
      title: Row(
        children: [
          InkWell(
            key: const Key('header-profile-button'),
            onTap: () => ref.read(currentTabProvider.notifier).select(4),
            borderRadius: BorderRadius.circular(24),
            child: const CircleAvatar(
              radius: 19,
              backgroundColor: AppColors.primary,
              child: Text(
                'N',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUBSCRIPTION TRACK',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'สวัสดี, คุณเน 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          ActionChip(
            key: const Key('income-chip'),
            onPressed: onEditIncome,
            avatar: const Icon(
              Icons.account_balance_wallet_rounded,
              size: 16,
              color: AppColors.primaryLight,
            ),
            label: Text(
              '฿${(income / 1000).toStringAsFixed(0)}k',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            backgroundColor: AppColors.bgSecondary,
            side: const BorderSide(color: AppColors.border),
          ),
        ],
      ),
    );
  }
}

class _MainDestination {
  const _MainDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

Future<void> _showIncomeBottomSheet({
  required BuildContext context,
  required double currentIncome,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _IncomeBottomSheet(initialIncome: currentIncome),
  );
}

class _IncomeBottomSheet extends ConsumerStatefulWidget {
  const _IncomeBottomSheet({required this.initialIncome});

  final double initialIncome;

  @override
  ConsumerState<_IncomeBottomSheet> createState() => _IncomeBottomSheetState();
}

class _IncomeBottomSheetState extends ConsumerState<_IncomeBottomSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialIncome.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'กำหนดรายได้ต่อเดือน',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'ใช้คำนวณ Creep Risk เท่านั้น และจะไม่แสดงต่อผู้ใช้อื่น',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('income-field'),
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              prefixText: '฿ ',
              labelText: 'รายได้ต่อเดือน',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('save-income-button'),
            onPressed: _save,
            child: const Text('บันทึกข้อมูล'),
          ),
        ],
      ),
    );
  }

  void _save() {
    final income = double.tryParse(_controller.text);
    final didUpdate =
        income != null && ref.read(userIncomeProvider.notifier).update(income);
    if (didUpdate) {
      Navigator.of(context).pop();
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('กรุณากรอกรายได้มากกว่า 0')));
  }
}
