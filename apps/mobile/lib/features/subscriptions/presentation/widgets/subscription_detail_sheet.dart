import 'package:flutter/material.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/subscription_detail_header.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/subscription_detail_overview.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/subscription_reminder_editor.dart';

class SubscriptionDetailSheet extends StatefulWidget {
  const SubscriptionDetailSheet({
    required this.subscription,
    required this.onSaved,
    super.key,
  });

  final Subscription subscription;
  final ValueChanged<Subscription> onSaved;

  @override
  State<SubscriptionDetailSheet> createState() =>
      _SubscriptionDetailSheetState();
}

class _SubscriptionDetailSheetState extends State<SubscriptionDetailSheet> {
  late bool reminderEnabled;
  late int reminderDays;
  late bool markCancelled;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // หุ้มด้วย Material และกำหนดสีตาม theme.cardColor เพื่อให้เข้ากับระบบ Theme อัตโนมัติ
    return Material(
      color: theme.cardColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SubscriptionDetailHeader(
                  subscription: widget.subscription,
                  onReset: () => setState(_reset),
                ),
                const SizedBox(height: 12),
                SubscriptionDetailOverview(subscription: widget.subscription),
                const SizedBox(height: 16),
                SubscriptionReminderEditor(
                  enabled: reminderEnabled,
                  days: reminderDays,
                  onEnabledChanged: _setReminderEnabled,
                  onDaysChanged: (days) => setState(() => reminderDays = days),
                ),
                const SizedBox(height: 12),
                CheckboxListTile.adaptive(
                  key: const Key('mark-subscription-cancelled'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('ยกเลิกแล้ว'),
                  value: markCancelled,
                  onChanged: (value) {
                    setState(() => markCancelled = value ?? false);
                  },
                ),
                const SizedBox(height: 16),
                if (reminderEnabled)
                  Text(
                    'เตือนล่วงหน้า $reminderDays วัน',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.6,
                      ),
                      fontSize: 12,
                    ),
                  ),
                if (markCancelled)
                  Text(
                    'ยกเลิกแล้ว',
                    key: const Key('cancelled-status-label'),
                    style: TextStyle(
                      // ใช้สีตาม colorScheme.primary หรือ error เพื่อให้รองรับ Dark/Light Theme ได้ถูกต้อง
                      color: theme.colorScheme.primary, 
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 16),
                _DetailActions(onSave: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _reset() {
    reminderEnabled = widget.subscription.reminderEnabled;
    reminderDays = _readReminderDays(widget.subscription);
    markCancelled =
        widget.subscription.usageStatus.toLowerCase() == 'cancelled';
  }

  void _setReminderEnabled(bool enabled) {
    setState(() {
      reminderEnabled = enabled;
      reminderDays = enabled ? (reminderDays == 0 ? 3 : reminderDays) : 0;
    });
  }

  void _save() {
    final fields = widget.subscription.customFields
        .where((entry) => entry['key'] != 'reminderDays')
        .toList(growable: false);
    final currentStatus = widget.subscription.usageStatus;

    widget.onSaved(
      widget.subscription.copyWith(
        reminderEnabled: reminderEnabled,
        usageStatus: markCancelled
            ? 'cancelled'
            : (currentStatus.toLowerCase() == 'cancelled'
                ? 'moderate'
                : currentStatus),
        customFields: reminderEnabled
            ? [
                ...fields,
                {'key': 'reminderDays', 'value': reminderDays.toString()},
              ]
            : fields,
      ),
    );
    Navigator.of(context).pop();
  }

  static int _readReminderDays(Subscription subscription) {
    if (!subscription.reminderEnabled) return 0;
    for (final field in subscription.customFields) {
      if (field['key'] == 'reminderDays') {
        final days = int.tryParse(field['value'] ?? '');
        if (days == 3 || days == 7) return days!;
      }
    }
    return 3;
  }
}

class _DetailActions extends StatelessWidget {
  const _DetailActions({required this.onSave});

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            key: const Key('save-subscription-details'),
            onPressed: onSave,
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('บันทึก'),
          ),
        ),
      ],
    );
  }
}