import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/app/application/current_tab_controller.dart';

void main() {
  test('selects only valid main navigation indexes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(currentTabProvider.notifier);

    controller.select(mainTabCount - 1);
    expect(container.read(currentTabProvider), mainTabCount - 1);

    controller.select(-1);
    controller.select(mainTabCount);
    expect(container.read(currentTabProvider), mainTabCount - 1);
  });
}
