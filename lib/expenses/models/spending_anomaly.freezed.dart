// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'spending_anomaly.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SpendingAnomaly {

 AnomalyType get type; String get label; double get currentAmount; double get averageAmount;
/// Create a copy of SpendingAnomaly
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpendingAnomalyCopyWith<SpendingAnomaly> get copyWith => _$SpendingAnomalyCopyWithImpl<SpendingAnomaly>(this as SpendingAnomaly, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpendingAnomaly&&(identical(other.type, type) || other.type == type)&&(identical(other.label, label) || other.label == label)&&(identical(other.currentAmount, currentAmount) || other.currentAmount == currentAmount)&&(identical(other.averageAmount, averageAmount) || other.averageAmount == averageAmount));
}


@override
int get hashCode => Object.hash(runtimeType,type,label,currentAmount,averageAmount);

@override
String toString() {
  return 'SpendingAnomaly(type: $type, label: $label, currentAmount: $currentAmount, averageAmount: $averageAmount)';
}


}

/// @nodoc
abstract mixin class $SpendingAnomalyCopyWith<$Res>  {
  factory $SpendingAnomalyCopyWith(SpendingAnomaly value, $Res Function(SpendingAnomaly) _then) = _$SpendingAnomalyCopyWithImpl;
@useResult
$Res call({
 AnomalyType type, String label, double currentAmount, double averageAmount
});




}
/// @nodoc
class _$SpendingAnomalyCopyWithImpl<$Res>
    implements $SpendingAnomalyCopyWith<$Res> {
  _$SpendingAnomalyCopyWithImpl(this._self, this._then);

  final SpendingAnomaly _self;
  final $Res Function(SpendingAnomaly) _then;

/// Create a copy of SpendingAnomaly
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? label = null,Object? currentAmount = null,Object? averageAmount = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AnomalyType,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,currentAmount: null == currentAmount ? _self.currentAmount : currentAmount // ignore: cast_nullable_to_non_nullable
as double,averageAmount: null == averageAmount ? _self.averageAmount : averageAmount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [SpendingAnomaly].
extension SpendingAnomalyPatterns on SpendingAnomaly {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpendingAnomaly value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpendingAnomaly() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpendingAnomaly value)  $default,){
final _that = this;
switch (_that) {
case _SpendingAnomaly():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpendingAnomaly value)?  $default,){
final _that = this;
switch (_that) {
case _SpendingAnomaly() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AnomalyType type,  String label,  double currentAmount,  double averageAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpendingAnomaly() when $default != null:
return $default(_that.type,_that.label,_that.currentAmount,_that.averageAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AnomalyType type,  String label,  double currentAmount,  double averageAmount)  $default,) {final _that = this;
switch (_that) {
case _SpendingAnomaly():
return $default(_that.type,_that.label,_that.currentAmount,_that.averageAmount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AnomalyType type,  String label,  double currentAmount,  double averageAmount)?  $default,) {final _that = this;
switch (_that) {
case _SpendingAnomaly() when $default != null:
return $default(_that.type,_that.label,_that.currentAmount,_that.averageAmount);case _:
  return null;

}
}

}

/// @nodoc


class _SpendingAnomaly extends SpendingAnomaly {
   _SpendingAnomaly({required this.type, required this.label, required this.currentAmount, required this.averageAmount}): super._();
  

@override final  AnomalyType type;
@override final  String label;
@override final  double currentAmount;
@override final  double averageAmount;

/// Create a copy of SpendingAnomaly
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpendingAnomalyCopyWith<_SpendingAnomaly> get copyWith => __$SpendingAnomalyCopyWithImpl<_SpendingAnomaly>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpendingAnomaly&&(identical(other.type, type) || other.type == type)&&(identical(other.label, label) || other.label == label)&&(identical(other.currentAmount, currentAmount) || other.currentAmount == currentAmount)&&(identical(other.averageAmount, averageAmount) || other.averageAmount == averageAmount));
}


@override
int get hashCode => Object.hash(runtimeType,type,label,currentAmount,averageAmount);

@override
String toString() {
  return 'SpendingAnomaly(type: $type, label: $label, currentAmount: $currentAmount, averageAmount: $averageAmount)';
}


}

/// @nodoc
abstract mixin class _$SpendingAnomalyCopyWith<$Res> implements $SpendingAnomalyCopyWith<$Res> {
  factory _$SpendingAnomalyCopyWith(_SpendingAnomaly value, $Res Function(_SpendingAnomaly) _then) = __$SpendingAnomalyCopyWithImpl;
@override @useResult
$Res call({
 AnomalyType type, String label, double currentAmount, double averageAmount
});




}
/// @nodoc
class __$SpendingAnomalyCopyWithImpl<$Res>
    implements _$SpendingAnomalyCopyWith<$Res> {
  __$SpendingAnomalyCopyWithImpl(this._self, this._then);

  final _SpendingAnomaly _self;
  final $Res Function(_SpendingAnomaly) _then;

/// Create a copy of SpendingAnomaly
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? label = null,Object? currentAmount = null,Object? averageAmount = null,}) {
  return _then(_SpendingAnomaly(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AnomalyType,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,currentAmount: null == currentAmount ? _self.currentAmount : currentAmount // ignore: cast_nullable_to_non_nullable
as double,averageAmount: null == averageAmount ? _self.averageAmount : averageAmount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
