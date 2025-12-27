// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expense.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Expense {

 String get id; String get title; double get amount; String get currency; String get category;@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime get date; String? get note; double? get amountEur; String? get baseCurrency; double? get baseRate; double? get amountInBaseCurrency; String? get budgetCurrency; double? get budgetRate; double? get amountInBudgetCurrency;@JsonKey(fromJson: _paymentSourceFromJson) String get paymentSourceType; String? get paymentSourceId; String get transactionType;
/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseCopyWith<Expense> get copyWith => _$ExpenseCopyWithImpl<Expense>(this as Expense, _$identity);

  /// Serializes this Expense to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Expense&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.category, category) || other.category == category)&&(identical(other.date, date) || other.date == date)&&(identical(other.note, note) || other.note == note)&&(identical(other.amountEur, amountEur) || other.amountEur == amountEur)&&(identical(other.baseCurrency, baseCurrency) || other.baseCurrency == baseCurrency)&&(identical(other.baseRate, baseRate) || other.baseRate == baseRate)&&(identical(other.amountInBaseCurrency, amountInBaseCurrency) || other.amountInBaseCurrency == amountInBaseCurrency)&&(identical(other.budgetCurrency, budgetCurrency) || other.budgetCurrency == budgetCurrency)&&(identical(other.budgetRate, budgetRate) || other.budgetRate == budgetRate)&&(identical(other.amountInBudgetCurrency, amountInBudgetCurrency) || other.amountInBudgetCurrency == amountInBudgetCurrency)&&(identical(other.paymentSourceType, paymentSourceType) || other.paymentSourceType == paymentSourceType)&&(identical(other.paymentSourceId, paymentSourceId) || other.paymentSourceId == paymentSourceId)&&(identical(other.transactionType, transactionType) || other.transactionType == transactionType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,amount,currency,category,date,note,amountEur,baseCurrency,baseRate,amountInBaseCurrency,budgetCurrency,budgetRate,amountInBudgetCurrency,paymentSourceType,paymentSourceId,transactionType);

@override
String toString() {
  return 'Expense(id: $id, title: $title, amount: $amount, currency: $currency, category: $category, date: $date, note: $note, amountEur: $amountEur, baseCurrency: $baseCurrency, baseRate: $baseRate, amountInBaseCurrency: $amountInBaseCurrency, budgetCurrency: $budgetCurrency, budgetRate: $budgetRate, amountInBudgetCurrency: $amountInBudgetCurrency, paymentSourceType: $paymentSourceType, paymentSourceId: $paymentSourceId, transactionType: $transactionType)';
}


}

/// @nodoc
abstract mixin class $ExpenseCopyWith<$Res>  {
  factory $ExpenseCopyWith(Expense value, $Res Function(Expense) _then) = _$ExpenseCopyWithImpl;
@useResult
$Res call({
 String id, String title, double amount, String currency, String category,@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime date, String? note, double? amountEur, String? baseCurrency, double? baseRate, double? amountInBaseCurrency, String? budgetCurrency, double? budgetRate, double? amountInBudgetCurrency,@JsonKey(fromJson: _paymentSourceFromJson) String paymentSourceType, String? paymentSourceId, String transactionType
});




}
/// @nodoc
class _$ExpenseCopyWithImpl<$Res>
    implements $ExpenseCopyWith<$Res> {
  _$ExpenseCopyWithImpl(this._self, this._then);

  final Expense _self;
  final $Res Function(Expense) _then;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? amount = null,Object? currency = null,Object? category = null,Object? date = null,Object? note = freezed,Object? amountEur = freezed,Object? baseCurrency = freezed,Object? baseRate = freezed,Object? amountInBaseCurrency = freezed,Object? budgetCurrency = freezed,Object? budgetRate = freezed,Object? amountInBudgetCurrency = freezed,Object? paymentSourceType = null,Object? paymentSourceId = freezed,Object? transactionType = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,amountEur: freezed == amountEur ? _self.amountEur : amountEur // ignore: cast_nullable_to_non_nullable
as double?,baseCurrency: freezed == baseCurrency ? _self.baseCurrency : baseCurrency // ignore: cast_nullable_to_non_nullable
as String?,baseRate: freezed == baseRate ? _self.baseRate : baseRate // ignore: cast_nullable_to_non_nullable
as double?,amountInBaseCurrency: freezed == amountInBaseCurrency ? _self.amountInBaseCurrency : amountInBaseCurrency // ignore: cast_nullable_to_non_nullable
as double?,budgetCurrency: freezed == budgetCurrency ? _self.budgetCurrency : budgetCurrency // ignore: cast_nullable_to_non_nullable
as String?,budgetRate: freezed == budgetRate ? _self.budgetRate : budgetRate // ignore: cast_nullable_to_non_nullable
as double?,amountInBudgetCurrency: freezed == amountInBudgetCurrency ? _self.amountInBudgetCurrency : amountInBudgetCurrency // ignore: cast_nullable_to_non_nullable
as double?,paymentSourceType: null == paymentSourceType ? _self.paymentSourceType : paymentSourceType // ignore: cast_nullable_to_non_nullable
as String,paymentSourceId: freezed == paymentSourceId ? _self.paymentSourceId : paymentSourceId // ignore: cast_nullable_to_non_nullable
as String?,transactionType: null == transactionType ? _self.transactionType : transactionType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Expense].
extension ExpensePatterns on Expense {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Expense value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Expense() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Expense value)  $default,){
final _that = this;
switch (_that) {
case _Expense():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Expense value)?  $default,){
final _that = this;
switch (_that) {
case _Expense() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  double amount,  String currency,  String category, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime date,  String? note,  double? amountEur,  String? baseCurrency,  double? baseRate,  double? amountInBaseCurrency,  String? budgetCurrency,  double? budgetRate,  double? amountInBudgetCurrency, @JsonKey(fromJson: _paymentSourceFromJson)  String paymentSourceType,  String? paymentSourceId,  String transactionType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Expense() when $default != null:
return $default(_that.id,_that.title,_that.amount,_that.currency,_that.category,_that.date,_that.note,_that.amountEur,_that.baseCurrency,_that.baseRate,_that.amountInBaseCurrency,_that.budgetCurrency,_that.budgetRate,_that.amountInBudgetCurrency,_that.paymentSourceType,_that.paymentSourceId,_that.transactionType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  double amount,  String currency,  String category, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime date,  String? note,  double? amountEur,  String? baseCurrency,  double? baseRate,  double? amountInBaseCurrency,  String? budgetCurrency,  double? budgetRate,  double? amountInBudgetCurrency, @JsonKey(fromJson: _paymentSourceFromJson)  String paymentSourceType,  String? paymentSourceId,  String transactionType)  $default,) {final _that = this;
switch (_that) {
case _Expense():
return $default(_that.id,_that.title,_that.amount,_that.currency,_that.category,_that.date,_that.note,_that.amountEur,_that.baseCurrency,_that.baseRate,_that.amountInBaseCurrency,_that.budgetCurrency,_that.budgetRate,_that.amountInBudgetCurrency,_that.paymentSourceType,_that.paymentSourceId,_that.transactionType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  double amount,  String currency,  String category, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime date,  String? note,  double? amountEur,  String? baseCurrency,  double? baseRate,  double? amountInBaseCurrency,  String? budgetCurrency,  double? budgetRate,  double? amountInBudgetCurrency, @JsonKey(fromJson: _paymentSourceFromJson)  String paymentSourceType,  String? paymentSourceId,  String transactionType)?  $default,) {final _that = this;
switch (_that) {
case _Expense() when $default != null:
return $default(_that.id,_that.title,_that.amount,_that.currency,_that.category,_that.date,_that.note,_that.amountEur,_that.baseCurrency,_that.baseRate,_that.amountInBaseCurrency,_that.budgetCurrency,_that.budgetRate,_that.amountInBudgetCurrency,_that.paymentSourceType,_that.paymentSourceId,_that.transactionType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Expense extends Expense {
   _Expense({required this.id, required this.title, required this.amount, required this.currency, required this.category, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) required this.date, this.note, this.amountEur, this.baseCurrency, this.baseRate, this.amountInBaseCurrency, this.budgetCurrency, this.budgetRate, this.amountInBudgetCurrency, @JsonKey(fromJson: _paymentSourceFromJson) this.paymentSourceType = 'cash', this.paymentSourceId, this.transactionType = 'spend'}): super._();
  factory _Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);

@override final  String id;
@override final  String title;
@override final  double amount;
@override final  String currency;
@override final  String category;
@override@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) final  DateTime date;
@override final  String? note;
@override final  double? amountEur;
@override final  String? baseCurrency;
@override final  double? baseRate;
@override final  double? amountInBaseCurrency;
@override final  String? budgetCurrency;
@override final  double? budgetRate;
@override final  double? amountInBudgetCurrency;
@override@JsonKey(fromJson: _paymentSourceFromJson) final  String paymentSourceType;
@override final  String? paymentSourceId;
@override@JsonKey() final  String transactionType;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseCopyWith<_Expense> get copyWith => __$ExpenseCopyWithImpl<_Expense>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExpenseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Expense&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.category, category) || other.category == category)&&(identical(other.date, date) || other.date == date)&&(identical(other.note, note) || other.note == note)&&(identical(other.amountEur, amountEur) || other.amountEur == amountEur)&&(identical(other.baseCurrency, baseCurrency) || other.baseCurrency == baseCurrency)&&(identical(other.baseRate, baseRate) || other.baseRate == baseRate)&&(identical(other.amountInBaseCurrency, amountInBaseCurrency) || other.amountInBaseCurrency == amountInBaseCurrency)&&(identical(other.budgetCurrency, budgetCurrency) || other.budgetCurrency == budgetCurrency)&&(identical(other.budgetRate, budgetRate) || other.budgetRate == budgetRate)&&(identical(other.amountInBudgetCurrency, amountInBudgetCurrency) || other.amountInBudgetCurrency == amountInBudgetCurrency)&&(identical(other.paymentSourceType, paymentSourceType) || other.paymentSourceType == paymentSourceType)&&(identical(other.paymentSourceId, paymentSourceId) || other.paymentSourceId == paymentSourceId)&&(identical(other.transactionType, transactionType) || other.transactionType == transactionType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,amount,currency,category,date,note,amountEur,baseCurrency,baseRate,amountInBaseCurrency,budgetCurrency,budgetRate,amountInBudgetCurrency,paymentSourceType,paymentSourceId,transactionType);

@override
String toString() {
  return 'Expense(id: $id, title: $title, amount: $amount, currency: $currency, category: $category, date: $date, note: $note, amountEur: $amountEur, baseCurrency: $baseCurrency, baseRate: $baseRate, amountInBaseCurrency: $amountInBaseCurrency, budgetCurrency: $budgetCurrency, budgetRate: $budgetRate, amountInBudgetCurrency: $amountInBudgetCurrency, paymentSourceType: $paymentSourceType, paymentSourceId: $paymentSourceId, transactionType: $transactionType)';
}


}

/// @nodoc
abstract mixin class _$ExpenseCopyWith<$Res> implements $ExpenseCopyWith<$Res> {
  factory _$ExpenseCopyWith(_Expense value, $Res Function(_Expense) _then) = __$ExpenseCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, double amount, String currency, String category,@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime date, String? note, double? amountEur, String? baseCurrency, double? baseRate, double? amountInBaseCurrency, String? budgetCurrency, double? budgetRate, double? amountInBudgetCurrency,@JsonKey(fromJson: _paymentSourceFromJson) String paymentSourceType, String? paymentSourceId, String transactionType
});




}
/// @nodoc
class __$ExpenseCopyWithImpl<$Res>
    implements _$ExpenseCopyWith<$Res> {
  __$ExpenseCopyWithImpl(this._self, this._then);

  final _Expense _self;
  final $Res Function(_Expense) _then;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? amount = null,Object? currency = null,Object? category = null,Object? date = null,Object? note = freezed,Object? amountEur = freezed,Object? baseCurrency = freezed,Object? baseRate = freezed,Object? amountInBaseCurrency = freezed,Object? budgetCurrency = freezed,Object? budgetRate = freezed,Object? amountInBudgetCurrency = freezed,Object? paymentSourceType = null,Object? paymentSourceId = freezed,Object? transactionType = null,}) {
  return _then(_Expense(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,amountEur: freezed == amountEur ? _self.amountEur : amountEur // ignore: cast_nullable_to_non_nullable
as double?,baseCurrency: freezed == baseCurrency ? _self.baseCurrency : baseCurrency // ignore: cast_nullable_to_non_nullable
as String?,baseRate: freezed == baseRate ? _self.baseRate : baseRate // ignore: cast_nullable_to_non_nullable
as double?,amountInBaseCurrency: freezed == amountInBaseCurrency ? _self.amountInBaseCurrency : amountInBaseCurrency // ignore: cast_nullable_to_non_nullable
as double?,budgetCurrency: freezed == budgetCurrency ? _self.budgetCurrency : budgetCurrency // ignore: cast_nullable_to_non_nullable
as String?,budgetRate: freezed == budgetRate ? _self.budgetRate : budgetRate // ignore: cast_nullable_to_non_nullable
as double?,amountInBudgetCurrency: freezed == amountInBudgetCurrency ? _self.amountInBudgetCurrency : amountInBudgetCurrency // ignore: cast_nullable_to_non_nullable
as double?,paymentSourceType: null == paymentSourceType ? _self.paymentSourceType : paymentSourceType // ignore: cast_nullable_to_non_nullable
as String,paymentSourceId: freezed == paymentSourceId ? _self.paymentSourceId : paymentSourceId // ignore: cast_nullable_to_non_nullable
as String?,transactionType: null == transactionType ? _self.transactionType : transactionType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
