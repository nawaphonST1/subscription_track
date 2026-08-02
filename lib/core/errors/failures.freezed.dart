// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'failures.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Failure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Failure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure()';
}


}

/// @nodoc
class $FailureCopyWith<$Res>  {
$FailureCopyWith(Failure _, $Res Function(Failure) __);
}


/// Adds pattern-matching-related methods to [Failure].
extension FailurePatterns on Failure {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _ServerError value)?  serverError,TResult Function( _NetworkError value)?  networkError,TResult Function( _NotFound value)?  notFound,TResult Function( _Unauthorized value)?  unauthorized,TResult Function( _ValidationError value)?  validationError,TResult Function( _CacheError value)?  cacheError,TResult Function( _Unknown value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServerError() when serverError != null:
return serverError(_that);case _NetworkError() when networkError != null:
return networkError(_that);case _NotFound() when notFound != null:
return notFound(_that);case _Unauthorized() when unauthorized != null:
return unauthorized(_that);case _ValidationError() when validationError != null:
return validationError(_that);case _CacheError() when cacheError != null:
return cacheError(_that);case _Unknown() when unknown != null:
return unknown(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _ServerError value)  serverError,required TResult Function( _NetworkError value)  networkError,required TResult Function( _NotFound value)  notFound,required TResult Function( _Unauthorized value)  unauthorized,required TResult Function( _ValidationError value)  validationError,required TResult Function( _CacheError value)  cacheError,required TResult Function( _Unknown value)  unknown,}){
final _that = this;
switch (_that) {
case _ServerError():
return serverError(_that);case _NetworkError():
return networkError(_that);case _NotFound():
return notFound(_that);case _Unauthorized():
return unauthorized(_that);case _ValidationError():
return validationError(_that);case _CacheError():
return cacheError(_that);case _Unknown():
return unknown(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _ServerError value)?  serverError,TResult? Function( _NetworkError value)?  networkError,TResult? Function( _NotFound value)?  notFound,TResult? Function( _Unauthorized value)?  unauthorized,TResult? Function( _ValidationError value)?  validationError,TResult? Function( _CacheError value)?  cacheError,TResult? Function( _Unknown value)?  unknown,}){
final _that = this;
switch (_that) {
case _ServerError() when serverError != null:
return serverError(_that);case _NetworkError() when networkError != null:
return networkError(_that);case _NotFound() when notFound != null:
return notFound(_that);case _Unauthorized() when unauthorized != null:
return unauthorized(_that);case _ValidationError() when validationError != null:
return validationError(_that);case _CacheError() when cacheError != null:
return cacheError(_that);case _Unknown() when unknown != null:
return unknown(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String message)?  serverError,TResult Function()?  networkError,TResult Function()?  notFound,TResult Function()?  unauthorized,TResult Function( String field,  String message)?  validationError,TResult Function( String message)?  cacheError,TResult Function( String message)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServerError() when serverError != null:
return serverError(_that.message);case _NetworkError() when networkError != null:
return networkError();case _NotFound() when notFound != null:
return notFound();case _Unauthorized() when unauthorized != null:
return unauthorized();case _ValidationError() when validationError != null:
return validationError(_that.field,_that.message);case _CacheError() when cacheError != null:
return cacheError(_that.message);case _Unknown() when unknown != null:
return unknown(_that.message);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String message)  serverError,required TResult Function()  networkError,required TResult Function()  notFound,required TResult Function()  unauthorized,required TResult Function( String field,  String message)  validationError,required TResult Function( String message)  cacheError,required TResult Function( String message)  unknown,}) {final _that = this;
switch (_that) {
case _ServerError():
return serverError(_that.message);case _NetworkError():
return networkError();case _NotFound():
return notFound();case _Unauthorized():
return unauthorized();case _ValidationError():
return validationError(_that.field,_that.message);case _CacheError():
return cacheError(_that.message);case _Unknown():
return unknown(_that.message);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String message)?  serverError,TResult? Function()?  networkError,TResult? Function()?  notFound,TResult? Function()?  unauthorized,TResult? Function( String field,  String message)?  validationError,TResult? Function( String message)?  cacheError,TResult? Function( String message)?  unknown,}) {final _that = this;
switch (_that) {
case _ServerError() when serverError != null:
return serverError(_that.message);case _NetworkError() when networkError != null:
return networkError();case _NotFound() when notFound != null:
return notFound();case _Unauthorized() when unauthorized != null:
return unauthorized();case _ValidationError() when validationError != null:
return validationError(_that.field,_that.message);case _CacheError() when cacheError != null:
return cacheError(_that.message);case _Unknown() when unknown != null:
return unknown(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _ServerError implements Failure {
  const _ServerError(this.message);
  

 final  String message;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServerErrorCopyWith<_ServerError> get copyWith => __$ServerErrorCopyWithImpl<_ServerError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServerError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'Failure.serverError(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ServerErrorCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory _$ServerErrorCopyWith(_ServerError value, $Res Function(_ServerError) _then) = __$ServerErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$ServerErrorCopyWithImpl<$Res>
    implements _$ServerErrorCopyWith<$Res> {
  __$ServerErrorCopyWithImpl(this._self, this._then);

  final _ServerError _self;
  final $Res Function(_ServerError) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_ServerError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _NetworkError implements Failure {
  const _NetworkError();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetworkError);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure.networkError()';
}


}




/// @nodoc


class _NotFound implements Failure {
  const _NotFound();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotFound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure.notFound()';
}


}




/// @nodoc


class _Unauthorized implements Failure {
  const _Unauthorized();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Unauthorized);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure.unauthorized()';
}


}




/// @nodoc


class _ValidationError implements Failure {
  const _ValidationError(this.field, this.message);
  

 final  String field;
 final  String message;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ValidationErrorCopyWith<_ValidationError> get copyWith => __$ValidationErrorCopyWithImpl<_ValidationError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ValidationError&&(identical(other.field, field) || other.field == field)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,field,message);

@override
String toString() {
  return 'Failure.validationError(field: $field, message: $message)';
}


}

/// @nodoc
abstract mixin class _$ValidationErrorCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory _$ValidationErrorCopyWith(_ValidationError value, $Res Function(_ValidationError) _then) = __$ValidationErrorCopyWithImpl;
@useResult
$Res call({
 String field, String message
});




}
/// @nodoc
class __$ValidationErrorCopyWithImpl<$Res>
    implements _$ValidationErrorCopyWith<$Res> {
  __$ValidationErrorCopyWithImpl(this._self, this._then);

  final _ValidationError _self;
  final $Res Function(_ValidationError) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field = null,Object? message = null,}) {
  return _then(_ValidationError(
null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _CacheError implements Failure {
  const _CacheError(this.message);
  

 final  String message;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CacheErrorCopyWith<_CacheError> get copyWith => __$CacheErrorCopyWithImpl<_CacheError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CacheError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'Failure.cacheError(message: $message)';
}


}

/// @nodoc
abstract mixin class _$CacheErrorCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory _$CacheErrorCopyWith(_CacheError value, $Res Function(_CacheError) _then) = __$CacheErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$CacheErrorCopyWithImpl<$Res>
    implements _$CacheErrorCopyWith<$Res> {
  __$CacheErrorCopyWithImpl(this._self, this._then);

  final _CacheError _self;
  final $Res Function(_CacheError) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_CacheError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _Unknown implements Failure {
  const _Unknown(this.message);
  

 final  String message;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnknownCopyWith<_Unknown> get copyWith => __$UnknownCopyWithImpl<_Unknown>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Unknown&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'Failure.unknown(message: $message)';
}


}

/// @nodoc
abstract mixin class _$UnknownCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory _$UnknownCopyWith(_Unknown value, $Res Function(_Unknown) _then) = __$UnknownCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$UnknownCopyWithImpl<$Res>
    implements _$UnknownCopyWith<$Res> {
  __$UnknownCopyWithImpl(this._self, this._then);

  final _Unknown _self;
  final $Res Function(_Unknown) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Unknown(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
