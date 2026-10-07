import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/features/profile/application/payment_card_linking_controller.dart';
import 'package:subscription_track/features/profile/presentation/payment_card_ui_extensions.dart';

Future<PaymentCardLinkResult?> showAddPaymentCardSheet(BuildContext context) {
  return showModalBottomSheet<PaymentCardLinkResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _AddPaymentCardSheet(),
  );
}

class _AddPaymentCardSheet extends ConsumerStatefulWidget {
  const _AddPaymentCardSheet();

  @override
  ConsumerState<_AddPaymentCardSheet> createState() =>
      _AddPaymentCardSheetState();
}

class _AddPaymentCardSheetState
    extends ConsumerState<_AddPaymentCardSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cardIdController = TextEditingController();
  bool _isLinking = false;
  String? _errorMessage;
  bool _showMockCards = false;

  @override
  void dispose() {
    _cardIdController.dispose();
    super.dispose();
  }

  String? _validateCardInput(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอก Card ID หรือหมายเลขบัตร';
    }
    final trimmed = value.trim();
    // Allow UUID format or alphanumeric card identifier
    final validFormat = RegExp(r'^[0-9a-fA-F-]{8,36}$').hasMatch(trimmed) ||
        RegExp(r'^[a-zA-Z0-9_-]{4,64}$').hasMatch(trimmed);
    if (!validFormat) {
      return 'รูปแบบ Card ID ไม่ถูกต้อง (ต้องเป็นตัวอักษร ตัวเลข หรือขีดกลาง)';
    }
    return null;
  }

  Future<void> _submitCardLink(String cardId) async {
    if (_isLinking) return;
    setState(() {
      _isLinking = true;
      _errorMessage = null;
    });

    try {
      final result = await ref
          .read(linkedPaymentCardsProvider.notifier)
          .linkCard(cardId);
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      setState(() {
        _isLinking = false;
        if (msg.contains('does not belong to your account')) {
          _errorMessage = 'This card does not belong to your account.';
        } else {
          _errorMessage = msg.replaceFirst('Exception: ', '');
        }
      });

      if (msg.contains('does not belong to your account')) {
        _showOwnershipErrorDialog(context);
      }
    }
  }

  void _showOwnershipErrorDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.gpp_bad_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text('ไม่สามารถเชื่อมต่อบัตรได้'),
          ],
        ),
        content: const Text(
          'This card does not belong to your account.\nบัตรนี้ถูกลงทะเบียนไว้กับบัญชีอื่น ไม่อนุญาตให้ผูกข้ามบัญชีผู้ใช้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final availableCards = ref.watch(availablePaymentCardsProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'เพิ่ม / ผูกบัตรชำระเงิน',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'กรอก Card ID ของบัตรที่คุณเป็นเจ้าของ หรือเลือกบัตรจำลองในระบบ',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.danger,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('card_id_input'),
              controller: _cardIdController,
              enabled: !_isLinking,
              decoration: InputDecoration(
                labelText: 'Card ID / Card Identifier',
                hintText: 'e.g. c0000000-0000-4000-a000-000000000001',
                prefixIcon: const Icon(Icons.credit_card_rounded),
                suffixIcon: _cardIdController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _cardIdController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              validator: _validateCardInput,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                key: const Key('link_card_button'),
                icon: _isLinking
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.link_rounded),
                label: Text(_isLinking ? 'กำลังเชื่อมต่อ...' : 'เชื่อมต่อบัตร'),
                onPressed: _isLinking
                    ? null
                    : () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _submitCardLink(_cardIdController.text.trim());
                        }
                      },
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () => setState(() => _showMockCards = !_showMockCards),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      _showMockCards
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'หรือเลือกจากบัตรจำลองในระบบ (Mock Cards)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showMockCards) ...[
              const SizedBox(height: 8),
              availableCards.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(
                  child: Text('โหลดข้อมูลบัตรจำลองไม่สำเร็จ'),
                ),
                data: (items) => items.isEmpty
                    ? const Center(child: Text('ไม่มีบัตรจำลองเพิ่มเติม'))
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final card = items[index];
                          return Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: card.displayColor
                                    .withValues(alpha: 0.15),
                                foregroundColor: card.displayColor,
                                child: const Icon(Icons.credit_card_rounded),
                              ),
                              title: Text(card.bankName),
                              subtitle: Text(
                                '•••• ${card.last4Digits} · ยอดเงิน ฿${card.currentBalance.toStringAsFixed(0)} (ID: ${card.id.length > 8 ? "${card.id.substring(0, 8)}..." : card.id})',
                              ),
                              trailing: TextButton(
                                onPressed: _isLinking
                                    ? null
                                    : () {
                                        _cardIdController.text = card.id;
                                        _submitCardLink(card.id);
                                      },
                                child: const Text('เลือกผูก'),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
