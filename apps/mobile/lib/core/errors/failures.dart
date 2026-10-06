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

extension FailureX on Failure {
  String get displayMessage => when(
        serverError: (message) => message,
        networkError: () => 'ไม่สามารถเชื่อมต่อเครือข่ายได้',
        notFound: () => 'ไม่พบข้อมูลในระบบ',
        unauthorized: () => 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
        validationError: (field, message) => message,
        cacheError: (message) => message,
        unknown: (message) => message,
      );
}
