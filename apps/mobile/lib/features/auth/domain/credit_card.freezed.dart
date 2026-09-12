// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'credit_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreditCard {

 String get id; String get bankName; String get last4Digits; double get creditLimit; double get currentBalance; String get cardColor;
/// Create a copy of CreditCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreditCardCopyWith<CreditCard> get copyWith => _$CreditCardCopyWithImpl<CreditCard>(this as CreditCard, _$identity);

  /// Serializes this CreditCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreditCard&&(identical(other.id, id) || other.id == id)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.last4Digits, last4Digits) || other.last4Digits == last4Digits)&&(identical(other.creditLimit, creditLimit) || other.creditLimit == creditLimit)&&(identical(other.currentBalance, currentBalance) || other.currentBalance == currentBalance)&&(identical(other.cardColor, cardColor) || other.cardColor == cardColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bankName,last4Digits,creditLimit,currentBalance,cardColor);

@override
String toString() {
  return 'CreditCard(id: $id, bankName: $bankName, last4Digits: $last4Digits, creditLimit: $creditLimit, currentBalance: $currentBalance, cardColor: $cardColor)';
}


}

/// @nodoc
abstract mixin class $CreditCardCopyWith<$Res>  {
  factory $CreditCardCopyWith(CreditCard value, $Res Function(CreditCard) _then) = _$CreditCardCopyWithImpl;
@useResult
$Res call({
 String id, String bankName, String last4Digits, double creditLimit, double currentBalance, String cardColor
});




}
/// @nodoc
class _$CreditCardCopyWithImpl<$Res>
    implements $CreditCardCopyWith<$Res> {
  _$CreditCardCopyWithImpl(this._self, this._then);

  final CreditCard _self;
  final $Res Function(CreditCard) _then;

/// Create a copy of CreditCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? bankName = null,Object? last4Digits = null,Object? creditLimit = null,Object? currentBalance = null,Object? cardColor = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,last4Digits: null == last4Digits ? _self.last4Digits : last4Digits // ignore: cast_nullable_to_non_nullable
as String,creditLimit: null == creditLimit ? _self.creditLimit : creditLimit // ignore: cast_nullable_to_non_nullable
as double,currentBalance: null == currentBalance ? _self.currentBalance : currentBalance // ignore: cast_nullable_to_non_nullable
as double,cardColor: null == cardColor ? _self.cardColor : cardColor // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CreditCard].
extension CreditCardPatterns on CreditCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreditCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreditCard() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreditCard value)  $default,){
final _that = this;
switch (_that) {
case _CreditCard():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreditCard value)?  $default,){
final _that = this;
switch (_that) {
case _CreditCard() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String bankName,  String last4Digits,  double creditLimit,  double currentBalance,  String cardColor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreditCard() when $default != null:
return $default(_that.id,_that.bankName,_that.last4Digits,_that.creditLimit,_that.currentBalance,_that.cardColor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String bankName,  String last4Digits,  double creditLimit,  double currentBalance,  String cardColor)  $default,) {final _that = this;
switch (_that) {
case _CreditCard():
return $default(_that.id,_that.bankName,_that.last4Digits,_that.creditLimit,_that.currentBalance,_that.cardColor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String bankName,  String last4Digits,  double creditLimit,  double currentBalance,  String cardColor)?  $default,) {final _that = this;
switch (_that) {
case _CreditCard() when $default != null:
return $default(_that.id,_that.bankName,_that.last4Digits,_that.creditLimit,_that.currentBalance,_that.cardColor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreditCard implements CreditCard {
  const _CreditCard({required this.id, required this.bankName, required this.last4Digits, required this.creditLimit, required this.currentBalance, required this.cardColor});
  factory _CreditCard.fromJson(Map<String, dynamic> json) => _$CreditCardFromJson(json);

@override final  String id;
@override final  String bankName;
@override final  String last4Digits;
@override final  double creditLimit;
@override final  double currentBalance;
@override final  String cardColor;

/// Create a copy of CreditCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreditCardCopyWith<_CreditCard> get copyWith => __$CreditCardCopyWithImpl<_CreditCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreditCardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreditCard&&(identical(other.id, id) || other.id == id)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.last4Digits, last4Digits) || other.last4Digits == last4Digits)&&(identical(other.creditLimit, creditLimit) || other.creditLimit == creditLimit)&&(identical(other.currentBalance, currentBalance) || other.currentBalance == currentBalance)&&(identical(other.cardColor, cardColor) || other.cardColor == cardColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bankName,last4Digits,creditLimit,currentBalance,cardColor);

@override
String toString() {
  return 'CreditCard(id: $id, bankName: $bankName, last4Digits: $last4Digits, creditLimit: $creditLimit, currentBalance: $currentBalance, cardColor: $cardColor)';
}


}

/// @nodoc
abstract mixin class _$CreditCardCopyWith<$Res> implements $CreditCardCopyWith<$Res> {
  factory _$CreditCardCopyWith(_CreditCard value, $Res Function(_CreditCard) _then) = __$CreditCardCopyWithImpl;
@override @useResult
$Res call({
 String id, String bankName, String last4Digits, double creditLimit, double currentBalance, String cardColor
});




}
/// @nodoc
class __$CreditCardCopyWithImpl<$Res>
    implements _$CreditCardCopyWith<$Res> {
  __$CreditCardCopyWithImpl(this._self, this._then);

  final _CreditCard _self;
  final $Res Function(_CreditCard) _then;

/// Create a copy of CreditCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? bankName = null,Object? last4Digits = null,Object? creditLimit = null,Object? currentBalance = null,Object? cardColor = null,}) {
  return _then(_CreditCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,last4Digits: null == last4Digits ? _self.last4Digits : last4Digits // ignore: cast_nullable_to_non_nullable
as String,creditLimit: null == creditLimit ? _self.creditLimit : creditLimit // ignore: cast_nullable_to_non_nullable
as double,currentBalance: null == currentBalance ? _self.currentBalance : currentBalance // ignore: cast_nullable_to_non_nullable
as double,cardColor: null == cardColor ? _self.cardColor : cardColor // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
