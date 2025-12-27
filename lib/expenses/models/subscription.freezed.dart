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

 String get id; String get name; double get amount; String get currency;@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime get renewalDate; RecurrenceFrequency get frequency; int get interval;@JsonKey(fromJson: intListFromJson, toJson: intListToJson) List<int> get reminderOffsets; bool get active; String? get category; String? get note;@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? get lastNotified;
/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionCopyWith<Subscription> get copyWith => _$SubscriptionCopyWithImpl<Subscription>(this as Subscription, _$identity);

  /// Serializes this Subscription to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Subscription&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.renewalDate, renewalDate) || other.renewalDate == renewalDate)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.interval, interval) || other.interval == interval)&&const DeepCollectionEquality().equals(other.reminderOffsets, reminderOffsets)&&(identical(other.active, active) || other.active == active)&&(identical(other.category, category) || other.category == category)&&(identical(other.note, note) || other.note == note)&&(identical(other.lastNotified, lastNotified) || other.lastNotified == lastNotified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,amount,currency,renewalDate,frequency,interval,const DeepCollectionEquality().hash(reminderOffsets),active,category,note,lastNotified);

@override
String toString() {
  return 'Subscription(id: $id, name: $name, amount: $amount, currency: $currency, renewalDate: $renewalDate, frequency: $frequency, interval: $interval, reminderOffsets: $reminderOffsets, active: $active, category: $category, note: $note, lastNotified: $lastNotified)';
}


}

/// @nodoc
abstract mixin class $SubscriptionCopyWith<$Res>  {
  factory $SubscriptionCopyWith(Subscription value, $Res Function(Subscription) _then) = _$SubscriptionCopyWithImpl;
@useResult
$Res call({
 String id, String name, double amount, String currency,@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime renewalDate, RecurrenceFrequency frequency, int interval,@JsonKey(fromJson: intListFromJson, toJson: intListToJson) List<int> reminderOffsets, bool active, String? category, String? note,@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? lastNotified
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? amount = null,Object? currency = null,Object? renewalDate = null,Object? frequency = null,Object? interval = null,Object? reminderOffsets = null,Object? active = null,Object? category = freezed,Object? note = freezed,Object? lastNotified = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,renewalDate: null == renewalDate ? _self.renewalDate : renewalDate // ignore: cast_nullable_to_non_nullable
as DateTime,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as RecurrenceFrequency,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,reminderOffsets: null == reminderOffsets ? _self.reminderOffsets : reminderOffsets // ignore: cast_nullable_to_non_nullable
as List<int>,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,lastNotified: freezed == lastNotified ? _self.lastNotified : lastNotified // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  double amount,  String currency, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime renewalDate,  RecurrenceFrequency frequency,  int interval, @JsonKey(fromJson: intListFromJson, toJson: intListToJson)  List<int> reminderOffsets,  bool active,  String? category,  String? note, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? lastNotified)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that.id,_that.name,_that.amount,_that.currency,_that.renewalDate,_that.frequency,_that.interval,_that.reminderOffsets,_that.active,_that.category,_that.note,_that.lastNotified);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  double amount,  String currency, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime renewalDate,  RecurrenceFrequency frequency,  int interval, @JsonKey(fromJson: intListFromJson, toJson: intListToJson)  List<int> reminderOffsets,  bool active,  String? category,  String? note, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? lastNotified)  $default,) {final _that = this;
switch (_that) {
case _Subscription():
return $default(_that.id,_that.name,_that.amount,_that.currency,_that.renewalDate,_that.frequency,_that.interval,_that.reminderOffsets,_that.active,_that.category,_that.note,_that.lastNotified);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  double amount,  String currency, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime renewalDate,  RecurrenceFrequency frequency,  int interval, @JsonKey(fromJson: intListFromJson, toJson: intListToJson)  List<int> reminderOffsets,  bool active,  String? category,  String? note, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? lastNotified)?  $default,) {final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that.id,_that.name,_that.amount,_that.currency,_that.renewalDate,_that.frequency,_that.interval,_that.reminderOffsets,_that.active,_that.category,_that.note,_that.lastNotified);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _Subscription extends Subscription {
   _Subscription({required this.id, required this.name, required this.amount, required this.currency, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) required this.renewalDate, this.frequency = RecurrenceFrequency.monthly, this.interval = 1, @JsonKey(fromJson: intListFromJson, toJson: intListToJson) final  List<int> reminderOffsets = const <int>[], this.active = true, this.category, this.note, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) this.lastNotified}): _reminderOffsets = reminderOffsets,super._();
  factory _Subscription.fromJson(Map<String, dynamic> json) => _$SubscriptionFromJson(json);

@override final  String id;
@override final  String name;
@override final  double amount;
@override final  String currency;
@override@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) final  DateTime renewalDate;
@override@JsonKey() final  RecurrenceFrequency frequency;
@override@JsonKey() final  int interval;
 final  List<int> _reminderOffsets;
@override@JsonKey(fromJson: intListFromJson, toJson: intListToJson) List<int> get reminderOffsets {
  if (_reminderOffsets is EqualUnmodifiableListView) return _reminderOffsets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reminderOffsets);
}

@override@JsonKey() final  bool active;
@override final  String? category;
@override final  String? note;
@override@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) final  DateTime? lastNotified;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Subscription&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.renewalDate, renewalDate) || other.renewalDate == renewalDate)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.interval, interval) || other.interval == interval)&&const DeepCollectionEquality().equals(other._reminderOffsets, _reminderOffsets)&&(identical(other.active, active) || other.active == active)&&(identical(other.category, category) || other.category == category)&&(identical(other.note, note) || other.note == note)&&(identical(other.lastNotified, lastNotified) || other.lastNotified == lastNotified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,amount,currency,renewalDate,frequency,interval,const DeepCollectionEquality().hash(_reminderOffsets),active,category,note,lastNotified);

@override
String toString() {
  return 'Subscription(id: $id, name: $name, amount: $amount, currency: $currency, renewalDate: $renewalDate, frequency: $frequency, interval: $interval, reminderOffsets: $reminderOffsets, active: $active, category: $category, note: $note, lastNotified: $lastNotified)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionCopyWith<$Res> implements $SubscriptionCopyWith<$Res> {
  factory _$SubscriptionCopyWith(_Subscription value, $Res Function(_Subscription) _then) = __$SubscriptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, double amount, String currency,@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime renewalDate, RecurrenceFrequency frequency, int interval,@JsonKey(fromJson: intListFromJson, toJson: intListToJson) List<int> reminderOffsets, bool active, String? category, String? note,@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? lastNotified
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? amount = null,Object? currency = null,Object? renewalDate = null,Object? frequency = null,Object? interval = null,Object? reminderOffsets = null,Object? active = null,Object? category = freezed,Object? note = freezed,Object? lastNotified = freezed,}) {
  return _then(_Subscription(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,renewalDate: null == renewalDate ? _self.renewalDate : renewalDate // ignore: cast_nullable_to_non_nullable
as DateTime,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as RecurrenceFrequency,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,reminderOffsets: null == reminderOffsets ? _self._reminderOffsets : reminderOffsets // ignore: cast_nullable_to_non_nullable
as List<int>,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,lastNotified: freezed == lastNotified ? _self.lastNotified : lastNotified // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
