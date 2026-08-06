// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Subscription {

 String get id; String get name; double get price; String get billingPeriod; String get category; DateTime? get nextBillingDate; String get usageStatus; int get confidence; bool get isSelected; List<Map<String, String>> get customFields; bool get reminderEnabled; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionCopyWith<Subscription> get copyWith => _$SubscriptionCopyWithImpl<Subscription>(this as Subscription, _$identity);

  /// Serializes this Subscription to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Subscription&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price)&&(identical(other.billingPeriod, billingPeriod) || other.billingPeriod == billingPeriod)&&(identical(other.category, category) || other.category == category)&&(identical(other.nextBillingDate, nextBillingDate) || other.nextBillingDate == nextBillingDate)&&(identical(other.usageStatus, usageStatus) || other.usageStatus == usageStatus)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.isSelected, isSelected) || other.isSelected == isSelected)&&const DeepCollectionEquality().equals(other.customFields, customFields)&&(identical(other.reminderEnabled, reminderEnabled) || other.reminderEnabled == reminderEnabled)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,price,billingPeriod,category,nextBillingDate,usageStatus,confidence,isSelected,const DeepCollectionEquality().hash(customFields),reminderEnabled,createdAt,updatedAt);

@override
String toString() {
  return 'Subscription(id: $id, name: $name, price: $price, billingPeriod: $billingPeriod, category: $category, nextBillingDate: $nextBillingDate, usageStatus: $usageStatus, confidence: $confidence, isSelected: $isSelected, customFields: $customFields, reminderEnabled: $reminderEnabled, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SubscriptionCopyWith<$Res>  {
  factory $SubscriptionCopyWith(Subscription value, $Res Function(Subscription) _then) = _$SubscriptionCopyWithImpl;
@useResult
$Res call({
 String id, String name, double price, String billingPeriod, String category, DateTime? nextBillingDate, String usageStatus, int confidence, bool isSelected, List<Map<String, String>> customFields, bool reminderEnabled, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$SubscriptionCopyWithImpl<$Res>
    implements $SubscriptionCopyWith<$Res> {
  _$SubscriptionCopyWithImpl(this._self, this._then);

  final Subscription _self;
  final $Res Function(Subscription) _then;

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? price = null,Object? billingPeriod = null,Object? category = null,Object? nextBillingDate = freezed,Object? usageStatus = null,Object? confidence = null,Object? isSelected = null,Object? customFields = null,Object? reminderEnabled = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,billingPeriod: null == billingPeriod ? _self.billingPeriod : billingPeriod // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,nextBillingDate: freezed == nextBillingDate ? _self.nextBillingDate : nextBillingDate // ignore: cast_nullable_to_non_nullable
as DateTime?,usageStatus: null == usageStatus ? _self.usageStatus : usageStatus // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as int,isSelected: null == isSelected ? _self.isSelected : isSelected // ignore: cast_nullable_to_non_nullable
as bool,customFields: null == customFields ? _self.customFields : customFields // ignore: cast_nullable_to_non_nullable
as List<Map<String, String>>,reminderEnabled: null == reminderEnabled ? _self.reminderEnabled : reminderEnabled // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Subscription].
extension SubscriptionPatterns on Subscription {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Subscription value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Subscription() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Subscription value)  $default,){
final _that = this;
switch (_that) {
case _Subscription():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Subscription value)?  $default,){
final _that = this;
switch (_that) {
case _Subscription() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  double price,  String billingPeriod,  String category,  DateTime? nextBillingDate,  String usageStatus,  int confidence,  bool isSelected,  List<Map<String, String>> customFields,  bool reminderEnabled,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that.id,_that.name,_that.price,_that.billingPeriod,_that.category,_that.nextBillingDate,_that.usageStatus,_that.confidence,_that.isSelected,_that.customFields,_that.reminderEnabled,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  double price,  String billingPeriod,  String category,  DateTime? nextBillingDate,  String usageStatus,  int confidence,  bool isSelected,  List<Map<String, String>> customFields,  bool reminderEnabled,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Subscription():
return $default(_that.id,_that.name,_that.price,_that.billingPeriod,_that.category,_that.nextBillingDate,_that.usageStatus,_that.confidence,_that.isSelected,_that.customFields,_that.reminderEnabled,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  double price,  String billingPeriod,  String category,  DateTime? nextBillingDate,  String usageStatus,  int confidence,  bool isSelected,  List<Map<String, String>> customFields,  bool reminderEnabled,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that.id,_that.name,_that.price,_that.billingPeriod,_that.category,_that.nextBillingDate,_that.usageStatus,_that.confidence,_that.isSelected,_that.customFields,_that.reminderEnabled,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Subscription implements Subscription {
  const _Subscription({required this.id, required this.name, required this.price, this.billingPeriod = 'monthly', this.category = 'other', this.nextBillingDate, this.usageStatus = 'moderate', this.confidence = 50, this.isSelected = false, final  List<Map<String, String>> customFields = const [], this.reminderEnabled = true, this.createdAt, this.updatedAt}): _customFields = customFields;
  factory _Subscription.fromJson(Map<String, dynamic> json) => _$SubscriptionFromJson(json);

@override final  String id;
@override final  String name;
@override final  double price;
@override@JsonKey() final  String billingPeriod;
@override@JsonKey() final  String category;
@override final  DateTime? nextBillingDate;
@override@JsonKey() final  String usageStatus;
@override@JsonKey() final  int confidence;
@override@JsonKey() final  bool isSelected;
 final  List<Map<String, String>> _customFields;
@override@JsonKey() List<Map<String, String>> get customFields {
  if (_customFields is EqualUnmodifiableListView) return _customFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_customFields);
}

@override@JsonKey() final  bool reminderEnabled;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionCopyWith<_Subscription> get copyWith => __$SubscriptionCopyWithImpl<_Subscription>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubscriptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Subscription&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price)&&(identical(other.billingPeriod, billingPeriod) || other.billingPeriod == billingPeriod)&&(identical(other.category, category) || other.category == category)&&(identical(other.nextBillingDate, nextBillingDate) || other.nextBillingDate == nextBillingDate)&&(identical(other.usageStatus, usageStatus) || other.usageStatus == usageStatus)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.isSelected, isSelected) || other.isSelected == isSelected)&&const DeepCollectionEquality().equals(other._customFields, _customFields)&&(identical(other.reminderEnabled, reminderEnabled) || other.reminderEnabled == reminderEnabled)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,price,billingPeriod,category,nextBillingDate,usageStatus,confidence,isSelected,const DeepCollectionEquality().hash(_customFields),reminderEnabled,createdAt,updatedAt);

@override
String toString() {
  return 'Subscription(id: $id, name: $name, price: $price, billingPeriod: $billingPeriod, category: $category, nextBillingDate: $nextBillingDate, usageStatus: $usageStatus, confidence: $confidence, isSelected: $isSelected, customFields: $customFields, reminderEnabled: $reminderEnabled, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionCopyWith<$Res> implements $SubscriptionCopyWith<$Res> {
  factory _$SubscriptionCopyWith(_Subscription value, $Res Function(_Subscription) _then) = __$SubscriptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, double price, String billingPeriod, String category, DateTime? nextBillingDate, String usageStatus, int confidence, bool isSelected, List<Map<String, String>> customFields, bool reminderEnabled, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$SubscriptionCopyWithImpl<$Res>
    implements _$SubscriptionCopyWith<$Res> {
  __$SubscriptionCopyWithImpl(this._self, this._then);

  final _Subscription _self;
  final $Res Function(_Subscription) _then;

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? price = null,Object? billingPeriod = null,Object? category = null,Object? nextBillingDate = freezed,Object? usageStatus = null,Object? confidence = null,Object? isSelected = null,Object? customFields = null,Object? reminderEnabled = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Subscription(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,billingPeriod: null == billingPeriod ? _self.billingPeriod : billingPeriod // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,nextBillingDate: freezed == nextBillingDate ? _self.nextBillingDate : nextBillingDate // ignore: cast_nullable_to_non_nullable
as DateTime?,usageStatus: null == usageStatus ? _self.usageStatus : usageStatus // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as int,isSelected: null == isSelected ? _self.isSelected : isSelected // ignore: cast_nullable_to_non_nullable
as bool,customFields: null == customFields ? _self._customFields : customFields // ignore: cast_nullable_to_non_nullable
as List<Map<String, String>>,reminderEnabled: null == reminderEnabled ? _self.reminderEnabled : reminderEnabled // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
