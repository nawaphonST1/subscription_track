import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:subscription_track/models/subscription.dart';
import 'package:subscription_track/providers/subscription_provider.dart';

part 'simulation_provider.g.dart';

@riverpod
class SelectedForSimulation extends _$SelectedForSimulation {
  @override
  Set<String> build() => {};

  void toggle(String id) {
    state = state.contains(id)
        ? ({...state}..remove(id))
        : ({...state}..add(id));
  }

  void clear() => state = {};
}

@riverpod
double simulationSavings(Ref ref) {
  final allAsync = ref.watch(subscriptionListProvider);
  final selected = ref.watch(selectedForSimulationProvider);

  return allAsync.when(
    data: (all) {
      return all
          .where((s) => selected.contains(s.id))
          .fold(0.0, (sum, s) => sum + s.monthlyPrice);
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
}
