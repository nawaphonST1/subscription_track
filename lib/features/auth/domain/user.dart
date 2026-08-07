import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:subscription_track/features/auth/domain/credit_card.dart';
part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String email,
    @Default('') String name,
    @Default('') String avatar,
    @Default('google') String authProvider,
    @Default(0.0) double income,
    @Default('THB') String currency,
    @Default([]) List<CreditCard> creditCards, // <-- เพิ่มฟิลด์นี้ตรงนี้ครับ
    @Default(UserSettings()) UserSettings settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
abstract class UserSettings with _$UserSettings {
  const factory UserSettings({
    @Default(3) int notificationDays,
    @Default(false) bool biometricEnabled,
    @Default('th') String language,
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}