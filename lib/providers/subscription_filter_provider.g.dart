// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedFilter)
final selectedFilterProvider = SelectedFilterProvider._();

final class SelectedFilterProvider
    extends $NotifierProvider<SelectedFilter, String> {
  SelectedFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedFilterHash();

  @$internal
  @override
  SelectedFilter create() => SelectedFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$selectedFilterHash() => r'8ceaecc86ff85e55536db6003ea29367f93f814e';

abstract class _$SelectedFilter extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(filteredSubscriptions)
final filteredSubscriptionsProvider = FilteredSubscriptionsProvider._();

final class FilteredSubscriptionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Subscription>>,
          List<Subscription>,
          FutureOr<List<Subscription>>
        >
    with
        $FutureModifier<List<Subscription>>,
        $FutureProvider<List<Subscription>> {
  FilteredSubscriptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredSubscriptionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredSubscriptionsHash();

  @$internal
  @override
  $FutureProviderElement<List<Subscription>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Subscription>> create(Ref ref) {
    return filteredSubscriptions(ref);
  }
}

String _$filteredSubscriptionsHash() =>
    r'1b238773b2daf02b0185569c1988f300bf6e8938';
