import 'package:freezed_annotation/freezed_annotation.dart';

part 'package.freezed.dart';
part 'package.g.dart';

@freezed
abstract class Package with _$Package {
  const factory Package({
    required String id,
    required String name,
    @Default('') String description,
    @Default('other') String category,
    @Default(0.0) double defaultPrice,
    @Default('monthly') String billingPeriod,
    @Default('') String iconUrl,
    @Default('') String websiteUrl,
    @Default(true) bool isActive,
  }) = _Package;

  factory Package.fromJson(Map<String, dynamic> json) => _$PackageFromJson(json);
}
