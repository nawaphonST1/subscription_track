// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'package.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Package {

 String get id; String get name; String get description; String get category; double get defaultPrice; String get billingPeriod; String get iconUrl; String get websiteUrl; bool get isActive;
/// Create a copy of Package
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PackageCopyWith<Package> get copyWith => _$PackageCopyWithImpl<Package>(this as Package, _$identity);

  /// Serializes this Package to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Package&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.defaultPrice, defaultPrice) || other.defaultPrice == defaultPrice)&&(identical(other.billingPeriod, billingPeriod) || other.billingPeriod == billingPeriod)&&(identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl)&&(identical(other.websiteUrl, websiteUrl) || other.websiteUrl == websiteUrl)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,category,defaultPrice,billingPeriod,iconUrl,websiteUrl,isActive);

@override
String toString() {
  return 'Package(id: $id, name: $name, description: $description, category: $category, defaultPrice: $defaultPrice, billingPeriod: $billingPeriod, iconUrl: $iconUrl, websiteUrl: $websiteUrl, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $PackageCopyWith<$Res>  {
  factory $PackageCopyWith(Package value, $Res Function(Package) _then) = _$PackageCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, String category, double defaultPrice, String billingPeriod, String iconUrl, String websiteUrl, bool isActive
});




}
/// @nodoc
class _$PackageCopyWithImpl<$Res>
    implements $PackageCopyWith<$Res> {
  _$PackageCopyWithImpl(this._self, this._then);

  final Package _self;
  final $Res Function(Package) _then;

/// Create a copy of Package
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? category = null,Object? defaultPrice = null,Object? billingPeriod = null,Object? iconUrl = null,Object? websiteUrl = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,defaultPrice: null == defaultPrice ? _self.defaultPrice : defaultPrice // ignore: cast_nullable_to_non_nullable
as double,billingPeriod: null == billingPeriod ? _self.billingPeriod : billingPeriod // ignore: cast_nullable_to_non_nullable
as String,iconUrl: null == iconUrl ? _self.iconUrl : iconUrl // ignore: cast_nullable_to_non_nullable
as String,websiteUrl: null == websiteUrl ? _self.websiteUrl : websiteUrl // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Package].
extension PackagePatterns on Package {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Package value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Package() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Package value)  $default,){
final _that = this;
switch (_that) {
case _Package():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Package value)?  $default,){
final _that = this;
switch (_that) {
case _Package() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  String category,  double defaultPrice,  String billingPeriod,  String iconUrl,  String websiteUrl,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Package() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.category,_that.defaultPrice,_that.billingPeriod,_that.iconUrl,_that.websiteUrl,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  String category,  double defaultPrice,  String billingPeriod,  String iconUrl,  String websiteUrl,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _Package():
return $default(_that.id,_that.name,_that.description,_that.category,_that.defaultPrice,_that.billingPeriod,_that.iconUrl,_that.websiteUrl,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  String category,  double defaultPrice,  String billingPeriod,  String iconUrl,  String websiteUrl,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _Package() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.category,_that.defaultPrice,_that.billingPeriod,_that.iconUrl,_that.websiteUrl,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Package implements Package {
  const _Package({required this.id, required this.name, this.description = '', this.category = 'other', this.defaultPrice = 0.0, this.billingPeriod = 'monthly', this.iconUrl = '', this.websiteUrl = '', this.isActive = true});
  factory _Package.fromJson(Map<String, dynamic> json) => _$PackageFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String description;
@override@JsonKey() final  String category;
@override@JsonKey() final  double defaultPrice;
@override@JsonKey() final  String billingPeriod;
@override@JsonKey() final  String iconUrl;
@override@JsonKey() final  String websiteUrl;
@override@JsonKey() final  bool isActive;

/// Create a copy of Package
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PackageCopyWith<_Package> get copyWith => __$PackageCopyWithImpl<_Package>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PackageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Package&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.defaultPrice, defaultPrice) || other.defaultPrice == defaultPrice)&&(identical(other.billingPeriod, billingPeriod) || other.billingPeriod == billingPeriod)&&(identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl)&&(identical(other.websiteUrl, websiteUrl) || other.websiteUrl == websiteUrl)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,category,defaultPrice,billingPeriod,iconUrl,websiteUrl,isActive);

@override
String toString() {
  return 'Package(id: $id, name: $name, description: $description, category: $category, defaultPrice: $defaultPrice, billingPeriod: $billingPeriod, iconUrl: $iconUrl, websiteUrl: $websiteUrl, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$PackageCopyWith<$Res> implements $PackageCopyWith<$Res> {
  factory _$PackageCopyWith(_Package value, $Res Function(_Package) _then) = __$PackageCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, String category, double defaultPrice, String billingPeriod, String iconUrl, String websiteUrl, bool isActive
});




}
/// @nodoc
class __$PackageCopyWithImpl<$Res>
    implements _$PackageCopyWith<$Res> {
  __$PackageCopyWithImpl(this._self, this._then);

  final _Package _self;
  final $Res Function(_Package) _then;

/// Create a copy of Package
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? category = null,Object? defaultPrice = null,Object? billingPeriod = null,Object? iconUrl = null,Object? websiteUrl = null,Object? isActive = null,}) {
  return _then(_Package(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,defaultPrice: null == defaultPrice ? _self.defaultPrice : defaultPrice // ignore: cast_nullable_to_non_nullable
as double,billingPeriod: null == billingPeriod ? _self.billingPeriod : billingPeriod // ignore: cast_nullable_to_non_nullable
as String,iconUrl: null == iconUrl ? _self.iconUrl : iconUrl // ignore: cast_nullable_to_non_nullable
as String,websiteUrl: null == websiteUrl ? _self.websiteUrl : websiteUrl // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
