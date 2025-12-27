// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'credit_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreditCard {

 String get id;@JsonKey(readValue: _readBankName) String get bankName;@JsonKey(readValue: _readBankIconUrl) String? get bankIconUrl;@JsonKey(readValue: _readCardNetwork) String? get cardNetwork;@JsonKey(readValue: _readCardNumber) String get cardNumber;@JsonKey(readValue: _readHolderName) String get holderName;@JsonKey(readValue: _readExpiryDate) String get expiryDate;@JsonKey(readValue: _readCvv) String get cvv;@JsonKey(fromJson: cardColorFromJson, toJson: colorToJson) Color get cardColor;@JsonKey(fromJson: textColorFromJson, toJson: colorToJson) Color get textColor;@JsonKey(readValue: _readCreatedAt, fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? get createdAt;@JsonKey(readValue: _readUpdatedAt, fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? get updatedAt;@JsonKey(readValue: _readBillingDay) int get billingDay;@JsonKey(readValue: _readGraceDays) int get graceDays;@JsonKey(readValue: _readUsageLimit) double? get usageLimit;@JsonKey(readValue: _readCurrency) String get currency;@JsonKey(readValue: _readAutopayEnabled, fromJson: _boolFromJson) bool get autopayEnabled;@JsonKey(readValue: _readReminderEnabled, fromJson: _boolFromJson) bool get reminderEnabled;@JsonKey(readValue: _readReminderOffsets, fromJson: intListFromJson, toJson: intListToJson) List<int> get reminderOffsets;
/// Create a copy of CreditCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreditCardCopyWith<CreditCard> get copyWith => _$CreditCardCopyWithImpl<CreditCard>(this as CreditCard, _$identity);

  /// Serializes this CreditCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreditCard&&(identical(other.id, id) || other.id == id)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.bankIconUrl, bankIconUrl) || other.bankIconUrl == bankIconUrl)&&(identical(other.cardNetwork, cardNetwork) || other.cardNetwork == cardNetwork)&&(identical(other.cardNumber, cardNumber) || other.cardNumber == cardNumber)&&(identical(other.holderName, holderName) || other.holderName == holderName)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate)&&(identical(other.cvv, cvv) || other.cvv == cvv)&&(identical(other.cardColor, cardColor) || other.cardColor == cardColor)&&(identical(other.textColor, textColor) || other.textColor == textColor)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.billingDay, billingDay) || other.billingDay == billingDay)&&(identical(other.graceDays, graceDays) || other.graceDays == graceDays)&&(identical(other.usageLimit, usageLimit) || other.usageLimit == usageLimit)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.autopayEnabled, autopayEnabled) || other.autopayEnabled == autopayEnabled)&&(identical(other.reminderEnabled, reminderEnabled) || other.reminderEnabled == reminderEnabled)&&const DeepCollectionEquality().equals(other.reminderOffsets, reminderOffsets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,bankName,bankIconUrl,cardNetwork,cardNumber,holderName,expiryDate,cvv,cardColor,textColor,createdAt,updatedAt,billingDay,graceDays,usageLimit,currency,autopayEnabled,reminderEnabled,const DeepCollectionEquality().hash(reminderOffsets)]);

@override
String toString() {
  return 'CreditCard(id: $id, bankName: $bankName, bankIconUrl: $bankIconUrl, cardNetwork: $cardNetwork, cardNumber: $cardNumber, holderName: $holderName, expiryDate: $expiryDate, cvv: $cvv, cardColor: $cardColor, textColor: $textColor, createdAt: $createdAt, updatedAt: $updatedAt, billingDay: $billingDay, graceDays: $graceDays, usageLimit: $usageLimit, currency: $currency, autopayEnabled: $autopayEnabled, reminderEnabled: $reminderEnabled, reminderOffsets: $reminderOffsets)';
}


}

/// @nodoc
abstract mixin class $CreditCardCopyWith<$Res>  {
  factory $CreditCardCopyWith(CreditCard value, $Res Function(CreditCard) _then) = _$CreditCardCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(readValue: _readBankName) String bankName,@JsonKey(readValue: _readBankIconUrl) String? bankIconUrl,@JsonKey(readValue: _readCardNetwork) String? cardNetwork,@JsonKey(readValue: _readCardNumber) String cardNumber,@JsonKey(readValue: _readHolderName) String holderName,@JsonKey(readValue: _readExpiryDate) String expiryDate,@JsonKey(readValue: _readCvv) String cvv,@JsonKey(fromJson: cardColorFromJson, toJson: colorToJson) Color cardColor,@JsonKey(fromJson: textColorFromJson, toJson: colorToJson) Color textColor,@JsonKey(readValue: _readCreatedAt, fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? createdAt,@JsonKey(readValue: _readUpdatedAt, fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? updatedAt,@JsonKey(readValue: _readBillingDay) int billingDay,@JsonKey(readValue: _readGraceDays) int graceDays,@JsonKey(readValue: _readUsageLimit) double? usageLimit,@JsonKey(readValue: _readCurrency) String currency,@JsonKey(readValue: _readAutopayEnabled, fromJson: _boolFromJson) bool autopayEnabled,@JsonKey(readValue: _readReminderEnabled, fromJson: _boolFromJson) bool reminderEnabled,@JsonKey(readValue: _readReminderOffsets, fromJson: intListFromJson, toJson: intListToJson) List<int> reminderOffsets
});




}
/// @nodoc
class _$CreditCardCopyWithImpl<$Res>
    implements $CreditCardCopyWith<$Res> {
  _$CreditCardCopyWithImpl(this._self, this._then);

  final CreditCard _self;
  final $Res Function(CreditCard) _then;

/// Create a copy of CreditCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? bankName = null,Object? bankIconUrl = freezed,Object? cardNetwork = freezed,Object? cardNumber = null,Object? holderName = null,Object? expiryDate = null,Object? cvv = null,Object? cardColor = null,Object? textColor = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? billingDay = null,Object? graceDays = null,Object? usageLimit = freezed,Object? currency = null,Object? autopayEnabled = null,Object? reminderEnabled = null,Object? reminderOffsets = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,bankIconUrl: freezed == bankIconUrl ? _self.bankIconUrl : bankIconUrl // ignore: cast_nullable_to_non_nullable
as String?,cardNetwork: freezed == cardNetwork ? _self.cardNetwork : cardNetwork // ignore: cast_nullable_to_non_nullable
as String?,cardNumber: null == cardNumber ? _self.cardNumber : cardNumber // ignore: cast_nullable_to_non_nullable
as String,holderName: null == holderName ? _self.holderName : holderName // ignore: cast_nullable_to_non_nullable
as String,expiryDate: null == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as String,cvv: null == cvv ? _self.cvv : cvv // ignore: cast_nullable_to_non_nullable
as String,cardColor: null == cardColor ? _self.cardColor : cardColor // ignore: cast_nullable_to_non_nullable
as Color,textColor: null == textColor ? _self.textColor : textColor // ignore: cast_nullable_to_non_nullable
as Color,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,billingDay: null == billingDay ? _self.billingDay : billingDay // ignore: cast_nullable_to_non_nullable
as int,graceDays: null == graceDays ? _self.graceDays : graceDays // ignore: cast_nullable_to_non_nullable
as int,usageLimit: freezed == usageLimit ? _self.usageLimit : usageLimit // ignore: cast_nullable_to_non_nullable
as double?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,autopayEnabled: null == autopayEnabled ? _self.autopayEnabled : autopayEnabled // ignore: cast_nullable_to_non_nullable
as bool,reminderEnabled: null == reminderEnabled ? _self.reminderEnabled : reminderEnabled // ignore: cast_nullable_to_non_nullable
as bool,reminderOffsets: null == reminderOffsets ? _self.reminderOffsets : reminderOffsets // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [CreditCard].
extension CreditCardPatterns on CreditCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreditCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreditCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreditCard value)  $default,){
final _that = this;
switch (_that) {
case _CreditCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreditCard value)?  $default,){
final _that = this;
switch (_that) {
case _CreditCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(readValue: _readBankName)  String bankName, @JsonKey(readValue: _readBankIconUrl)  String? bankIconUrl, @JsonKey(readValue: _readCardNetwork)  String? cardNetwork, @JsonKey(readValue: _readCardNumber)  String cardNumber, @JsonKey(readValue: _readHolderName)  String holderName, @JsonKey(readValue: _readExpiryDate)  String expiryDate, @JsonKey(readValue: _readCvv)  String cvv, @JsonKey(fromJson: cardColorFromJson, toJson: colorToJson)  Color cardColor, @JsonKey(fromJson: textColorFromJson, toJson: colorToJson)  Color textColor, @JsonKey(readValue: _readCreatedAt, fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? createdAt, @JsonKey(readValue: _readUpdatedAt, fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? updatedAt, @JsonKey(readValue: _readBillingDay)  int billingDay, @JsonKey(readValue: _readGraceDays)  int graceDays, @JsonKey(readValue: _readUsageLimit)  double? usageLimit, @JsonKey(readValue: _readCurrency)  String currency, @JsonKey(readValue: _readAutopayEnabled, fromJson: _boolFromJson)  bool autopayEnabled, @JsonKey(readValue: _readReminderEnabled, fromJson: _boolFromJson)  bool reminderEnabled, @JsonKey(readValue: _readReminderOffsets, fromJson: intListFromJson, toJson: intListToJson)  List<int> reminderOffsets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreditCard() when $default != null:
return $default(_that.id,_that.bankName,_that.bankIconUrl,_that.cardNetwork,_that.cardNumber,_that.holderName,_that.expiryDate,_that.cvv,_that.cardColor,_that.textColor,_that.createdAt,_that.updatedAt,_that.billingDay,_that.graceDays,_that.usageLimit,_that.currency,_that.autopayEnabled,_that.reminderEnabled,_that.reminderOffsets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(readValue: _readBankName)  String bankName, @JsonKey(readValue: _readBankIconUrl)  String? bankIconUrl, @JsonKey(readValue: _readCardNetwork)  String? cardNetwork, @JsonKey(readValue: _readCardNumber)  String cardNumber, @JsonKey(readValue: _readHolderName)  String holderName, @JsonKey(readValue: _readExpiryDate)  String expiryDate, @JsonKey(readValue: _readCvv)  String cvv, @JsonKey(fromJson: cardColorFromJson, toJson: colorToJson)  Color cardColor, @JsonKey(fromJson: textColorFromJson, toJson: colorToJson)  Color textColor, @JsonKey(readValue: _readCreatedAt, fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? createdAt, @JsonKey(readValue: _readUpdatedAt, fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? updatedAt, @JsonKey(readValue: _readBillingDay)  int billingDay, @JsonKey(readValue: _readGraceDays)  int graceDays, @JsonKey(readValue: _readUsageLimit)  double? usageLimit, @JsonKey(readValue: _readCurrency)  String currency, @JsonKey(readValue: _readAutopayEnabled, fromJson: _boolFromJson)  bool autopayEnabled, @JsonKey(readValue: _readReminderEnabled, fromJson: _boolFromJson)  bool reminderEnabled, @JsonKey(readValue: _readReminderOffsets, fromJson: intListFromJson, toJson: intListToJson)  List<int> reminderOffsets)  $default,) {final _that = this;
switch (_that) {
case _CreditCard():
return $default(_that.id,_that.bankName,_that.bankIconUrl,_that.cardNetwork,_that.cardNumber,_that.holderName,_that.expiryDate,_that.cvv,_that.cardColor,_that.textColor,_that.createdAt,_that.updatedAt,_that.billingDay,_that.graceDays,_that.usageLimit,_that.currency,_that.autopayEnabled,_that.reminderEnabled,_that.reminderOffsets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(readValue: _readBankName)  String bankName, @JsonKey(readValue: _readBankIconUrl)  String? bankIconUrl, @JsonKey(readValue: _readCardNetwork)  String? cardNetwork, @JsonKey(readValue: _readCardNumber)  String cardNumber, @JsonKey(readValue: _readHolderName)  String holderName, @JsonKey(readValue: _readExpiryDate)  String expiryDate, @JsonKey(readValue: _readCvv)  String cvv, @JsonKey(fromJson: cardColorFromJson, toJson: colorToJson)  Color cardColor, @JsonKey(fromJson: textColorFromJson, toJson: colorToJson)  Color textColor, @JsonKey(readValue: _readCreatedAt, fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? createdAt, @JsonKey(readValue: _readUpdatedAt, fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? updatedAt, @JsonKey(readValue: _readBillingDay)  int billingDay, @JsonKey(readValue: _readGraceDays)  int graceDays, @JsonKey(readValue: _readUsageLimit)  double? usageLimit, @JsonKey(readValue: _readCurrency)  String currency, @JsonKey(readValue: _readAutopayEnabled, fromJson: _boolFromJson)  bool autopayEnabled, @JsonKey(readValue: _readReminderEnabled, fromJson: _boolFromJson)  bool reminderEnabled, @JsonKey(readValue: _readReminderOffsets, fromJson: intListFromJson, toJson: intListToJson)  List<int> reminderOffsets)?  $default,) {final _that = this;
switch (_that) {
case _CreditCard() when $default != null:
return $default(_that.id,_that.bankName,_that.bankIconUrl,_that.cardNetwork,_that.cardNumber,_that.holderName,_that.expiryDate,_that.cvv,_that.cardColor,_that.textColor,_that.createdAt,_that.updatedAt,_that.billingDay,_that.graceDays,_that.usageLimit,_that.currency,_that.autopayEnabled,_that.reminderEnabled,_that.reminderOffsets);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreditCard extends CreditCard {
   _CreditCard({required this.id, @JsonKey(readValue: _readBankName) required this.bankName, @JsonKey(readValue: _readBankIconUrl) this.bankIconUrl, @JsonKey(readValue: _readCardNetwork) this.cardNetwork, @JsonKey(readValue: _readCardNumber) required this.cardNumber, @JsonKey(readValue: _readHolderName) required this.holderName, @JsonKey(readValue: _readExpiryDate) required this.expiryDate, @JsonKey(readValue: _readCvv) required this.cvv, @JsonKey(fromJson: cardColorFromJson, toJson: colorToJson) required this.cardColor, @JsonKey(fromJson: textColorFromJson, toJson: colorToJson) required this.textColor, @JsonKey(readValue: _readCreatedAt, fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) this.createdAt, @JsonKey(readValue: _readUpdatedAt, fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) this.updatedAt, @JsonKey(readValue: _readBillingDay) this.billingDay = 1, @JsonKey(readValue: _readGraceDays) this.graceDays = 15, @JsonKey(readValue: _readUsageLimit) this.usageLimit, @JsonKey(readValue: _readCurrency) this.currency = AppConfig.baseCurrency, @JsonKey(readValue: _readAutopayEnabled, fromJson: _boolFromJson) this.autopayEnabled = false, @JsonKey(readValue: _readReminderEnabled, fromJson: _boolFromJson) this.reminderEnabled = false, @JsonKey(readValue: _readReminderOffsets, fromJson: intListFromJson, toJson: intListToJson) final  List<int> reminderOffsets = const <int>[]}): _reminderOffsets = reminderOffsets,super._();
  factory _CreditCard.fromJson(Map<String, dynamic> json) => _$CreditCardFromJson(json);

@override final  String id;
@override@JsonKey(readValue: _readBankName) final  String bankName;
@override@JsonKey(readValue: _readBankIconUrl) final  String? bankIconUrl;
@override@JsonKey(readValue: _readCardNetwork) final  String? cardNetwork;
@override@JsonKey(readValue: _readCardNumber) final  String cardNumber;
@override@JsonKey(readValue: _readHolderName) final  String holderName;
@override@JsonKey(readValue: _readExpiryDate) final  String expiryDate;
@override@JsonKey(readValue: _readCvv) final  String cvv;
@override@JsonKey(fromJson: cardColorFromJson, toJson: colorToJson) final  Color cardColor;
@override@JsonKey(fromJson: textColorFromJson, toJson: colorToJson) final  Color textColor;
@override@JsonKey(readValue: _readCreatedAt, fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) final  DateTime? createdAt;
@override@JsonKey(readValue: _readUpdatedAt, fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) final  DateTime? updatedAt;
@override@JsonKey(readValue: _readBillingDay) final  int billingDay;
@override@JsonKey(readValue: _readGraceDays) final  int graceDays;
@override@JsonKey(readValue: _readUsageLimit) final  double? usageLimit;
@override@JsonKey(readValue: _readCurrency) final  String currency;
@override@JsonKey(readValue: _readAutopayEnabled, fromJson: _boolFromJson) final  bool autopayEnabled;
@override@JsonKey(readValue: _readReminderEnabled, fromJson: _boolFromJson) final  bool reminderEnabled;
 final  List<int> _reminderOffsets;
@override@JsonKey(readValue: _readReminderOffsets, fromJson: intListFromJson, toJson: intListToJson) List<int> get reminderOffsets {
  if (_reminderOffsets is EqualUnmodifiableListView) return _reminderOffsets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reminderOffsets);
}


/// Create a copy of CreditCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreditCardCopyWith<_CreditCard> get copyWith => __$CreditCardCopyWithImpl<_CreditCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreditCardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreditCard&&(identical(other.id, id) || other.id == id)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.bankIconUrl, bankIconUrl) || other.bankIconUrl == bankIconUrl)&&(identical(other.cardNetwork, cardNetwork) || other.cardNetwork == cardNetwork)&&(identical(other.cardNumber, cardNumber) || other.cardNumber == cardNumber)&&(identical(other.holderName, holderName) || other.holderName == holderName)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate)&&(identical(other.cvv, cvv) || other.cvv == cvv)&&(identical(other.cardColor, cardColor) || other.cardColor == cardColor)&&(identical(other.textColor, textColor) || other.textColor == textColor)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.billingDay, billingDay) || other.billingDay == billingDay)&&(identical(other.graceDays, graceDays) || other.graceDays == graceDays)&&(identical(other.usageLimit, usageLimit) || other.usageLimit == usageLimit)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.autopayEnabled, autopayEnabled) || other.autopayEnabled == autopayEnabled)&&(identical(other.reminderEnabled, reminderEnabled) || other.reminderEnabled == reminderEnabled)&&const DeepCollectionEquality().equals(other._reminderOffsets, _reminderOffsets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,bankName,bankIconUrl,cardNetwork,cardNumber,holderName,expiryDate,cvv,cardColor,textColor,createdAt,updatedAt,billingDay,graceDays,usageLimit,currency,autopayEnabled,reminderEnabled,const DeepCollectionEquality().hash(_reminderOffsets)]);

@override
String toString() {
  return 'CreditCard(id: $id, bankName: $bankName, bankIconUrl: $bankIconUrl, cardNetwork: $cardNetwork, cardNumber: $cardNumber, holderName: $holderName, expiryDate: $expiryDate, cvv: $cvv, cardColor: $cardColor, textColor: $textColor, createdAt: $createdAt, updatedAt: $updatedAt, billingDay: $billingDay, graceDays: $graceDays, usageLimit: $usageLimit, currency: $currency, autopayEnabled: $autopayEnabled, reminderEnabled: $reminderEnabled, reminderOffsets: $reminderOffsets)';
}


}

/// @nodoc
abstract mixin class _$CreditCardCopyWith<$Res> implements $CreditCardCopyWith<$Res> {
  factory _$CreditCardCopyWith(_CreditCard value, $Res Function(_CreditCard) _then) = __$CreditCardCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(readValue: _readBankName) String bankName,@JsonKey(readValue: _readBankIconUrl) String? bankIconUrl,@JsonKey(readValue: _readCardNetwork) String? cardNetwork,@JsonKey(readValue: _readCardNumber) String cardNumber,@JsonKey(readValue: _readHolderName) String holderName,@JsonKey(readValue: _readExpiryDate) String expiryDate,@JsonKey(readValue: _readCvv) String cvv,@JsonKey(fromJson: cardColorFromJson, toJson: colorToJson) Color cardColor,@JsonKey(fromJson: textColorFromJson, toJson: colorToJson) Color textColor,@JsonKey(readValue: _readCreatedAt, fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? createdAt,@JsonKey(readValue: _readUpdatedAt, fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? updatedAt,@JsonKey(readValue: _readBillingDay) int billingDay,@JsonKey(readValue: _readGraceDays) int graceDays,@JsonKey(readValue: _readUsageLimit) double? usageLimit,@JsonKey(readValue: _readCurrency) String currency,@JsonKey(readValue: _readAutopayEnabled, fromJson: _boolFromJson) bool autopayEnabled,@JsonKey(readValue: _readReminderEnabled, fromJson: _boolFromJson) bool reminderEnabled,@JsonKey(readValue: _readReminderOffsets, fromJson: intListFromJson, toJson: intListToJson) List<int> reminderOffsets
});




}
/// @nodoc
class __$CreditCardCopyWithImpl<$Res>
    implements _$CreditCardCopyWith<$Res> {
  __$CreditCardCopyWithImpl(this._self, this._then);

  final _CreditCard _self;
  final $Res Function(_CreditCard) _then;

/// Create a copy of CreditCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? bankName = null,Object? bankIconUrl = freezed,Object? cardNetwork = freezed,Object? cardNumber = null,Object? holderName = null,Object? expiryDate = null,Object? cvv = null,Object? cardColor = null,Object? textColor = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? billingDay = null,Object? graceDays = null,Object? usageLimit = freezed,Object? currency = null,Object? autopayEnabled = null,Object? reminderEnabled = null,Object? reminderOffsets = null,}) {
  return _then(_CreditCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,bankIconUrl: freezed == bankIconUrl ? _self.bankIconUrl : bankIconUrl // ignore: cast_nullable_to_non_nullable
as String?,cardNetwork: freezed == cardNetwork ? _self.cardNetwork : cardNetwork // ignore: cast_nullable_to_non_nullable
as String?,cardNumber: null == cardNumber ? _self.cardNumber : cardNumber // ignore: cast_nullable_to_non_nullable
as String,holderName: null == holderName ? _self.holderName : holderName // ignore: cast_nullable_to_non_nullable
as String,expiryDate: null == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as String,cvv: null == cvv ? _self.cvv : cvv // ignore: cast_nullable_to_non_nullable
as String,cardColor: null == cardColor ? _self.cardColor : cardColor // ignore: cast_nullable_to_non_nullable
as Color,textColor: null == textColor ? _self.textColor : textColor // ignore: cast_nullable_to_non_nullable
as Color,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,billingDay: null == billingDay ? _self.billingDay : billingDay // ignore: cast_nullable_to_non_nullable
as int,graceDays: null == graceDays ? _self.graceDays : graceDays // ignore: cast_nullable_to_non_nullable
as int,usageLimit: freezed == usageLimit ? _self.usageLimit : usageLimit // ignore: cast_nullable_to_non_nullable
as double?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,autopayEnabled: null == autopayEnabled ? _self.autopayEnabled : autopayEnabled // ignore: cast_nullable_to_non_nullable
as bool,reminderEnabled: null == reminderEnabled ? _self.reminderEnabled : reminderEnabled // ignore: cast_nullable_to_non_nullable
as bool,reminderOffsets: null == reminderOffsets ? _self._reminderOffsets : reminderOffsets // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

// dart format on
