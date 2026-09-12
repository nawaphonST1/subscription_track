import 'package:flutter/material.dart';
import 'package:subscription_track/core/layout/app_breakpoints.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/subscription_list_tile.dart';

class SubscriptionCollection extends StatelessWidget {
  const SubscriptionCollection({
    required this.subscriptions,
    required this.onToggle,
    required this.onDelete,
    required this.onShowDetails,
    super.key,
  });

  final List<Subscription> subscriptions;
  final ValueChanged<Subscription> onToggle;
  final ValueChanged<Subscription> onDelete;
  final ValueChanged<Subscription> onShowDetails;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useGrid = constraints.maxWidth >= AppBreakpoints.tablet;
        final padding = const EdgeInsets.fromLTRB(16, 4, 16, 96);

        Widget buildTile(BuildContext context, int index) {
          final subscription = subscriptions[index];
          return SubscriptionListTile(
            subscription: subscription,
            onToggle: () => onToggle(subscription),
            onDelete: () => onDelete(subscription),
            onShowDetails: () => onShowDetails(subscription),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.contentMaxWidth,
            ),
            child: useGrid
                ? GridView.builder(
                    key: const Key('subscriptions-desktop-grid'),
                    padding: padding,
                    itemCount: subscriptions.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 560,
                          mainAxisExtent: 76,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemBuilder: buildTile,
                  )
                : ListView.separated(
                    key: const PageStorageKey<String>('subscriptions-tab'),
                    padding: padding,
                    itemCount: subscriptions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: buildTile,
                  ),
          ),
        );
      },
    );
  }
}
