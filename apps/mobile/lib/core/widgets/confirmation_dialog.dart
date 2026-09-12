import 'package:flutter/material.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/core/theme/app_typography.dart';

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'ยืนยัน',
    this.cancelText = 'ยกเลิก',
    this.isDanger = false,
    this.icon,
  });

  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDanger;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      key: const Key('confirmation-dialog'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Icon(
        icon ??
            (isDanger
                ? Icons.warning_amber_rounded
                : Icons.help_outline_rounded),
        color: isDanger ? AppColors.danger : theme.colorScheme.primary,
        size: 34,
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: AppTypography.headingSmall.copyWith(
          color: theme.textTheme.titleMedium?.color,
        ),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.bodyMedium.copyWith(
          color: theme.textTheme.bodySmall?.color,
        ),
      ),
      actions: [
        TextButton(
          key: const Key('confirmation-cancel-button'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        FilledButton(
          key: const Key('confirmation-confirm-button'),
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: isDanger
                ? AppColors.danger
                : theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'ยืนยัน',
    String cancelText = 'ยกเลิก',
    bool isDanger = false,
    IconData? icon,
    bool barrierDismissible = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDanger: isDanger,
        icon: icon,
      ),
    );
    return result ?? false;
  }
}
