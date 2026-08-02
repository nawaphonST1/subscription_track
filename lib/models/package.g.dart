// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Package _$PackageFromJson(Map<String, dynamic> json) => _Package(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String? ?? '',
  category: json['category'] as String? ?? 'other',
  defaultPrice: (json['defaultPrice'] as num?)?.toDouble() ?? 0.0,
  billingPeriod: json['billingPeriod'] as String? ?? 'monthly',
  iconUrl: json['iconUrl'] as String? ?? '',
  websiteUrl: json['websiteUrl'] as String? ?? '',
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$PackageToJson(_Package instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'category': instance.category,
  'defaultPrice': instance.defaultPrice,
  'billingPeriod': instance.billingPeriod,
  'iconUrl': instance.iconUrl,
  'websiteUrl': instance.websiteUrl,
  'isActive': instance.isActive,
};
