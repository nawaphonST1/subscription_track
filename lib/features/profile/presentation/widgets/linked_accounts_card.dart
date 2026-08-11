import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _LinkedCardTile extends StatelessWidget {
  const _LinkedCardTile({required this.card});

  final PaymentCard card;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: DecoratedBox(
        decoration: BoxDecoration(
          color: card.displayColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.credit_card_rounded, color: card.displayColor),
        ),
      ),
      title: Text(
        card.bankName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '•••• ${card.last4Digits} · '
        '${card.detectedSubscriptions.length} Subscription',
      ),
      trailing: Icon(Icons.sync_rounded, color: card.displayColor),
    );
  }
}
