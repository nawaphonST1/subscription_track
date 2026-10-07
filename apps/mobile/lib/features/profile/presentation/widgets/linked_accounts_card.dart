import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/widgets/confirmation_dialog.dart';
import 'package:subscription_track/core/widgets/pin_verification_dialog.dart';
import 'package:subscription_track/features/profile/application/payment_card_linking_controller.dart';
import 'package:subscription_track/features/profile/domain/payment_card.dart';
import 'package:subscription_track/features/profile/presentation/payment_card_ui_extensions.dart';

class LinkedAccountsCard extends ConsumerWidget {
  const LinkedAccountsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(linkedPaymentCardsProvider);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'บัตรที่เชื่อมต่อ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          cards.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.all(16),
              child: Text('โหลดข้อมูลบัตรไม่สำเร็จ'),
            ),
            data: (items) => items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: Text('ยังไม่มีบัตรที่เชื่อมต่อ'),
                  )
                : _LinkedCardList(cards: items),
          ),
        ],
      ),
    );
  }
}

class _LinkedCardList extends StatelessWidget {
  const _LinkedCardList({required this.cards});

  final List<PaymentCard> cards;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < cards.length; index++) ...[
          _LinkedCardTile(card: cards[index]),
          if (index < cards.length - 1)
            Divider(height: 1, color: Theme.of(context).dividerColor),
        ],
      ],
    );
  }
}

class _LinkedCardTile extends ConsumerStatefulWidget {
  const _LinkedCardTile({super.key, required this.card});

  final PaymentCard card;

  @override
  ConsumerState<_LinkedCardTile> createState() => _LinkedCardTileState();
}

class _LinkedCardTileState extends ConsumerState<_LinkedCardTile> {
  bool _isDeleting = false;

  Future<void> _deleteCard(BuildContext context) async {
    if (_isDeleting) return;

    final shouldDelete = await ConfirmationDialog.show(
      context: context,
      title: 'ยกเลิกการเชื่อมต่อบัตรหรือไม่?',
      message: '${widget.card.bankName} (•••• ${widget.card.last4Digits})',
      confirmText: 'ยกเลิกบัตร',
      cancelText: 'ไม่ยกเลิก',
      isDanger: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!shouldDelete || !mounted) return;

    final pin = await PinVerificationDialog.showForPin(
      context: context,
      title: 'ยืนยันการยกเลิกบัตร',
      message: 'กรุณากรอกรหัส PIN เพื่อยกเลิกบัตร ${widget.card.bankName}',
    );
    if (pin == null || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      await ref
          .read(linkedPaymentCardsProvider.notifier)
          .deleteCard(widget.card.id, pin: pin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ยกเลิกการเชื่อมต่อบัตร ${widget.card.bankName} เรียบร้อยแล้ว',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยกเลิกบัตรไม่สำเร็จ กรุณาลองอีกครั้ง')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.card.displayColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.credit_card_rounded, color: widget.card.displayColor),
        ),
      ),
      title: Text(
        widget.card.bankName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '•••• ${widget.card.last4Digits} · ยอดเงินคงเหลือ ฿${widget.card.currentBalance.toStringAsFixed(0)} · '
        '${widget.card.detectedSubscriptions.length} บริการ',
      ),
      trailing: _isDeleting
          ? const SizedBox(
              width: 24,
              height: 24,
              child: Padding(
                padding: EdgeInsets.all(4.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'ยกเลิกการเชื่อมต่อบัตร',
              onPressed: () => _deleteCard(context),
            ),
    );
  }
}
