import 'package:flutter/material.dart';

const _destinations = <_MainDestination>[
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

class MainAppNavigationRail extends StatelessWidget {
  const MainAppNavigationRail({
    required this.selectedIndex,
    required this.extended,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final bool extended;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NavigationRail(
      key: const Key('main-navigation-rail'),
      selectedIndex: selectedIndex,
      extended: extended,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      onDestinationSelected: onSelected,
      backgroundColor: theme.cardColor,
      indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.18),
      destinations: [
        for (final destination in _destinations)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: Text(destination.label),
          ),
      ],
    );
  }
}

class MainAppNavigationBar extends StatelessWidget {
  const MainAppNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NavigationBar(
      key: const Key('main-bottom-navigation'),
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      backgroundColor: theme.cardColor,
      indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.18),
      destinations: [
        for (final destination in _destinations)
          NavigationDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: destination.label,
          ),
      ],
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
