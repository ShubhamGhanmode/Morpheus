// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurring_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecurringTransaction {

 String get id; String get title; double get amount; String get currency; String get category;@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime get startDate; RecurrenceFrequency get frequency; int get interval;@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? get lastGenerated; bool get active; String? get note; String get paymentSourceType; String? get paymentSourceId;
/// Create a copy of RecurringTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurringTransactionCopyWith<RecurringTransaction> get copyWith => _$RecurringTransactionCopyWithImpl<RecurringTransaction>(this as RecurringTransaction, _$identity);

  /// Serializes this RecurringTransaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.category, category) || other.category == category)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.interval, interval) || other.interval == interval)&&(identical(other.lastGenerated, lastGenerated) || other.lastGenerated == lastGenerated)&&(identical(other.active, active) || other.active == active)&&(identical(other.note, note) || other.note == note)&&(identical(other.paymentSourceType, paymentSourceType) || other.paymentSourceType == paymentSourceType)&&(identical(other.paymentSourceId, paymentSourceId) || other.paymentSourceId == paymentSourceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,amount,currency,category,startDate,frequency,interval,lastGenerated,active,note,paymentSourceType,paymentSourceId);

@override
String toString() {
  return 'RecurringTransaction(id: $id, title: $title, amount: $amount, currency: $currency, category: $category, startDate: $startDate, frequency: $frequency, interval: $interval, lastGenerated: $lastGenerated, active: $active, note: $note, paymentSourceType: $paymentSourceType, paymentSourceId: $paymentSourceId)';
}


}

/// @nodoc
abstract mixin class $RecurringTransactionCopyWith<$Res>  {
  factory $RecurringTransactionCopyWith(RecurringTransaction value, $Res Function(RecurringTransaction) _then) = _$RecurringTransactionCopyWithImpl;
@useResult
$Res call({
 String id, String title, double amount, String currency, String category,@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime startDate, RecurrenceFrequency frequency, int interval,@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? lastGenerated, bool active, String? note, String paymentSourceType, String? paymentSourceId
});




}
/// @nodoc
class _$RecurringTransactionCopyWithImpl<$Res>
    implements $RecurringTransactionCopyWith<$Res> {
  _$RecurringTransactionCopyWithImpl(this._self, this._then);

  final RecurringTransaction _self;
  final $Res Function(RecurringTransaction) _then;

/// Create a copy of RecurringTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? amount = null,Object? currency = null,Object? category = null,Object? startDate = null,Object? frequency = null,Object? interval = null,Object? lastGenerated = freezed,Object? active = null,Object? note = freezed,Object? paymentSourceType = null,Object? paymentSourceId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as RecurrenceFrequency,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,lastGenerated: freezed == lastGenerated ? _self.lastGenerated : lastGenerated // ignore: cast_nullable_to_non_nullable
as DateTime?,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,paymentSourceType: null == paymentSourceType ? _self.paymentSourceType : paymentSourceType // ignore: cast_nullable_to_non_nullable
as String,paymentSourceId: freezed == paymentSourceId ? _self.paymentSourceId : paymentSourceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecurringTransaction].
extension RecurringTransactionPatterns on RecurringTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecurringTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecurringTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecurringTransaction value)  $default,){
final _that = this;
switch (_that) {
case _RecurringTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecurringTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _RecurringTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  double amount,  String currency,  String category, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime startDate,  RecurrenceFrequency frequency,  int interval, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? lastGenerated,  bool active,  String? note,  String paymentSourceType,  String? paymentSourceId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurringTransaction() when $default != null:
return $default(_that.id,_that.title,_that.amount,_that.currency,_that.category,_that.startDate,_that.frequency,_that.interval,_that.lastGenerated,_that.active,_that.note,_that.paymentSourceType,_that.paymentSourceId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  double amount,  String currency,  String category, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime startDate,  RecurrenceFrequency frequency,  int interval, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? lastGenerated,  bool active,  String? note,  String paymentSourceType,  String? paymentSourceId)  $default,) {final _that = this;
switch (_that) {
case _RecurringTransaction():
return $default(_that.id,_that.title,_that.amount,_that.currency,_that.category,_that.startDate,_that.frequency,_that.interval,_that.lastGenerated,_that.active,_that.note,_that.paymentSourceType,_that.paymentSourceId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  double amount,  String currency,  String category, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime startDate,  RecurrenceFrequency frequency,  int interval, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? lastGenerated,  bool active,  String? note,  String paymentSourceType,  String? paymentSourceId)?  $default,) {final _that = this;
switch (_that) {
case _RecurringTransaction() when $default != null:
return $default(_that.id,_that.title,_that.amount,_that.currency,_that.category,_that.startDate,_that.frequency,_that.interval,_that.lastGenerated,_that.active,_that.note,_that.paymentSourceType,_that.paymentSourceId);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _RecurringTransaction extends RecurringTransaction {
   _RecurringTransaction({required this.id, required this.title, required this.amount, required this.currency, required this.category, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) required this.startDate, this.frequency = RecurrenceFrequency.monthly, this.interval = 1, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) this.lastGenerated, this.active = true, this.note, this.paymentSourceType = 'cash', this.paymentSourceId}): super._();
  factory _RecurringTransaction.fromJson(Map<String, dynamic> json) => _$RecurringTransactionFromJson(json);

@override final  String id;
@override final  String title;
@override final  double amount;
@override final  String currency;
@override final  String category;
@override@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) final  DateTime startDate;
@override@JsonKey() final  RecurrenceFrequency frequency;
@override@JsonKey() final  int interval;
@override@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) final  DateTime? lastGenerated;
@override@JsonKey() final  bool active;
@override final  String? note;
@override@JsonKey() final  String paymentSourceType;
@override final  String? paymentSourceId;

/// Create a copy of RecurringTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurringTransactionCopyWith<_RecurringTransaction> get copyWith => __$RecurringTransactionCopyWithImpl<_RecurringTransaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecurringTransactionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurringTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.category, category) || other.category == category)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.interval, interval) || other.interval == interval)&&(identical(other.lastGenerated, lastGenerated) || other.lastGenerated == lastGenerated)&&(identical(other.active, active) || other.active == active)&&(identical(other.note, note) || other.note == note)&&(identical(other.paymentSourceType, paymentSourceType) || other.paymentSourceType == paymentSourceType)&&(identical(other.paymentSourceId, paymentSourceId) || other.paymentSourceId == paymentSourceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,amount,currency,category,startDate,frequency,interval,lastGenerated,active,note,paymentSourceType,paymentSourceId);

@override
String toString() {
  return 'RecurringTransaction(id: $id, title: $title, amount: $amount, currency: $currency, category: $category, startDate: $startDate, frequency: $frequency, interval: $interval, lastGenerated: $lastGenerated, active: $active, note: $note, paymentSourceType: $paymentSourceType, paymentSourceId: $paymentSourceId)';
}


}

/// @nodoc
abstract mixin class _$RecurringTransactionCopyWith<$Res> implements $RecurringTransactionCopyWith<$Res> {
  factory _$RecurringTransactionCopyWith(_RecurringTransaction value, $Res Function(_RecurringTransaction) _then) = __$RecurringTransactionCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, double amount, String currency, String category,@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime startDate, RecurrenceFrequency frequency, int interval,@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? lastGenerated, bool active, String? note, String paymentSourceType, String? paymentSourceId
});




}
/// @nodoc
class __$RecurringTransactionCopyWithImpl<$Res>
    implements _$RecurringTransactionCopyWith<$Res> {
  __$RecurringTransactionCopyWithImpl(this._self, this._then);

  final _RecurringTransaction _self;
  final $Res Function(_RecurringTransaction) _then;

/// Create a copy of RecurringTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? amount = null,Object? currency = null,Object? category = null,Object? startDate = null,Object? frequency = null,Object? interval = null,Object? lastGenerated = freezed,Object? active = null,Object? note = freezed,Object? paymentSourceType = null,Object? paymentSourceId = freezed,}) {
  return _then(_RecurringTransaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as RecurrenceFrequency,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,lastGenerated: freezed == lastGenerated ? _self.lastGenerated : lastGenerated // ignore: cast_nullable_to_non_nullable
as DateTime?,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,paymentSourceType: null == paymentSourceType ? _self.paymentSourceType : paymentSourceType // ignore: cast_nullable_to_non_nullable
as String,paymentSourceId: freezed == paymentSourceId ? _self.paymentSourceId : paymentSourceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
