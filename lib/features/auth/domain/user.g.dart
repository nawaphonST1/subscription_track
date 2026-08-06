// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: json['id'] as String,
  email: json['email'] as String,
  name: json['name'] as String? ?? '',
  avatar: json['avatar'] as String? ?? '',
  authProvider: json['authProvider'] as String? ?? 'google',
  income: (json['income'] as num?)?.toDouble() ?? 0.0,
  currency: json['currency'] as String? ?? 'THB',
  settings: json['settings'] == null
      ? const UserSettings()
      : UserSettings.fromJson(json['settings'] as Map<String, dynamic>),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'name': instance.name,
  'avatar': instance.avatar,
  'authProvider': instance.authProvider,
  'income': instance.income,
  'currency': instance.currency,
  'settings': instance.settings,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

_UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) =>
    _UserSettings(
      notificationDays: (json['notificationDays'] as num?)?.toInt() ?? 3,
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      language: json['language'] as String? ?? 'th',
    );

Map<String, dynamic> _$UserSettingsToJson(_UserSettings instance) =>
    <String, dynamic>{
      'notificationDays': instance.notificationDays,
      'biometricEnabled': instance.biometricEnabled,
      'language': instance.language,
    };
