// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bill_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BillItem {

 CreditCard get card;@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime get due; double get amount; double get amountInBase; String get currency; bool get overdue;
/// Create a copy of BillItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillItemCopyWith<BillItem> get copyWith => _$BillItemCopyWithImpl<BillItem>(this as BillItem, _$identity);

  /// Serializes this BillItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillItem&&(identical(other.card, card) || other.card == card)&&(identical(other.due, due) || other.due == due)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.amountInBase, amountInBase) || other.amountInBase == amountInBase)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.overdue, overdue) || other.overdue == overdue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,card,due,amount,amountInBase,currency,overdue);

@override
String toString() {
  return 'BillItem(card: $card, due: $due, amount: $amount, amountInBase: $amountInBase, currency: $currency, overdue: $overdue)';
}


}

/// @nodoc
abstract mixin class $BillItemCopyWith<$Res>  {
  factory $BillItemCopyWith(BillItem value, $Res Function(BillItem) _then) = _$BillItemCopyWithImpl;
@useResult
$Res call({
 CreditCard card,@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime due, double amount, double amountInBase, String currency, bool overdue
});


$CreditCardCopyWith<$Res> get card;

}
/// @nodoc
class _$BillItemCopyWithImpl<$Res>
    implements $BillItemCopyWith<$Res> {
  _$BillItemCopyWithImpl(this._self, this._then);

  final BillItem _self;
  final $Res Function(BillItem) _then;

/// Create a copy of BillItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? card = null,Object? due = null,Object? amount = null,Object? amountInBase = null,Object? currency = null,Object? overdue = null,}) {
  return _then(_self.copyWith(
card: null == card ? _self.card : card // ignore: cast_nullable_to_non_nullable
as CreditCard,due: null == due ? _self.due : due // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,amountInBase: null == amountInBase ? _self.amountInBase : amountInBase // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,overdue: null == overdue ? _self.overdue : overdue // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of BillItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CreditCardCopyWith<$Res> get card {
  
  return $CreditCardCopyWith<$Res>(_self.card, (value) {
    return _then(_self.copyWith(card: value));
  });
}
}


/// Adds pattern-matching-related methods to [BillItem].
extension BillItemPatterns on BillItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BillItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BillItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BillItem value)  $default,){
final _that = this;
switch (_that) {
case _BillItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BillItem value)?  $default,){
final _that = this;
switch (_that) {
case _BillItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CreditCard card, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime due,  double amount,  double amountInBase,  String currency,  bool overdue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BillItem() when $default != null:
return $default(_that.card,_that.due,_that.amount,_that.amountInBase,_that.currency,_that.overdue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CreditCard card, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime due,  double amount,  double amountInBase,  String currency,  bool overdue)  $default,) {final _that = this;
switch (_that) {
case _BillItem():
return $default(_that.card,_that.due,_that.amount,_that.amountInBase,_that.currency,_that.overdue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CreditCard card, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime due,  double amount,  double amountInBase,  String currency,  bool overdue)?  $default,) {final _that = this;
switch (_that) {
case _BillItem() when $default != null:
return $default(_that.card,_that.due,_that.amount,_that.amountInBase,_that.currency,_that.overdue);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _BillItem extends BillItem {
   _BillItem({required this.card, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) required this.due, required this.amount, required this.amountInBase, required this.currency, required this.overdue}): super._();
  factory _BillItem.fromJson(Map<String, dynamic> json) => _$BillItemFromJson(json);

@override final  CreditCard card;
@override@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) final  DateTime due;
@override final  double amount;
@override final  double amountInBase;
@override final  String currency;
@override final  bool overdue;

/// Create a copy of BillItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BillItemCopyWith<_BillItem> get copyWith => __$BillItemCopyWithImpl<_BillItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BillItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BillItem&&(identical(other.card, card) || other.card == card)&&(identical(other.due, due) || other.due == due)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.amountInBase, amountInBase) || other.amountInBase == amountInBase)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.overdue, overdue) || other.overdue == overdue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,card,due,amount,amountInBase,currency,overdue);

@override
String toString() {
  return 'BillItem(card: $card, due: $due, amount: $amount, amountInBase: $amountInBase, currency: $currency, overdue: $overdue)';
}


}

/// @nodoc
abstract mixin class _$BillItemCopyWith<$Res> implements $BillItemCopyWith<$Res> {
  factory _$BillItemCopyWith(_BillItem value, $Res Function(_BillItem) _then) = __$BillItemCopyWithImpl;
@override @useResult
$Res call({
 CreditCard card,@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime due, double amount, double amountInBase, String currency, bool overdue
});


@override $CreditCardCopyWith<$Res> get card;

}
/// @nodoc
class __$BillItemCopyWithImpl<$Res>
    implements _$BillItemCopyWith<$Res> {
  __$BillItemCopyWithImpl(this._self, this._then);

  final _BillItem _self;
  final $Res Function(_BillItem) _then;

/// Create a copy of BillItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? card = null,Object? due = null,Object? amount = null,Object? amountInBase = null,Object? currency = null,Object? overdue = null,}) {
  return _then(_BillItem(
card: null == card ? _self.card : card // ignore: cast_nullable_to_non_nullable
as CreditCard,due: null == due ? _self.due : due // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,amountInBase: null == amountInBase ? _self.amountInBase : amountInBase // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,overdue: null == overdue ? _self.overdue : overdue // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of BillItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CreditCardCopyWith<$Res> get card {
  
  return $CreditCardCopyWith<$Res>(_self.card, (value) {
    return _then(_self.copyWith(card: value));
  });
}
}

// dart format on
