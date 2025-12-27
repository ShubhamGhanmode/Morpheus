// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'next_occurrence.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NextRecurring {

 RecurringTransaction get transaction; DateTime get nextDate;
/// Create a copy of NextRecurring
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NextRecurringCopyWith<NextRecurring> get copyWith => _$NextRecurringCopyWithImpl<NextRecurring>(this as NextRecurring, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NextRecurring&&(identical(other.transaction, transaction) || other.transaction == transaction)&&(identical(other.nextDate, nextDate) || other.nextDate == nextDate));
}


@override
int get hashCode => Object.hash(runtimeType,transaction,nextDate);

@override
String toString() {
  return 'NextRecurring(transaction: $transaction, nextDate: $nextDate)';
}


}

/// @nodoc
abstract mixin class $NextRecurringCopyWith<$Res>  {
  factory $NextRecurringCopyWith(NextRecurring value, $Res Function(NextRecurring) _then) = _$NextRecurringCopyWithImpl;
@useResult
$Res call({
 RecurringTransaction transaction, DateTime nextDate
});


$RecurringTransactionCopyWith<$Res> get transaction;

}
/// @nodoc
class _$NextRecurringCopyWithImpl<$Res>
    implements $NextRecurringCopyWith<$Res> {
  _$NextRecurringCopyWithImpl(this._self, this._then);

  final NextRecurring _self;
  final $Res Function(NextRecurring) _then;

/// Create a copy of NextRecurring
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? transaction = null,Object? nextDate = null,}) {
  return _then(_self.copyWith(
transaction: null == transaction ? _self.transaction : transaction // ignore: cast_nullable_to_non_nullable
as RecurringTransaction,nextDate: null == nextDate ? _self.nextDate : nextDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of NextRecurring
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecurringTransactionCopyWith<$Res> get transaction {
  
  return $RecurringTransactionCopyWith<$Res>(_self.transaction, (value) {
    return _then(_self.copyWith(transaction: value));
  });
}
}


/// Adds pattern-matching-related methods to [NextRecurring].
extension NextRecurringPatterns on NextRecurring {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NextRecurring value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NextRecurring() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NextRecurring value)  $default,){
final _that = this;
switch (_that) {
case _NextRecurring():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NextRecurring value)?  $default,){
final _that = this;
switch (_that) {
case _NextRecurring() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RecurringTransaction transaction,  DateTime nextDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NextRecurring() when $default != null:
return $default(_that.transaction,_that.nextDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RecurringTransaction transaction,  DateTime nextDate)  $default,) {final _that = this;
switch (_that) {
case _NextRecurring():
return $default(_that.transaction,_that.nextDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RecurringTransaction transaction,  DateTime nextDate)?  $default,) {final _that = this;
switch (_that) {
case _NextRecurring() when $default != null:
return $default(_that.transaction,_that.nextDate);case _:
  return null;

}
}

}

/// @nodoc


class _NextRecurring extends NextRecurring {
  const _NextRecurring({required this.transaction, required this.nextDate}): super._();
  

@override final  RecurringTransaction transaction;
@override final  DateTime nextDate;

/// Create a copy of NextRecurring
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NextRecurringCopyWith<_NextRecurring> get copyWith => __$NextRecurringCopyWithImpl<_NextRecurring>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NextRecurring&&(identical(other.transaction, transaction) || other.transaction == transaction)&&(identical(other.nextDate, nextDate) || other.nextDate == nextDate));
}


@override
int get hashCode => Object.hash(runtimeType,transaction,nextDate);

@override
String toString() {
  return 'NextRecurring(transaction: $transaction, nextDate: $nextDate)';
}


}

/// @nodoc
abstract mixin class _$NextRecurringCopyWith<$Res> implements $NextRecurringCopyWith<$Res> {
  factory _$NextRecurringCopyWith(_NextRecurring value, $Res Function(_NextRecurring) _then) = __$NextRecurringCopyWithImpl;
@override @useResult
$Res call({
 RecurringTransaction transaction, DateTime nextDate
});


@override $RecurringTransactionCopyWith<$Res> get transaction;

}
/// @nodoc
class __$NextRecurringCopyWithImpl<$Res>
    implements _$NextRecurringCopyWith<$Res> {
  __$NextRecurringCopyWithImpl(this._self, this._then);

  final _NextRecurring _self;
  final $Res Function(_NextRecurring) _then;

/// Create a copy of NextRecurring
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? transaction = null,Object? nextDate = null,}) {
  return _then(_NextRecurring(
transaction: null == transaction ? _self.transaction : transaction // ignore: cast_nullable_to_non_nullable
as RecurringTransaction,nextDate: null == nextDate ? _self.nextDate : nextDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of NextRecurring
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecurringTransactionCopyWith<$Res> get transaction {
  
  return $RecurringTransactionCopyWith<$Res>(_self.transaction, (value) {
    return _then(_self.copyWith(transaction: value));
  });
}
}

/// @nodoc
mixin _$NextSubscription {

 Subscription get subscription; DateTime get nextDate;
/// Create a copy of NextSubscription
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NextSubscriptionCopyWith<NextSubscription> get copyWith => _$NextSubscriptionCopyWithImpl<NextSubscription>(this as NextSubscription, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NextSubscription&&(identical(other.subscription, subscription) || other.subscription == subscription)&&(identical(other.nextDate, nextDate) || other.nextDate == nextDate));
}


@override
int get hashCode => Object.hash(runtimeType,subscription,nextDate);

@override
String toString() {
  return 'NextSubscription(subscription: $subscription, nextDate: $nextDate)';
}


}

/// @nodoc
abstract mixin class $NextSubscriptionCopyWith<$Res>  {
  factory $NextSubscriptionCopyWith(NextSubscription value, $Res Function(NextSubscription) _then) = _$NextSubscriptionCopyWithImpl;
@useResult
$Res call({
 Subscription subscription, DateTime nextDate
});


$SubscriptionCopyWith<$Res> get subscription;

}
/// @nodoc
class _$NextSubscriptionCopyWithImpl<$Res>
    implements $NextSubscriptionCopyWith<$Res> {
  _$NextSubscriptionCopyWithImpl(this._self, this._then);

  final NextSubscription _self;
  final $Res Function(NextSubscription) _then;

/// Create a copy of NextSubscription
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subscription = null,Object? nextDate = null,}) {
  return _then(_self.copyWith(
subscription: null == subscription ? _self.subscription : subscription // ignore: cast_nullable_to_non_nullable
as Subscription,nextDate: null == nextDate ? _self.nextDate : nextDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of NextSubscription
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubscriptionCopyWith<$Res> get subscription {
  
  return $SubscriptionCopyWith<$Res>(_self.subscription, (value) {
    return _then(_self.copyWith(subscription: value));
  });
}
}


/// Adds pattern-matching-related methods to [NextSubscription].
extension NextSubscriptionPatterns on NextSubscription {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NextSubscription value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NextSubscription() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NextSubscription value)  $default,){
final _that = this;
switch (_that) {
case _NextSubscription():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NextSubscription value)?  $default,){
final _that = this;
switch (_that) {
case _NextSubscription() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Subscription subscription,  DateTime nextDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NextSubscription() when $default != null:
return $default(_that.subscription,_that.nextDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Subscription subscription,  DateTime nextDate)  $default,) {final _that = this;
switch (_that) {
case _NextSubscription():
return $default(_that.subscription,_that.nextDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Subscription subscription,  DateTime nextDate)?  $default,) {final _that = this;
switch (_that) {
case _NextSubscription() when $default != null:
return $default(_that.subscription,_that.nextDate);case _:
  return null;

}
}

}

/// @nodoc


class _NextSubscription extends NextSubscription {
  const _NextSubscription({required this.subscription, required this.nextDate}): super._();
  

@override final  Subscription subscription;
@override final  DateTime nextDate;

/// Create a copy of NextSubscription
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NextSubscriptionCopyWith<_NextSubscription> get copyWith => __$NextSubscriptionCopyWithImpl<_NextSubscription>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NextSubscription&&(identical(other.subscription, subscription) || other.subscription == subscription)&&(identical(other.nextDate, nextDate) || other.nextDate == nextDate));
}


@override
int get hashCode => Object.hash(runtimeType,subscription,nextDate);

@override
String toString() {
  return 'NextSubscription(subscription: $subscription, nextDate: $nextDate)';
}


}

/// @nodoc
abstract mixin class _$NextSubscriptionCopyWith<$Res> implements $NextSubscriptionCopyWith<$Res> {
  factory _$NextSubscriptionCopyWith(_NextSubscription value, $Res Function(_NextSubscription) _then) = __$NextSubscriptionCopyWithImpl;
@override @useResult
$Res call({
 Subscription subscription, DateTime nextDate
});


@override $SubscriptionCopyWith<$Res> get subscription;

}
/// @nodoc
class __$NextSubscriptionCopyWithImpl<$Res>
    implements _$NextSubscriptionCopyWith<$Res> {
  __$NextSubscriptionCopyWithImpl(this._self, this._then);

  final _NextSubscription _self;
  final $Res Function(_NextSubscription) _then;

/// Create a copy of NextSubscription
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subscription = null,Object? nextDate = null,}) {
  return _then(_NextSubscription(
subscription: null == subscription ? _self.subscription : subscription // ignore: cast_nullable_to_non_nullable
as Subscription,nextDate: null == nextDate ? _self.nextDate : nextDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of NextSubscription
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubscriptionCopyWith<$Res> get subscription {
  
  return $SubscriptionCopyWith<$Res>(_self.subscription, (value) {
    return _then(_self.copyWith(subscription: value));
  });
}
}

// dart format on
