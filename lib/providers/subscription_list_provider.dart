import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:subscription_track/models/subscription.dart';
import 'package:subscription_track/services/service_providers.dart';

part 'subscription_list_provider.g.dart';

@riverpod
Future<List<Subscription>> subscriptionList(Ref ref) async {
  final service = ref.watch(subscriptionServiceProvider);
  final result = await service.getAll();
  return result.fold(
    (failure) => throw Exception(failure),
    (subscriptions) => subscriptions,
  );
}

@riverpod
Future<Subscription?> subscriptionById(Ref ref, String id) async {
  final service = ref.watch(subscriptionServiceProvider);
  final result = await service.getById(id);
  return result.fold(
    (failure) => throw Exception(failure),
    (subscription) => subscription,
  );
}
