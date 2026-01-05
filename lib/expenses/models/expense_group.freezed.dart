// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expense_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExpenseGroup {

 String get id; String get name; String? get merchant; List<String> get expenseIds; String? get receiptImageUri;@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? get createdAt; String? get currency; double? get totalAmount;@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? get receiptDate;
/// Create a copy of ExpenseGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseGroupCopyWith<ExpenseGroup> get copyWith => _$ExpenseGroupCopyWithImpl<ExpenseGroup>(this as ExpenseGroup, _$identity);

  /// Serializes this ExpenseGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpenseGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&const DeepCollectionEquality().equals(other.expenseIds, expenseIds)&&(identical(other.receiptImageUri, receiptImageUri) || other.receiptImageUri == receiptImageUri)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.receiptDate, receiptDate) || other.receiptDate == receiptDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,merchant,const DeepCollectionEquality().hash(expenseIds),receiptImageUri,createdAt,currency,totalAmount,receiptDate);

@override
String toString() {
  return 'ExpenseGroup(id: $id, name: $name, merchant: $merchant, expenseIds: $expenseIds, receiptImageUri: $receiptImageUri, createdAt: $createdAt, currency: $currency, totalAmount: $totalAmount, receiptDate: $receiptDate)';
}


}

/// @nodoc
abstract mixin class $ExpenseGroupCopyWith<$Res>  {
  factory $ExpenseGroupCopyWith(ExpenseGroup value, $Res Function(ExpenseGroup) _then) = _$ExpenseGroupCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? merchant, List<String> expenseIds, String? receiptImageUri,@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? createdAt, String? currency, double? totalAmount,@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? receiptDate
});




}
/// @nodoc
class _$ExpenseGroupCopyWithImpl<$Res>
    implements $ExpenseGroupCopyWith<$Res> {
  _$ExpenseGroupCopyWithImpl(this._self, this._then);

  final ExpenseGroup _self;
  final $Res Function(ExpenseGroup) _then;

/// Create a copy of ExpenseGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? merchant = freezed,Object? expenseIds = null,Object? receiptImageUri = freezed,Object? createdAt = freezed,Object? currency = freezed,Object? totalAmount = freezed,Object? receiptDate = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,expenseIds: null == expenseIds ? _self.expenseIds : expenseIds // ignore: cast_nullable_to_non_nullable
as List<String>,receiptImageUri: freezed == receiptImageUri ? _self.receiptImageUri : receiptImageUri // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,totalAmount: freezed == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double?,receiptDate: freezed == receiptDate ? _self.receiptDate : receiptDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExpenseGroup].
extension ExpenseGroupPatterns on ExpenseGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExpenseGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExpenseGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExpenseGroup value)  $default,){
final _that = this;
switch (_that) {
case _ExpenseGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExpenseGroup value)?  $default,){
final _that = this;
switch (_that) {
case _ExpenseGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? merchant,  List<String> expenseIds,  String? receiptImageUri, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? createdAt,  String? currency,  double? totalAmount, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? receiptDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExpenseGroup() when $default != null:
return $default(_that.id,_that.name,_that.merchant,_that.expenseIds,_that.receiptImageUri,_that.createdAt,_that.currency,_that.totalAmount,_that.receiptDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? merchant,  List<String> expenseIds,  String? receiptImageUri, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? createdAt,  String? currency,  double? totalAmount, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? receiptDate)  $default,) {final _that = this;
switch (_that) {
case _ExpenseGroup():
return $default(_that.id,_that.name,_that.merchant,_that.expenseIds,_that.receiptImageUri,_that.createdAt,_that.currency,_that.totalAmount,_that.receiptDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? merchant,  List<String> expenseIds,  String? receiptImageUri, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? createdAt,  String? currency,  double? totalAmount, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? receiptDate)?  $default,) {final _that = this;
switch (_that) {
case _ExpenseGroup() when $default != null:
return $default(_that.id,_that.name,_that.merchant,_that.expenseIds,_that.receiptImageUri,_that.createdAt,_that.currency,_that.totalAmount,_that.receiptDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExpenseGroup extends ExpenseGroup {
   _ExpenseGroup({required this.id, required this.name, this.merchant, final  List<String> expenseIds = const <String>[], this.receiptImageUri, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) this.createdAt, this.currency, this.totalAmount, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) this.receiptDate}): _expenseIds = expenseIds,super._();
  factory _ExpenseGroup.fromJson(Map<String, dynamic> json) => _$ExpenseGroupFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? merchant;
 final  List<String> _expenseIds;
@override@JsonKey() List<String> get expenseIds {
  if (_expenseIds is EqualUnmodifiableListView) return _expenseIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_expenseIds);
}

@override final  String? receiptImageUri;
@override@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) final  DateTime? createdAt;
@override final  String? currency;
@override final  double? totalAmount;
@override@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) final  DateTime? receiptDate;

/// Create a copy of ExpenseGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseGroupCopyWith<_ExpenseGroup> get copyWith => __$ExpenseGroupCopyWithImpl<_ExpenseGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExpenseGroupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExpenseGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&const DeepCollectionEquality().equals(other._expenseIds, _expenseIds)&&(identical(other.receiptImageUri, receiptImageUri) || other.receiptImageUri == receiptImageUri)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.receiptDate, receiptDate) || other.receiptDate == receiptDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,merchant,const DeepCollectionEquality().hash(_expenseIds),receiptImageUri,createdAt,currency,totalAmount,receiptDate);

@override
String toString() {
  return 'ExpenseGroup(id: $id, name: $name, merchant: $merchant, expenseIds: $expenseIds, receiptImageUri: $receiptImageUri, createdAt: $createdAt, currency: $currency, totalAmount: $totalAmount, receiptDate: $receiptDate)';
}


}

/// @nodoc
abstract mixin class _$ExpenseGroupCopyWith<$Res> implements $ExpenseGroupCopyWith<$Res> {
  factory _$ExpenseGroupCopyWith(_ExpenseGroup value, $Res Function(_ExpenseGroup) _then) = __$ExpenseGroupCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? merchant, List<String> expenseIds, String? receiptImageUri,@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? createdAt, String? currency, double? totalAmount,@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? receiptDate
});




}
/// @nodoc
class __$ExpenseGroupCopyWithImpl<$Res>
    implements _$ExpenseGroupCopyWith<$Res> {
  __$ExpenseGroupCopyWithImpl(this._self, this._then);

  final _ExpenseGroup _self;
  final $Res Function(_ExpenseGroup) _then;

/// Create a copy of ExpenseGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? merchant = freezed,Object? expenseIds = null,Object? receiptImageUri = freezed,Object? createdAt = freezed,Object? currency = freezed,Object? totalAmount = freezed,Object? receiptDate = freezed,}) {
  return _then(_ExpenseGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,expenseIds: null == expenseIds ? _self._expenseIds : expenseIds // ignore: cast_nullable_to_non_nullable
as List<String>,receiptImageUri: freezed == receiptImageUri ? _self.receiptImageUri : receiptImageUri // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,totalAmount: freezed == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double?,receiptDate: freezed == receiptDate ? _self.receiptDate : receiptDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
