// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(subscriptionList)
final subscriptionListProvider = SubscriptionListProvider._();

final class SubscriptionListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Subscription>>,
          List<Subscription>,
          FutureOr<List<Subscription>>
        >
    with
        $FutureModifier<List<Subscription>>,
        $FutureProvider<List<Subscription>> {
  SubscriptionListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionListHash();

  @$internal
  @override
  $FutureProviderElement<List<Subscription>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Subscription>> create(Ref ref) {
    return subscriptionList(ref);
  }
}

String _$subscriptionListHash() => r'bb25b5e6e66910e01dae79a7adef601899d91b84';

@ProviderFor(subscriptionById)
final subscriptionByIdProvider = SubscriptionByIdFamily._();

final class SubscriptionByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<Subscription?>,
          Subscription?,
          FutureOr<Subscription?>
        >
    with $FutureModifier<Subscription?>, $FutureProvider<Subscription?> {
  SubscriptionByIdProvider._({
    required SubscriptionByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'subscriptionByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$subscriptionByIdHash();

  @override
  String toString() {
    return r'subscriptionByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Subscription?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Subscription?> create(Ref ref) {
    final argument = this.argument as String;
    return subscriptionById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SubscriptionByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$subscriptionByIdHash() => r'78bc4578136d8a1643d4aa214cabd96292fe0f4e';

final class SubscriptionByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Subscription?>, String> {
  SubscriptionByIdFamily._()
    : super(
        retry: null,
        name: r'subscriptionByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SubscriptionByIdProvider call(String id) =>
      SubscriptionByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'subscriptionByIdProvider';
}
