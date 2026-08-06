import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/app/application/current_tab_controller.dart';
import 'package:subscription_track/features/profile/application/user_income_controller.dart';

class MainAppHeader extends ConsumerWidget implements PreferredSizeWidget {
  const MainAppHeader({required this.onEditIncome, super.key});

  final VoidCallback onEditIncome;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(userIncomeProvider);
    final theme = Theme.of(context);

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      titleSpacing: 16,
      title: Row(
        children: [
          InkWell(
            key: const Key('header-profile-button'),
            onTap: () => ref.read(currentTabProvider.notifier).select(4),
            borderRadius: BorderRadius.circular(24),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                'N',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUBSCRIPTION TRACK',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'สวัสดี, คุณเน 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
          ActionChip(
            key: const Key('income-chip'),
            onPressed: onEditIncome,
            avatar: Icon(
              Icons.account_balance_wallet_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            label: Text(
              '฿${(income / 1000).toStringAsFixed(0)}k',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            backgroundColor: theme.cardColor,
            side: BorderSide(color: theme.dividerColor),
          ),
        ],
      ),
    );
  }
}
