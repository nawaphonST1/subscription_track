import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:subscription_track/models/subscription.dart';
import 'package:subscription_track/providers/subscription_provider.dart';

part 'subscription_filter_provider.g.dart';

@riverpod
class SelectedFilter extends _$SelectedFilter {
  @override
  String build() => 'all';

  void setFilter(String filter) => state = filter;
}

@riverpod
Future<List<Subscription>> filteredSubscriptions(Ref ref) async {
  final allAsync = ref.watch(subscriptionListProvider);
  final filter = ref.watch(selectedFilterProvider);

  return allAsync.when(
    data: (all) {
      if (filter == 'all') return all;
      return all.where((s) => s.category == filter).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
}
