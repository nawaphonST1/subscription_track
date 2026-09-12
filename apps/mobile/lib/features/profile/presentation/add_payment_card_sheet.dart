import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/profile/application/payment_card_linking_controller.dart';
import 'package:subscription_track/features/profile/domain/payment_card.dart';
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
  String? _linkingCardId;

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(availablePaymentCardsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'เพิ่มบัตร',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'เลือกบัตรจำลองเพื่อค้นหา Subscription จากรายการเรียกเก็บซ้ำ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Flexible(
            child: cards.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(
                child: Text('โหลดข้อมูลบัตรไม่สำเร็จ กรุณาลองอีกครั้ง'),
              ),
              data: (items) => items.isEmpty
                  ? const Center(child: Text('เพิ่มบัตรจำลองครบแล้ว'))
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) => _AvailableCardTile(
                        card: items[index],
                        isLinking: _linkingCardId == items[index].id,
                        isDisabled: _linkingCardId != null,
                        onLink: () => _linkCard(items[index]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _linkCard(PaymentCard card) async {
    setState(() => _linkingCardId = card.id);
    try {
      final result = await ref
          .read(linkedPaymentCardsProvider.notifier)
          .linkCard(card.id);
      if (mounted) Navigator.of(context).pop(result);
    } catch (_) {
      if (!mounted) return;
      setState(() => _linkingCardId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เพิ่มบัตรไม่สำเร็จ กรุณาลองอีกครั้ง')),
      );
    }
  }
}

class _AvailableCardTile extends StatelessWidget {
  const _AvailableCardTile({
    required this.card,
    required this.isLinking,
    required this.isDisabled,
    required this.onLink,
  });

  final PaymentCard card;
  final bool isLinking;
  final bool isDisabled;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: card.displayColor.withValues(alpha: 0.15),
          foregroundColor: card.displayColor,
          child: const Icon(Icons.credit_card_rounded),
        ),
        title: Text(card.bankName),
        subtitle: Text(
          '•••• ${card.last4Digits} · ตรวจพบ ${card.detectedSubscriptions.length} รายการ',
        ),
        trailing: isLinking
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : FilledButton(
                onPressed: isDisabled ? null : onLink,
                child: const Text('เพิ่ม'),
              ),
      ),
    );
  }
}
