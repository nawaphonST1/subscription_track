// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simulation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedForSimulation)
final selectedForSimulationProvider = SelectedForSimulationProvider._();

final class SelectedForSimulationProvider
    extends $NotifierProvider<SelectedForSimulation, Set<String>> {
  SelectedForSimulationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedForSimulationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedForSimulationHash();

  @$internal
  @override
  SelectedForSimulation create() => SelectedForSimulation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$selectedForSimulationHash() =>
    r'e8f90f79345a40c726f46cc13f0f4559643313fe';

abstract class _$SelectedForSimulation extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(simulationSavings)
final simulationSavingsProvider = SimulationSavingsProvider._();

final class SimulationSavingsProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  SimulationSavingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'simulationSavingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$simulationSavingsHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return simulationSavings(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$simulationSavingsHash() => r'564309858b91e372e745eb9db1b1a058a8b6c6a8';
