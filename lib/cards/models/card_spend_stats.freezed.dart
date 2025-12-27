// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'card_spend_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CardSpendStats {

@JsonKey(fromJson: statementWindowFromJson, toJson: statementWindowToJson) StatementWindow get window; double get statementBalance; double get unbilledBalance; double get totalBalance; double get statementCharges; double get statementPayments; double get statementBalanceBase; double get unbilledBalanceBase; double get totalBalanceBase; double get statementPaymentsBase; double? get available; double? get availableBase; double? get utilization;
/// Create a copy of CardSpendStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardSpendStatsCopyWith<CardSpendStats> get copyWith => _$CardSpendStatsCopyWithImpl<CardSpendStats>(this as CardSpendStats, _$identity);

  /// Serializes this CardSpendStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardSpendStats&&(identical(other.window, window) || other.window == window)&&(identical(other.statementBalance, statementBalance) || other.statementBalance == statementBalance)&&(identical(other.unbilledBalance, unbilledBalance) || other.unbilledBalance == unbilledBalance)&&(identical(other.totalBalance, totalBalance) || other.totalBalance == totalBalance)&&(identical(other.statementCharges, statementCharges) || other.statementCharges == statementCharges)&&(identical(other.statementPayments, statementPayments) || other.statementPayments == statementPayments)&&(identical(other.statementBalanceBase, statementBalanceBase) || other.statementBalanceBase == statementBalanceBase)&&(identical(other.unbilledBalanceBase, unbilledBalanceBase) || other.unbilledBalanceBase == unbilledBalanceBase)&&(identical(other.totalBalanceBase, totalBalanceBase) || other.totalBalanceBase == totalBalanceBase)&&(identical(other.statementPaymentsBase, statementPaymentsBase) || other.statementPaymentsBase == statementPaymentsBase)&&(identical(other.available, available) || other.available == available)&&(identical(other.availableBase, availableBase) || other.availableBase == availableBase)&&(identical(other.utilization, utilization) || other.utilization == utilization));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,window,statementBalance,unbilledBalance,totalBalance,statementCharges,statementPayments,statementBalanceBase,unbilledBalanceBase,totalBalanceBase,statementPaymentsBase,available,availableBase,utilization);

@override
String toString() {
  return 'CardSpendStats(window: $window, statementBalance: $statementBalance, unbilledBalance: $unbilledBalance, totalBalance: $totalBalance, statementCharges: $statementCharges, statementPayments: $statementPayments, statementBalanceBase: $statementBalanceBase, unbilledBalanceBase: $unbilledBalanceBase, totalBalanceBase: $totalBalanceBase, statementPaymentsBase: $statementPaymentsBase, available: $available, availableBase: $availableBase, utilization: $utilization)';
}


}

/// @nodoc
abstract mixin class $CardSpendStatsCopyWith<$Res>  {
  factory $CardSpendStatsCopyWith(CardSpendStats value, $Res Function(CardSpendStats) _then) = _$CardSpendStatsCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: statementWindowFromJson, toJson: statementWindowToJson) StatementWindow window, double statementBalance, double unbilledBalance, double totalBalance, double statementCharges, double statementPayments, double statementBalanceBase, double unbilledBalanceBase, double totalBalanceBase, double statementPaymentsBase, double? available, double? availableBase, double? utilization
});




}
/// @nodoc
class _$CardSpendStatsCopyWithImpl<$Res>
    implements $CardSpendStatsCopyWith<$Res> {
  _$CardSpendStatsCopyWithImpl(this._self, this._then);

  final CardSpendStats _self;
  final $Res Function(CardSpendStats) _then;

/// Create a copy of CardSpendStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? window = null,Object? statementBalance = null,Object? unbilledBalance = null,Object? totalBalance = null,Object? statementCharges = null,Object? statementPayments = null,Object? statementBalanceBase = null,Object? unbilledBalanceBase = null,Object? totalBalanceBase = null,Object? statementPaymentsBase = null,Object? available = freezed,Object? availableBase = freezed,Object? utilization = freezed,}) {
  return _then(_self.copyWith(
window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as StatementWindow,statementBalance: null == statementBalance ? _self.statementBalance : statementBalance // ignore: cast_nullable_to_non_nullable
as double,unbilledBalance: null == unbilledBalance ? _self.unbilledBalance : unbilledBalance // ignore: cast_nullable_to_non_nullable
as double,totalBalance: null == totalBalance ? _self.totalBalance : totalBalance // ignore: cast_nullable_to_non_nullable
as double,statementCharges: null == statementCharges ? _self.statementCharges : statementCharges // ignore: cast_nullable_to_non_nullable
as double,statementPayments: null == statementPayments ? _self.statementPayments : statementPayments // ignore: cast_nullable_to_non_nullable
as double,statementBalanceBase: null == statementBalanceBase ? _self.statementBalanceBase : statementBalanceBase // ignore: cast_nullable_to_non_nullable
as double,unbilledBalanceBase: null == unbilledBalanceBase ? _self.unbilledBalanceBase : unbilledBalanceBase // ignore: cast_nullable_to_non_nullable
as double,totalBalanceBase: null == totalBalanceBase ? _self.totalBalanceBase : totalBalanceBase // ignore: cast_nullable_to_non_nullable
as double,statementPaymentsBase: null == statementPaymentsBase ? _self.statementPaymentsBase : statementPaymentsBase // ignore: cast_nullable_to_non_nullable
as double,available: freezed == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as double?,availableBase: freezed == availableBase ? _self.availableBase : availableBase // ignore: cast_nullable_to_non_nullable
as double?,utilization: freezed == utilization ? _self.utilization : utilization // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [CardSpendStats].
extension CardSpendStatsPatterns on CardSpendStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardSpendStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardSpendStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardSpendStats value)  $default,){
final _that = this;
switch (_that) {
case _CardSpendStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardSpendStats value)?  $default,){
final _that = this;
switch (_that) {
case _CardSpendStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: statementWindowFromJson, toJson: statementWindowToJson)  StatementWindow window,  double statementBalance,  double unbilledBalance,  double totalBalance,  double statementCharges,  double statementPayments,  double statementBalanceBase,  double unbilledBalanceBase,  double totalBalanceBase,  double statementPaymentsBase,  double? available,  double? availableBase,  double? utilization)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardSpendStats() when $default != null:
return $default(_that.window,_that.statementBalance,_that.unbilledBalance,_that.totalBalance,_that.statementCharges,_that.statementPayments,_that.statementBalanceBase,_that.unbilledBalanceBase,_that.totalBalanceBase,_that.statementPaymentsBase,_that.available,_that.availableBase,_that.utilization);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: statementWindowFromJson, toJson: statementWindowToJson)  StatementWindow window,  double statementBalance,  double unbilledBalance,  double totalBalance,  double statementCharges,  double statementPayments,  double statementBalanceBase,  double unbilledBalanceBase,  double totalBalanceBase,  double statementPaymentsBase,  double? available,  double? availableBase,  double? utilization)  $default,) {final _that = this;
switch (_that) {
case _CardSpendStats():
return $default(_that.window,_that.statementBalance,_that.unbilledBalance,_that.totalBalance,_that.statementCharges,_that.statementPayments,_that.statementBalanceBase,_that.unbilledBalanceBase,_that.totalBalanceBase,_that.statementPaymentsBase,_that.available,_that.availableBase,_that.utilization);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: statementWindowFromJson, toJson: statementWindowToJson)  StatementWindow window,  double statementBalance,  double unbilledBalance,  double totalBalance,  double statementCharges,  double statementPayments,  double statementBalanceBase,  double unbilledBalanceBase,  double totalBalanceBase,  double statementPaymentsBase,  double? available,  double? availableBase,  double? utilization)?  $default,) {final _that = this;
switch (_that) {
case _CardSpendStats() when $default != null:
return $default(_that.window,_that.statementBalance,_that.unbilledBalance,_that.totalBalance,_that.statementCharges,_that.statementPayments,_that.statementBalanceBase,_that.unbilledBalanceBase,_that.totalBalanceBase,_that.statementPaymentsBase,_that.available,_that.availableBase,_that.utilization);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _CardSpendStats extends CardSpendStats {
   _CardSpendStats({@JsonKey(fromJson: statementWindowFromJson, toJson: statementWindowToJson) required this.window, required this.statementBalance, required this.unbilledBalance, required this.totalBalance, required this.statementCharges, required this.statementPayments, required this.statementBalanceBase, required this.unbilledBalanceBase, required this.totalBalanceBase, required this.statementPaymentsBase, this.available, this.availableBase, this.utilization}): super._();
  factory _CardSpendStats.fromJson(Map<String, dynamic> json) => _$CardSpendStatsFromJson(json);

@override@JsonKey(fromJson: statementWindowFromJson, toJson: statementWindowToJson) final  StatementWindow window;
@override final  double statementBalance;
@override final  double unbilledBalance;
@override final  double totalBalance;
@override final  double statementCharges;
@override final  double statementPayments;
@override final  double statementBalanceBase;
@override final  double unbilledBalanceBase;
@override final  double totalBalanceBase;
@override final  double statementPaymentsBase;
@override final  double? available;
@override final  double? availableBase;
@override final  double? utilization;

/// Create a copy of CardSpendStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardSpendStatsCopyWith<_CardSpendStats> get copyWith => __$CardSpendStatsCopyWithImpl<_CardSpendStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CardSpendStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardSpendStats&&(identical(other.window, window) || other.window == window)&&(identical(other.statementBalance, statementBalance) || other.statementBalance == statementBalance)&&(identical(other.unbilledBalance, unbilledBalance) || other.unbilledBalance == unbilledBalance)&&(identical(other.totalBalance, totalBalance) || other.totalBalance == totalBalance)&&(identical(other.statementCharges, statementCharges) || other.statementCharges == statementCharges)&&(identical(other.statementPayments, statementPayments) || other.statementPayments == statementPayments)&&(identical(other.statementBalanceBase, statementBalanceBase) || other.statementBalanceBase == statementBalanceBase)&&(identical(other.unbilledBalanceBase, unbilledBalanceBase) || other.unbilledBalanceBase == unbilledBalanceBase)&&(identical(other.totalBalanceBase, totalBalanceBase) || other.totalBalanceBase == totalBalanceBase)&&(identical(other.statementPaymentsBase, statementPaymentsBase) || other.statementPaymentsBase == statementPaymentsBase)&&(identical(other.available, available) || other.available == available)&&(identical(other.availableBase, availableBase) || other.availableBase == availableBase)&&(identical(other.utilization, utilization) || other.utilization == utilization));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,window,statementBalance,unbilledBalance,totalBalance,statementCharges,statementPayments,statementBalanceBase,unbilledBalanceBase,totalBalanceBase,statementPaymentsBase,available,availableBase,utilization);

@override
String toString() {
  return 'CardSpendStats(window: $window, statementBalance: $statementBalance, unbilledBalance: $unbilledBalance, totalBalance: $totalBalance, statementCharges: $statementCharges, statementPayments: $statementPayments, statementBalanceBase: $statementBalanceBase, unbilledBalanceBase: $unbilledBalanceBase, totalBalanceBase: $totalBalanceBase, statementPaymentsBase: $statementPaymentsBase, available: $available, availableBase: $availableBase, utilization: $utilization)';
}


}

/// @nodoc
abstract mixin class _$CardSpendStatsCopyWith<$Res> implements $CardSpendStatsCopyWith<$Res> {
  factory _$CardSpendStatsCopyWith(_CardSpendStats value, $Res Function(_CardSpendStats) _then) = __$CardSpendStatsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: statementWindowFromJson, toJson: statementWindowToJson) StatementWindow window, double statementBalance, double unbilledBalance, double totalBalance, double statementCharges, double statementPayments, double statementBalanceBase, double unbilledBalanceBase, double totalBalanceBase, double statementPaymentsBase, double? available, double? availableBase, double? utilization
});




}
/// @nodoc
class __$CardSpendStatsCopyWithImpl<$Res>
    implements _$CardSpendStatsCopyWith<$Res> {
  __$CardSpendStatsCopyWithImpl(this._self, this._then);

  final _CardSpendStats _self;
  final $Res Function(_CardSpendStats) _then;

/// Create a copy of CardSpendStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? window = null,Object? statementBalance = null,Object? unbilledBalance = null,Object? totalBalance = null,Object? statementCharges = null,Object? statementPayments = null,Object? statementBalanceBase = null,Object? unbilledBalanceBase = null,Object? totalBalanceBase = null,Object? statementPaymentsBase = null,Object? available = freezed,Object? availableBase = freezed,Object? utilization = freezed,}) {
  return _then(_CardSpendStats(
window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as StatementWindow,statementBalance: null == statementBalance ? _self.statementBalance : statementBalance // ignore: cast_nullable_to_non_nullable
as double,unbilledBalance: null == unbilledBalance ? _self.unbilledBalance : unbilledBalance // ignore: cast_nullable_to_non_nullable
as double,totalBalance: null == totalBalance ? _self.totalBalance : totalBalance // ignore: cast_nullable_to_non_nullable
as double,statementCharges: null == statementCharges ? _self.statementCharges : statementCharges // ignore: cast_nullable_to_non_nullable
as double,statementPayments: null == statementPayments ? _self.statementPayments : statementPayments // ignore: cast_nullable_to_non_nullable
as double,statementBalanceBase: null == statementBalanceBase ? _self.statementBalanceBase : statementBalanceBase // ignore: cast_nullable_to_non_nullable
as double,unbilledBalanceBase: null == unbilledBalanceBase ? _self.unbilledBalanceBase : unbilledBalanceBase // ignore: cast_nullable_to_non_nullable
as double,totalBalanceBase: null == totalBalanceBase ? _self.totalBalanceBase : totalBalanceBase // ignore: cast_nullable_to_non_nullable
as double,statementPaymentsBase: null == statementPaymentsBase ? _self.statementPaymentsBase : statementPaymentsBase // ignore: cast_nullable_to_non_nullable
as double,available: freezed == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as double?,availableBase: freezed == availableBase ? _self.availableBase : availableBase // ignore: cast_nullable_to_non_nullable
as double?,utilization: freezed == utilization ? _self.utilization : utilization // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
