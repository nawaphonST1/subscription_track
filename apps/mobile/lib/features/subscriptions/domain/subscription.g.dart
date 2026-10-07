// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Subscription _$SubscriptionFromJson(Map<String, dynamic> json) =>
    _Subscription(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      billingPeriod: json['billingPeriod'] as String? ?? 'monthly',
      category: json['category'] as String? ?? 'other',
      nextBillingDate: json['nextBillingDate'] == null
          ? null
          : DateTime.parse(json['nextBillingDate'] as String),
      usageStatus: json['usageStatus'] as String? ?? 'moderate',
      confidence: (json['confidence'] as num?)?.toInt() ?? 50,
      paymentCardId: json['paymentCardId'] as String?,
      isSelected: json['isSelected'] as bool? ?? false,
      customFields:
          (json['customFields'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          const [],
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      presetId: json['presetId'] as String?,
      planTier: json['planTier'] as String?,
      sharedMembers: (json['sharedMembers'] as num?)?.toInt() ?? 1,
      pricePerSlot: (json['pricePerSlot'] as num?)?.toDouble(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SubscriptionToJson(_Subscription instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price': instance.price,
      'billingPeriod': instance.billingPeriod,
      'category': instance.category,
      'nextBillingDate': instance.nextBillingDate?.toIso8601String(),
      'usageStatus': instance.usageStatus,
      'confidence': instance.confidence,
      'paymentCardId': instance.paymentCardId,
      'isSelected': instance.isSelected,
      'customFields': instance.customFields,
      'reminderEnabled': instance.reminderEnabled,
      'presetId': instance.presetId,
      'planTier': instance.planTier,
      'sharedMembers': instance.sharedMembers,
      'pricePerSlot': instance.pricePerSlot,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
