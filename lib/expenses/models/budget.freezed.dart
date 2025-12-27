// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Budget {

 String get id; double get amount;@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime get startDate;@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime get endDate; String get currency; List<PlannedExpense> get plannedExpenses;
/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BudgetCopyWith<Budget> get copyWith => _$BudgetCopyWithImpl<Budget>(this as Budget, _$identity);

  /// Serializes this Budget to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Budget&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.currency, currency) || other.currency == currency)&&const DeepCollectionEquality().equals(other.plannedExpenses, plannedExpenses));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,amount,startDate,endDate,currency,const DeepCollectionEquality().hash(plannedExpenses));

@override
String toString() {
  return 'Budget(id: $id, amount: $amount, startDate: $startDate, endDate: $endDate, currency: $currency, plannedExpenses: $plannedExpenses)';
}


}

/// @nodoc
abstract mixin class $BudgetCopyWith<$Res>  {
  factory $BudgetCopyWith(Budget value, $Res Function(Budget) _then) = _$BudgetCopyWithImpl;
@useResult
$Res call({
 String id, double amount,@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime startDate,@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime endDate, String currency, List<PlannedExpense> plannedExpenses
});




}
/// @nodoc
class _$BudgetCopyWithImpl<$Res>
    implements $BudgetCopyWith<$Res> {
  _$BudgetCopyWithImpl(this._self, this._then);

  final Budget _self;
  final $Res Function(Budget) _then;

/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? amount = null,Object? startDate = null,Object? endDate = null,Object? currency = null,Object? plannedExpenses = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,plannedExpenses: null == plannedExpenses ? _self.plannedExpenses : plannedExpenses // ignore: cast_nullable_to_non_nullable
as List<PlannedExpense>,
  ));
}

}


/// Adds pattern-matching-related methods to [Budget].
extension BudgetPatterns on Budget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Budget value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Budget() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Budget value)  $default,){
final _that = this;
switch (_that) {
case _Budget():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Budget value)?  $default,){
final _that = this;
switch (_that) {
case _Budget() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  double amount, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime startDate, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime endDate,  String currency,  List<PlannedExpense> plannedExpenses)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Budget() when $default != null:
return $default(_that.id,_that.amount,_that.startDate,_that.endDate,_that.currency,_that.plannedExpenses);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  double amount, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime startDate, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime endDate,  String currency,  List<PlannedExpense> plannedExpenses)  $default,) {final _that = this;
switch (_that) {
case _Budget():
return $default(_that.id,_that.amount,_that.startDate,_that.endDate,_that.currency,_that.plannedExpenses);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  double amount, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime startDate, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime endDate,  String currency,  List<PlannedExpense> plannedExpenses)?  $default,) {final _that = this;
switch (_that) {
case _Budget() when $default != null:
return $default(_that.id,_that.amount,_that.startDate,_that.endDate,_that.currency,_that.plannedExpenses);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _Budget extends Budget {
   _Budget({required this.id, required this.amount, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) required this.startDate, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) required this.endDate, this.currency = AppConfig.baseCurrency, final  List<PlannedExpense> plannedExpenses = const <PlannedExpense>[]}): _plannedExpenses = plannedExpenses,super._();
  factory _Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);

@override final  String id;
@override final  double amount;
@override@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) final  DateTime startDate;
@override@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) final  DateTime endDate;
@override@JsonKey() final  String currency;
 final  List<PlannedExpense> _plannedExpenses;
@override@JsonKey() List<PlannedExpense> get plannedExpenses {
  if (_plannedExpenses is EqualUnmodifiableListView) return _plannedExpenses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_plannedExpenses);
}


/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BudgetCopyWith<_Budget> get copyWith => __$BudgetCopyWithImpl<_Budget>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BudgetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Budget&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.currency, currency) || other.currency == currency)&&const DeepCollectionEquality().equals(other._plannedExpenses, _plannedExpenses));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,amount,startDate,endDate,currency,const DeepCollectionEquality().hash(_plannedExpenses));

@override
String toString() {
  return 'Budget(id: $id, amount: $amount, startDate: $startDate, endDate: $endDate, currency: $currency, plannedExpenses: $plannedExpenses)';
}


}

/// @nodoc
abstract mixin class _$BudgetCopyWith<$Res> implements $BudgetCopyWith<$Res> {
  factory _$BudgetCopyWith(_Budget value, $Res Function(_Budget) _then) = __$BudgetCopyWithImpl;
@override @useResult
$Res call({
 String id, double amount,@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime startDate,@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime endDate, String currency, List<PlannedExpense> plannedExpenses
});




}
/// @nodoc
class __$BudgetCopyWithImpl<$Res>
    implements _$BudgetCopyWith<$Res> {
  __$BudgetCopyWithImpl(this._self, this._then);

  final _Budget _self;
  final $Res Function(_Budget) _then;

/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? amount = null,Object? startDate = null,Object? endDate = null,Object? currency = null,Object? plannedExpenses = null,}) {
  return _then(_Budget(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,plannedExpenses: null == plannedExpenses ? _self._plannedExpenses : plannedExpenses // ignore: cast_nullable_to_non_nullable
as List<PlannedExpense>,
  ));
}


}

// dart format on
