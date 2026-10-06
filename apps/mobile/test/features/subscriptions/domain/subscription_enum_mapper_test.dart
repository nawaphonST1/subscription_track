import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription_enum_mapper.dart';

void main() {
  group('billingCycleToBackend', () {
    test('monthly -> MONTHLY', () {
      expect(billingCycleToBackend('monthly'), 'MONTHLY');
    });

    test('yearly -> YEARLY', () {
      expect(billingCycleToBackend('yearly'), 'YEARLY');
    });

    test('weekly -> WEEKLY', () {
      expect(billingCycleToBackend('weekly'), 'WEEKLY');
    });

    test('is case-insensitive on input', () {
      expect(billingCycleToBackend('Monthly'), 'MONTHLY');
      expect(billingCycleToBackend('YEARLY'), 'YEARLY');
    });

    test('quarterly has no backend equivalent -> throws, not silently MONTHLY',
        () {
      expect(() => billingCycleToBackend('quarterly'), throwsArgumentError);
    });

    test('unknown value throws ArgumentError', () {
      expect(() => billingCycleToBackend('biannual'), throwsArgumentError);
    });
  });

  group('billingCycleFromBackend', () {
    test('MONTHLY -> monthly', () {
      expect(billingCycleFromBackend('MONTHLY'), 'monthly');
    });

    test('YEARLY -> yearly', () {
      expect(billingCycleFromBackend('YEARLY'), 'yearly');
    });

    test('WEEKLY -> weekly', () {
      expect(billingCycleFromBackend('WEEKLY'), 'weekly');
    });

    test('unknown backend value throws rather than defaulting silently', () {
      expect(() => billingCycleFromBackend('DAILY'), throwsArgumentError);
    });
  });

  group('usageStatusToBackend', () {
    test('frequent -> FREQUENT', () {
      expect(usageStatusToBackend('frequent'), 'FREQUENT');
    });

    test('moderate -> OCCASIONAL (the one name mismatch, documented)', () {
      expect(usageStatusToBackend('moderate'), 'OCCASIONAL');
    });

    test('unused -> UNUSED', () {
      expect(usageStatusToBackend('unused'), 'UNUSED');
    });

    test('is case-insensitive on input', () {
      expect(usageStatusToBackend('Frequent'), 'FREQUENT');
    });

    test('unknown value throws ArgumentError', () {
      expect(() => usageStatusToBackend('dormant'), throwsArgumentError);
    });
  });

  group('usageStatusFromBackend', () {
    test('FREQUENT -> frequent', () {
      expect(usageStatusFromBackend('FREQUENT'), 'frequent');
    });

    test('OCCASIONAL -> moderate (the one name mismatch, documented)', () {
      expect(usageStatusFromBackend('OCCASIONAL'), 'moderate');
    });

    test('UNUSED -> unused', () {
      expect(usageStatusFromBackend('UNUSED'), 'unused');
    });

    test('unknown backend value throws rather than defaulting silently', () {
      expect(() => usageStatusFromBackend('DORMANT'), throwsArgumentError);
    });
  });

  group('round-trip consistency', () {
    test('billing cycle round-trips through both directions', () {
      for (final period in ['monthly', 'yearly', 'weekly']) {
        final backend = billingCycleToBackend(period);
        expect(billingCycleFromBackend(backend), period);
      }
    });

    test('usage status round-trips through both directions', () {
      for (final status in ['frequent', 'moderate', 'unused']) {
        final backend = usageStatusToBackend(status);
        expect(usageStatusFromBackend(backend), status);
      }
    });
  });
}
