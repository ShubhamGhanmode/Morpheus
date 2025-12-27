// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_source_key.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PaymentSourceKey {

 String get type; String get id;
/// Create a copy of PaymentSourceKey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentSourceKeyCopyWith<PaymentSourceKey> get copyWith => _$PaymentSourceKeyCopyWithImpl<PaymentSourceKey>(this as PaymentSourceKey, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentSourceKey&&(identical(other.type, type) || other.type == type)&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,type,id);

@override
String toString() {
  return 'PaymentSourceKey(type: $type, id: $id)';
}


}

/// @nodoc
abstract mixin class $PaymentSourceKeyCopyWith<$Res>  {
  factory $PaymentSourceKeyCopyWith(PaymentSourceKey value, $Res Function(PaymentSourceKey) _then) = _$PaymentSourceKeyCopyWithImpl;
@useResult
$Res call({
 String type, String id
});




}
/// @nodoc
class _$PaymentSourceKeyCopyWithImpl<$Res>
    implements $PaymentSourceKeyCopyWith<$Res> {
  _$PaymentSourceKeyCopyWithImpl(this._self, this._then);

  final PaymentSourceKey _self;
  final $Res Function(PaymentSourceKey) _then;

/// Create a copy of PaymentSourceKey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? id = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentSourceKey].
extension PaymentSourceKeyPatterns on PaymentSourceKey {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentSourceKey value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentSourceKey() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentSourceKey value)  $default,){
final _that = this;
switch (_that) {
case _PaymentSourceKey():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentSourceKey value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentSourceKey() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String id)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentSourceKey() when $default != null:
return $default(_that.type,_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String id)  $default,) {final _that = this;
switch (_that) {
case _PaymentSourceKey():
return $default(_that.type,_that.id);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String id)?  $default,) {final _that = this;
switch (_that) {
case _PaymentSourceKey() when $default != null:
return $default(_that.type,_that.id);case _:
  return null;

}
}

}

/// @nodoc


class _PaymentSourceKey extends PaymentSourceKey {
  const _PaymentSourceKey({required this.type, required this.id}): super._();
  

@override final  String type;
@override final  String id;

/// Create a copy of PaymentSourceKey
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentSourceKeyCopyWith<_PaymentSourceKey> get copyWith => __$PaymentSourceKeyCopyWithImpl<_PaymentSourceKey>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentSourceKey&&(identical(other.type, type) || other.type == type)&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,type,id);

@override
String toString() {
  return 'PaymentSourceKey(type: $type, id: $id)';
}


}

/// @nodoc
abstract mixin class _$PaymentSourceKeyCopyWith<$Res> implements $PaymentSourceKeyCopyWith<$Res> {
  factory _$PaymentSourceKeyCopyWith(_PaymentSourceKey value, $Res Function(_PaymentSourceKey) _then) = __$PaymentSourceKeyCopyWithImpl;
@override @useResult
$Res call({
 String type, String id
});




}
/// @nodoc
class __$PaymentSourceKeyCopyWithImpl<$Res>
    implements _$PaymentSourceKeyCopyWith<$Res> {
  __$PaymentSourceKeyCopyWithImpl(this._self, this._then);

  final _PaymentSourceKey _self;
  final $Res Function(_PaymentSourceKey) _then;

/// Create a copy of PaymentSourceKey
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? id = null,}) {
  return _then(_PaymentSourceKey(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
