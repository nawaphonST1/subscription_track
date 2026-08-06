import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subscription_track/core/layout/app_breakpoints.dart';
import 'package:subscription_track/features/profile/application/user_income_controller.dart';
import 'package:subscription_track/features/profile/presentation/widgets/linked_accounts_card.dart';
import 'package:subscription_track/features/profile/presentation/widgets/profile_identity_card.dart';
import 'package:subscription_track/features/profile/presentation/widgets/profile_settings_card.dart';
import 'package:subscription_track/providers/app_flow_provider.dart';
import 'package:subscription_track/providers/auth_provider.dart';
import 'package:subscription_track/router/route_constants.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key, required this.onEditIncome});

  final VoidCallback onEditIncome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(userIncomeProvider);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.settingsMaxWidth,
        ),
        child: ListView(
          key: const PageStorageKey<String>('profile-tab'),
          padding: const EdgeInsets.all(16),
          children: [
            const ProfileIdentityCard(),
            const SizedBox(height: 16),
            ProfileSettingsCard(
              income: income,
              onEditIncome: onEditIncome,
              onOpenPinSettings: () => showPinSettingsInfoDialog(context),
            ),
            const SizedBox(height: 16),
            const LinkedAccountsCard(),
            const SizedBox(height: 32),
            _LogoutButton(onPressed: () => _logout(context, ref)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    ref.read(onboardingProvider.notifier).setCompleted(false);
    await ref.read(authProvider.notifier).logout();
    if (context.mounted) context.go(RouteConstants.onboarding);
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const danger = Color(0xFFEF4444);
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.logout_rounded),
      label: const Text(
        'ออกจากระบบ',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: danger.withValues(alpha: 0.1),
        foregroundColor: danger,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: danger.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}
