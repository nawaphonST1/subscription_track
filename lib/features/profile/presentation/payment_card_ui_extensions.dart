import 'package:flutter/material.dart';
import 'package:subscription_track/features/profile/domain/payment_card.dart';

extension PaymentCardUiExtension on PaymentCard {
  Color get displayColor {
    final normalized = colorHex.replaceFirst('#', '');
    final value = int.tryParse(normalized, radix: 16);
    return value == null
        ? const Color(0xFF3B82F6)
        : Color(0xFF000000 | value);
  }
}
