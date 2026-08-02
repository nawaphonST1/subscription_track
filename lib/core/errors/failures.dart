import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
abstract class Failure with _$Failure {
  const factory Failure.serverError(String message) = _ServerError;
  const factory Failure.networkError() = _NetworkError;
  const factory Failure.notFound() = _NotFound;
  const factory Failure.unauthorized() = _Unauthorized;
  const factory Failure.validationError(String field, String message) = _ValidationError;
  const factory Failure.cacheError(String message) = _CacheError;
  const factory Failure.unknown(String message) = _Unknown;
}
