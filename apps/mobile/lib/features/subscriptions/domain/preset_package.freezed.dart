// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'preset_package.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PresetPackage {

 String get name; double get price; String get billingPeriod; String get category; String? get id; String? get brandColor; String? get iconUrl; String? get description; List<PresetPlan> get plans; List<String> get features; int get maxSlots;
/// Create a copy of PresetPackage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresetPackageCopyWith<PresetPackage> get copyWith => _$PresetPackageCopyWithImpl<PresetPackage>(this as PresetPackage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresetPackage&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price)&&(identical(other.billingPeriod, billingPeriod) || other.billingPeriod == billingPeriod)&&(identical(other.category, category) || other.category == category)&&(identical(other.id, id) || other.id == id)&&(identical(other.brandColor, brandColor) || other.brandColor == brandColor)&&(identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.plans, plans)&&const DeepCollectionEquality().equals(other.features, features)&&(identical(other.maxSlots, maxSlots) || other.maxSlots == maxSlots));
}


@override
int get hashCode => Object.hash(runtimeType,name,price,billingPeriod,category,id,brandColor,iconUrl,description,const DeepCollectionEquality().hash(plans),const DeepCollectionEquality().hash(features),maxSlots);

@override
String toString() {
  return 'PresetPackage(name: $name, price: $price, billingPeriod: $billingPeriod, category: $category, id: $id, brandColor: $brandColor, iconUrl: $iconUrl, description: $description, plans: $plans, features: $features, maxSlots: $maxSlots)';
}


}

/// @nodoc
abstract mixin class $PresetPackageCopyWith<$Res>  {
  factory $PresetPackageCopyWith(PresetPackage value, $Res Function(PresetPackage) _then) = _$PresetPackageCopyWithImpl;
@useResult
$Res call({
 String name, double price, String billingPeriod, String category, String? id, String? brandColor, String? iconUrl, String? description, List<PresetPlan> plans, List<String> features, int maxSlots
});




}
/// @nodoc
class _$PresetPackageCopyWithImpl<$Res>
    implements $PresetPackageCopyWith<$Res> {
  _$PresetPackageCopyWithImpl(this._self, this._then);

  final PresetPackage _self;
  final $Res Function(PresetPackage) _then;

/// Create a copy of PresetPackage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? price = null,Object? billingPeriod = null,Object? category = null,Object? id = freezed,Object? brandColor = freezed,Object? iconUrl = freezed,Object? description = freezed,Object? plans = null,Object? features = null,Object? maxSlots = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,billingPeriod: null == billingPeriod ? _self.billingPeriod : billingPeriod // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,brandColor: freezed == brandColor ? _self.brandColor : brandColor // ignore: cast_nullable_to_non_nullable
as String?,iconUrl: freezed == iconUrl ? _self.iconUrl : iconUrl // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,plans: null == plans ? _self.plans : plans // ignore: cast_nullable_to_non_nullable
as List<PresetPlan>,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as List<String>,maxSlots: null == maxSlots ? _self.maxSlots : maxSlots // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PresetPackage].
extension PresetPackagePatterns on PresetPackage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresetPackage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresetPackage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresetPackage value)  $default,){
final _that = this;
switch (_that) {
case _PresetPackage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresetPackage value)?  $default,){
final _that = this;
switch (_that) {
case _PresetPackage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  double price,  String billingPeriod,  String category,  String? id,  String? brandColor,  String? iconUrl,  String? description,  List<PresetPlan> plans,  List<String> features,  int maxSlots)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresetPackage() when $default != null:
return $default(_that.name,_that.price,_that.billingPeriod,_that.category,_that.id,_that.brandColor,_that.iconUrl,_that.description,_that.plans,_that.features,_that.maxSlots);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  double price,  String billingPeriod,  String category,  String? id,  String? brandColor,  String? iconUrl,  String? description,  List<PresetPlan> plans,  List<String> features,  int maxSlots)  $default,) {final _that = this;
switch (_that) {
case _PresetPackage():
return $default(_that.name,_that.price,_that.billingPeriod,_that.category,_that.id,_that.brandColor,_that.iconUrl,_that.description,_that.plans,_that.features,_that.maxSlots);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  double price,  String billingPeriod,  String category,  String? id,  String? brandColor,  String? iconUrl,  String? description,  List<PresetPlan> plans,  List<String> features,  int maxSlots)?  $default,) {final _that = this;
switch (_that) {
case _PresetPackage() when $default != null:
return $default(_that.name,_that.price,_that.billingPeriod,_that.category,_that.id,_that.brandColor,_that.iconUrl,_that.description,_that.plans,_that.features,_that.maxSlots);case _:
  return null;

}
}

}

/// @nodoc


class _PresetPackage implements PresetPackage {
  const _PresetPackage({required this.name, required this.price, required this.billingPeriod, required this.category, this.id, this.brandColor, this.iconUrl, this.description, final  List<PresetPlan> plans = const [], final  List<String> features = const [], this.maxSlots = 1}): _plans = plans,_features = features;
  

@override final  String name;
@override final  double price;
@override final  String billingPeriod;
@override final  String category;
@override final  String? id;
@override final  String? brandColor;
@override final  String? iconUrl;
@override final  String? description;
 final  List<PresetPlan> _plans;
@override@JsonKey() List<PresetPlan> get plans {
  if (_plans is EqualUnmodifiableListView) return _plans;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_plans);
}

 final  List<String> _features;
@override@JsonKey() List<String> get features {
  if (_features is EqualUnmodifiableListView) return _features;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_features);
}

@override@JsonKey() final  int maxSlots;

/// Create a copy of PresetPackage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresetPackageCopyWith<_PresetPackage> get copyWith => __$PresetPackageCopyWithImpl<_PresetPackage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresetPackage&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price)&&(identical(other.billingPeriod, billingPeriod) || other.billingPeriod == billingPeriod)&&(identical(other.category, category) || other.category == category)&&(identical(other.id, id) || other.id == id)&&(identical(other.brandColor, brandColor) || other.brandColor == brandColor)&&(identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._plans, _plans)&&const DeepCollectionEquality().equals(other._features, _features)&&(identical(other.maxSlots, maxSlots) || other.maxSlots == maxSlots));
}


@override
int get hashCode => Object.hash(runtimeType,name,price,billingPeriod,category,id,brandColor,iconUrl,description,const DeepCollectionEquality().hash(_plans),const DeepCollectionEquality().hash(_features),maxSlots);

@override
String toString() {
  return 'PresetPackage(name: $name, price: $price, billingPeriod: $billingPeriod, category: $category, id: $id, brandColor: $brandColor, iconUrl: $iconUrl, description: $description, plans: $plans, features: $features, maxSlots: $maxSlots)';
}


}

/// @nodoc
abstract mixin class _$PresetPackageCopyWith<$Res> implements $PresetPackageCopyWith<$Res> {
  factory _$PresetPackageCopyWith(_PresetPackage value, $Res Function(_PresetPackage) _then) = __$PresetPackageCopyWithImpl;
@override @useResult
$Res call({
 String name, double price, String billingPeriod, String category, String? id, String? brandColor, String? iconUrl, String? description, List<PresetPlan> plans, List<String> features, int maxSlots
});




}
/// @nodoc
class __$PresetPackageCopyWithImpl<$Res>
    implements _$PresetPackageCopyWith<$Res> {
  __$PresetPackageCopyWithImpl(this._self, this._then);

  final _PresetPackage _self;
  final $Res Function(_PresetPackage) _then;

/// Create a copy of PresetPackage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? price = null,Object? billingPeriod = null,Object? category = null,Object? id = freezed,Object? brandColor = freezed,Object? iconUrl = freezed,Object? description = freezed,Object? plans = null,Object? features = null,Object? maxSlots = null,}) {
  return _then(_PresetPackage(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,billingPeriod: null == billingPeriod ? _self.billingPeriod : billingPeriod // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,brandColor: freezed == brandColor ? _self.brandColor : brandColor // ignore: cast_nullable_to_non_nullable
as String?,iconUrl: freezed == iconUrl ? _self.iconUrl : iconUrl // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,plans: null == plans ? _self._plans : plans // ignore: cast_nullable_to_non_nullable
as List<PresetPlan>,features: null == features ? _self._features : features // ignore: cast_nullable_to_non_nullable
as List<String>,maxSlots: null == maxSlots ? _self.maxSlots : maxSlots // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
