// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'card_payment_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CardPaymentDraft {

 double get amount; String get currency;@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime get date; String? get accountId; String? get note;
/// Create a copy of CardPaymentDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardPaymentDraftCopyWith<CardPaymentDraft> get copyWith => _$CardPaymentDraftCopyWithImpl<CardPaymentDraft>(this as CardPaymentDraft, _$identity);

  /// Serializes this CardPaymentDraft to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardPaymentDraft&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.date, date) || other.date == date)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amount,currency,date,accountId,note);

@override
String toString() {
  return 'CardPaymentDraft(amount: $amount, currency: $currency, date: $date, accountId: $accountId, note: $note)';
}


}

/// @nodoc
abstract mixin class $CardPaymentDraftCopyWith<$Res>  {
  factory $CardPaymentDraftCopyWith(CardPaymentDraft value, $Res Function(CardPaymentDraft) _then) = _$CardPaymentDraftCopyWithImpl;
@useResult
$Res call({
 double amount, String currency,@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime date, String? accountId, String? note
});




}
/// @nodoc
class _$CardPaymentDraftCopyWithImpl<$Res>
    implements $CardPaymentDraftCopyWith<$Res> {
  _$CardPaymentDraftCopyWithImpl(this._self, this._then);

  final CardPaymentDraft _self;
  final $Res Function(CardPaymentDraft) _then;

/// Create a copy of CardPaymentDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = null,Object? currency = null,Object? date = null,Object? accountId = freezed,Object? note = freezed,}) {
  return _then(_self.copyWith(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CardPaymentDraft].
extension CardPaymentDraftPatterns on CardPaymentDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardPaymentDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardPaymentDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardPaymentDraft value)  $default,){
final _that = this;
switch (_that) {
case _CardPaymentDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardPaymentDraft value)?  $default,){
final _that = this;
switch (_that) {
case _CardPaymentDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double amount,  String currency, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime date,  String? accountId,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardPaymentDraft() when $default != null:
return $default(_that.amount,_that.currency,_that.date,_that.accountId,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double amount,  String currency, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime date,  String? accountId,  String? note)  $default,) {final _that = this;
switch (_that) {
case _CardPaymentDraft():
return $default(_that.amount,_that.currency,_that.date,_that.accountId,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double amount,  String currency, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime date,  String? accountId,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _CardPaymentDraft() when $default != null:
return $default(_that.amount,_that.currency,_that.date,_that.accountId,_that.note);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _CardPaymentDraft extends CardPaymentDraft {
   _CardPaymentDraft({required this.amount, required this.currency, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) required this.date, this.accountId, this.note}): super._();
  factory _CardPaymentDraft.fromJson(Map<String, dynamic> json) => _$CardPaymentDraftFromJson(json);

@override final  double amount;
@override final  String currency;
@override@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) final  DateTime date;
@override final  String? accountId;
@override final  String? note;

/// Create a copy of CardPaymentDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardPaymentDraftCopyWith<_CardPaymentDraft> get copyWith => __$CardPaymentDraftCopyWithImpl<_CardPaymentDraft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CardPaymentDraftToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardPaymentDraft&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.date, date) || other.date == date)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amount,currency,date,accountId,note);

@override
String toString() {
  return 'CardPaymentDraft(amount: $amount, currency: $currency, date: $date, accountId: $accountId, note: $note)';
}


}

/// @nodoc
abstract mixin class _$CardPaymentDraftCopyWith<$Res> implements $CardPaymentDraftCopyWith<$Res> {
  factory _$CardPaymentDraftCopyWith(_CardPaymentDraft value, $Res Function(_CardPaymentDraft) _then) = __$CardPaymentDraftCopyWithImpl;
@override @useResult
$Res call({
 double amount, String currency,@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime date, String? accountId, String? note
});




}
/// @nodoc
class __$CardPaymentDraftCopyWithImpl<$Res>
    implements _$CardPaymentDraftCopyWith<$Res> {
  __$CardPaymentDraftCopyWithImpl(this._self, this._then);

  final _CardPaymentDraft _self;
  final $Res Function(_CardPaymentDraft) _then;

/// Create a copy of CardPaymentDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? currency = null,Object? date = null,Object? accountId = freezed,Object? note = freezed,}) {
  return _then(_CardPaymentDraft(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
