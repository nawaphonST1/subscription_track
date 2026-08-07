import 'package:freezed_annotation/freezed_annotation.dart';

part 'credit_card.freezed.dart';
part 'credit_card.g.dart';

@freezed
abstract class CreditCard with _$CreditCard {
  const factory CreditCard({
    required String id,
    required String bankName,
    required String last4Digits,
    required double creditLimit,
    required double currentBalance,
    required String cardColor,
  }) = _CreditCard;

  // ⚠️ เช็คว่ามีบรรทัดนี้อยู่แน่นอนใช่ไหมครับ?
  factory CreditCard.fromJson(Map<String, dynamic> json) =>
      _$CreditCardFromJson(json);
}