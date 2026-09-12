import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_form_validator.dart';

void main() {
  group('SubscriptionFormValidator', () {
    test('requires a non-empty service name', () {
      expect(SubscriptionFormValidator.validateName('  '), isNotNull);
      expect(SubscriptionFormValidator.validateName('Netflix'), isNull);
    });

    test('requires a positive numeric price', () {
      expect(SubscriptionFormValidator.validatePrice(null), isNotNull);
      expect(SubscriptionFormValidator.validatePrice('free'), isNotNull);
      expect(SubscriptionFormValidator.validatePrice('0'), isNotNull);
      expect(SubscriptionFormValidator.validatePrice('419'), isNull);
    });
  });
}
