// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'preset_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PresetPlan {

 String get tier; double get monthlyPrice; double? get yearlyPrice; int get maxSlots; List<String> get features;
/// Create a copy of PresetPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresetPlanCopyWith<PresetPlan> get copyWith => _$PresetPlanCopyWithImpl<PresetPlan>(this as PresetPlan, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresetPlan&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.monthlyPrice, monthlyPrice) || other.monthlyPrice == monthlyPrice)&&(identical(other.yearlyPrice, yearlyPrice) || other.yearlyPrice == yearlyPrice)&&(identical(other.maxSlots, maxSlots) || other.maxSlots == maxSlots)&&const DeepCollectionEquality().equals(other.features, features));
}


@override
int get hashCode => Object.hash(runtimeType,tier,monthlyPrice,yearlyPrice,maxSlots,const DeepCollectionEquality().hash(features));

@override
String toString() {
  return 'PresetPlan(tier: $tier, monthlyPrice: $monthlyPrice, yearlyPrice: $yearlyPrice, maxSlots: $maxSlots, features: $features)';
}


}

/// @nodoc
abstract mixin class $PresetPlanCopyWith<$Res>  {
  factory $PresetPlanCopyWith(PresetPlan value, $Res Function(PresetPlan) _then) = _$PresetPlanCopyWithImpl;
@useResult
$Res call({
 String tier, double monthlyPrice, double? yearlyPrice, int maxSlots, List<String> features
});




}
/// @nodoc
class _$PresetPlanCopyWithImpl<$Res>
    implements $PresetPlanCopyWith<$Res> {
  _$PresetPlanCopyWithImpl(this._self, this._then);

  final PresetPlan _self;
  final $Res Function(PresetPlan) _then;

/// Create a copy of PresetPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tier = null,Object? monthlyPrice = null,Object? yearlyPrice = freezed,Object? maxSlots = null,Object? features = null,}) {
  return _then(_self.copyWith(
tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,monthlyPrice: null == monthlyPrice ? _self.monthlyPrice : monthlyPrice // ignore: cast_nullable_to_non_nullable
as double,yearlyPrice: freezed == yearlyPrice ? _self.yearlyPrice : yearlyPrice // ignore: cast_nullable_to_non_nullable
as double?,maxSlots: null == maxSlots ? _self.maxSlots : maxSlots // ignore: cast_nullable_to_non_nullable
as int,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PresetPlan].
extension PresetPlanPatterns on PresetPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresetPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresetPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresetPlan value)  $default,){
final _that = this;
switch (_that) {
case _PresetPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresetPlan value)?  $default,){
final _that = this;
switch (_that) {
case _PresetPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tier,  double monthlyPrice,  double? yearlyPrice,  int maxSlots,  List<String> features)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresetPlan() when $default != null:
return $default(_that.tier,_that.monthlyPrice,_that.yearlyPrice,_that.maxSlots,_that.features);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tier,  double monthlyPrice,  double? yearlyPrice,  int maxSlots,  List<String> features)  $default,) {final _that = this;
switch (_that) {
case _PresetPlan():
return $default(_that.tier,_that.monthlyPrice,_that.yearlyPrice,_that.maxSlots,_that.features);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tier,  double monthlyPrice,  double? yearlyPrice,  int maxSlots,  List<String> features)?  $default,) {final _that = this;
switch (_that) {
case _PresetPlan() when $default != null:
return $default(_that.tier,_that.monthlyPrice,_that.yearlyPrice,_that.maxSlots,_that.features);case _:
  return null;

}
}

}

/// @nodoc


class _PresetPlan implements PresetPlan {
  const _PresetPlan({required this.tier, required this.monthlyPrice, this.yearlyPrice, this.maxSlots = 1, final  List<String> features = const []}): _features = features;
  

@override final  String tier;
@override final  double monthlyPrice;
@override final  double? yearlyPrice;
@override@JsonKey() final  int maxSlots;
 final  List<String> _features;
@override@JsonKey() List<String> get features {
  if (_features is EqualUnmodifiableListView) return _features;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_features);
}


/// Create a copy of PresetPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresetPlanCopyWith<_PresetPlan> get copyWith => __$PresetPlanCopyWithImpl<_PresetPlan>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresetPlan&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.monthlyPrice, monthlyPrice) || other.monthlyPrice == monthlyPrice)&&(identical(other.yearlyPrice, yearlyPrice) || other.yearlyPrice == yearlyPrice)&&(identical(other.maxSlots, maxSlots) || other.maxSlots == maxSlots)&&const DeepCollectionEquality().equals(other._features, _features));
}


@override
int get hashCode => Object.hash(runtimeType,tier,monthlyPrice,yearlyPrice,maxSlots,const DeepCollectionEquality().hash(_features));

@override
String toString() {
  return 'PresetPlan(tier: $tier, monthlyPrice: $monthlyPrice, yearlyPrice: $yearlyPrice, maxSlots: $maxSlots, features: $features)';
}


}

/// @nodoc
abstract mixin class _$PresetPlanCopyWith<$Res> implements $PresetPlanCopyWith<$Res> {
  factory _$PresetPlanCopyWith(_PresetPlan value, $Res Function(_PresetPlan) _then) = __$PresetPlanCopyWithImpl;
@override @useResult
$Res call({
 String tier, double monthlyPrice, double? yearlyPrice, int maxSlots, List<String> features
});




}
/// @nodoc
class __$PresetPlanCopyWithImpl<$Res>
    implements _$PresetPlanCopyWith<$Res> {
  __$PresetPlanCopyWithImpl(this._self, this._then);

  final _PresetPlan _self;
  final $Res Function(_PresetPlan) _then;

/// Create a copy of PresetPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tier = null,Object? monthlyPrice = null,Object? yearlyPrice = freezed,Object? maxSlots = null,Object? features = null,}) {
  return _then(_PresetPlan(
tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,monthlyPrice: null == monthlyPrice ? _self.monthlyPrice : monthlyPrice // ignore: cast_nullable_to_non_nullable
as double,yearlyPrice: freezed == yearlyPrice ? _self.yearlyPrice : yearlyPrice // ignore: cast_nullable_to_non_nullable
as double?,maxSlots: null == maxSlots ? _self.maxSlots : maxSlots // ignore: cast_nullable_to_non_nullable
as int,features: null == features ? _self._features : features // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
