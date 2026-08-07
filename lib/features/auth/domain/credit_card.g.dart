// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CreditCard _$CreditCardFromJson(Map<String, dynamic> json) => _CreditCard(
  id: json['id'] as String,
  bankName: json['bankName'] as String,
  last4Digits: json['last4Digits'] as String,
  creditLimit: (json['creditLimit'] as num).toDouble(),
  currentBalance: (json['currentBalance'] as num).toDouble(),
  cardColor: json['cardColor'] as String,
);

Map<String, dynamic> _$CreditCardToJson(_CreditCard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bankName': instance.bankName,
      'last4Digits': instance.last4Digits,
      'creditLimit': instance.creditLimit,
      'currentBalance': instance.currentBalance,
      'cardColor': instance.cardColor,
    };
