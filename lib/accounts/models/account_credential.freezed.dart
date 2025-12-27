// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_credential.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AccountCredential {

 String get id;@JsonKey(readValue: _readBankName) String get bankName;@JsonKey(readValue: _readBankIconUrl) String? get bankIconUrl;@JsonKey(readValue: _readUsername) String get username;@JsonKey(readValue: _readPassword) String get password;@JsonKey(readValue: _readWebsite) String? get website;@JsonKey(readValue: _readLastUpdated, fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime get lastUpdated;@JsonKey(fromJson: nullableColorFromJson, toJson: nullableColorToJson) Color? get brandColor;@JsonKey(readValue: _readCurrency) String get currency; double get balance;
/// Create a copy of AccountCredential
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountCredentialCopyWith<AccountCredential> get copyWith => _$AccountCredentialCopyWithImpl<AccountCredential>(this as AccountCredential, _$identity);

  /// Serializes this AccountCredential to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountCredential&&(identical(other.id, id) || other.id == id)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.bankIconUrl, bankIconUrl) || other.bankIconUrl == bankIconUrl)&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password)&&(identical(other.website, website) || other.website == website)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated)&&(identical(other.brandColor, brandColor) || other.brandColor == brandColor)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.balance, balance) || other.balance == balance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bankName,bankIconUrl,username,password,website,lastUpdated,brandColor,currency,balance);

@override
String toString() {
  return 'AccountCredential(id: $id, bankName: $bankName, bankIconUrl: $bankIconUrl, username: $username, password: $password, website: $website, lastUpdated: $lastUpdated, brandColor: $brandColor, currency: $currency, balance: $balance)';
}


}

/// @nodoc
abstract mixin class $AccountCredentialCopyWith<$Res>  {
  factory $AccountCredentialCopyWith(AccountCredential value, $Res Function(AccountCredential) _then) = _$AccountCredentialCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(readValue: _readBankName) String bankName,@JsonKey(readValue: _readBankIconUrl) String? bankIconUrl,@JsonKey(readValue: _readUsername) String username,@JsonKey(readValue: _readPassword) String password,@JsonKey(readValue: _readWebsite) String? website,@JsonKey(readValue: _readLastUpdated, fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime lastUpdated,@JsonKey(fromJson: nullableColorFromJson, toJson: nullableColorToJson) Color? brandColor,@JsonKey(readValue: _readCurrency) String currency, double balance
});




}
/// @nodoc
class _$AccountCredentialCopyWithImpl<$Res>
    implements $AccountCredentialCopyWith<$Res> {
  _$AccountCredentialCopyWithImpl(this._self, this._then);

  final AccountCredential _self;
  final $Res Function(AccountCredential) _then;

/// Create a copy of AccountCredential
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? bankName = null,Object? bankIconUrl = freezed,Object? username = null,Object? password = null,Object? website = freezed,Object? lastUpdated = null,Object? brandColor = freezed,Object? currency = null,Object? balance = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,bankIconUrl: freezed == bankIconUrl ? _self.bankIconUrl : bankIconUrl // ignore: cast_nullable_to_non_nullable
as String?,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime,brandColor: freezed == brandColor ? _self.brandColor : brandColor // ignore: cast_nullable_to_non_nullable
as Color?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountCredential].
extension AccountCredentialPatterns on AccountCredential {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountCredential value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountCredential() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountCredential value)  $default,){
final _that = this;
switch (_that) {
case _AccountCredential():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountCredential value)?  $default,){
final _that = this;
switch (_that) {
case _AccountCredential() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(readValue: _readBankName)  String bankName, @JsonKey(readValue: _readBankIconUrl)  String? bankIconUrl, @JsonKey(readValue: _readUsername)  String username, @JsonKey(readValue: _readPassword)  String password, @JsonKey(readValue: _readWebsite)  String? website, @JsonKey(readValue: _readLastUpdated, fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime lastUpdated, @JsonKey(fromJson: nullableColorFromJson, toJson: nullableColorToJson)  Color? brandColor, @JsonKey(readValue: _readCurrency)  String currency,  double balance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountCredential() when $default != null:
return $default(_that.id,_that.bankName,_that.bankIconUrl,_that.username,_that.password,_that.website,_that.lastUpdated,_that.brandColor,_that.currency,_that.balance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(readValue: _readBankName)  String bankName, @JsonKey(readValue: _readBankIconUrl)  String? bankIconUrl, @JsonKey(readValue: _readUsername)  String username, @JsonKey(readValue: _readPassword)  String password, @JsonKey(readValue: _readWebsite)  String? website, @JsonKey(readValue: _readLastUpdated, fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime lastUpdated, @JsonKey(fromJson: nullableColorFromJson, toJson: nullableColorToJson)  Color? brandColor, @JsonKey(readValue: _readCurrency)  String currency,  double balance)  $default,) {final _that = this;
switch (_that) {
case _AccountCredential():
return $default(_that.id,_that.bankName,_that.bankIconUrl,_that.username,_that.password,_that.website,_that.lastUpdated,_that.brandColor,_that.currency,_that.balance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(readValue: _readBankName)  String bankName, @JsonKey(readValue: _readBankIconUrl)  String? bankIconUrl, @JsonKey(readValue: _readUsername)  String username, @JsonKey(readValue: _readPassword)  String password, @JsonKey(readValue: _readWebsite)  String? website, @JsonKey(readValue: _readLastUpdated, fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime lastUpdated, @JsonKey(fromJson: nullableColorFromJson, toJson: nullableColorToJson)  Color? brandColor, @JsonKey(readValue: _readCurrency)  String currency,  double balance)?  $default,) {final _that = this;
switch (_that) {
case _AccountCredential() when $default != null:
return $default(_that.id,_that.bankName,_that.bankIconUrl,_that.username,_that.password,_that.website,_that.lastUpdated,_that.brandColor,_that.currency,_that.balance);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AccountCredential extends AccountCredential {
   _AccountCredential({required this.id, @JsonKey(readValue: _readBankName) required this.bankName, @JsonKey(readValue: _readBankIconUrl) this.bankIconUrl, @JsonKey(readValue: _readUsername) required this.username, @JsonKey(readValue: _readPassword) required this.password, @JsonKey(readValue: _readWebsite) this.website, @JsonKey(readValue: _readLastUpdated, fromJson: dateTimeFromJson, toJson: dateTimeToJson) required this.lastUpdated, @JsonKey(fromJson: nullableColorFromJson, toJson: nullableColorToJson) this.brandColor, @JsonKey(readValue: _readCurrency) this.currency = AppConfig.baseCurrency, this.balance = 0}): super._();
  factory _AccountCredential.fromJson(Map<String, dynamic> json) => _$AccountCredentialFromJson(json);

@override final  String id;
@override@JsonKey(readValue: _readBankName) final  String bankName;
@override@JsonKey(readValue: _readBankIconUrl) final  String? bankIconUrl;
@override@JsonKey(readValue: _readUsername) final  String username;
@override@JsonKey(readValue: _readPassword) final  String password;
@override@JsonKey(readValue: _readWebsite) final  String? website;
@override@JsonKey(readValue: _readLastUpdated, fromJson: dateTimeFromJson, toJson: dateTimeToJson) final  DateTime lastUpdated;
@override@JsonKey(fromJson: nullableColorFromJson, toJson: nullableColorToJson) final  Color? brandColor;
@override@JsonKey(readValue: _readCurrency) final  String currency;
@override@JsonKey() final  double balance;

/// Create a copy of AccountCredential
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountCredentialCopyWith<_AccountCredential> get copyWith => __$AccountCredentialCopyWithImpl<_AccountCredential>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccountCredentialToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountCredential&&(identical(other.id, id) || other.id == id)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.bankIconUrl, bankIconUrl) || other.bankIconUrl == bankIconUrl)&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password)&&(identical(other.website, website) || other.website == website)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated)&&(identical(other.brandColor, brandColor) || other.brandColor == brandColor)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.balance, balance) || other.balance == balance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bankName,bankIconUrl,username,password,website,lastUpdated,brandColor,currency,balance);

@override
String toString() {
  return 'AccountCredential(id: $id, bankName: $bankName, bankIconUrl: $bankIconUrl, username: $username, password: $password, website: $website, lastUpdated: $lastUpdated, brandColor: $brandColor, currency: $currency, balance: $balance)';
}


}

/// @nodoc
abstract mixin class _$AccountCredentialCopyWith<$Res> implements $AccountCredentialCopyWith<$Res> {
  factory _$AccountCredentialCopyWith(_AccountCredential value, $Res Function(_AccountCredential) _then) = __$AccountCredentialCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(readValue: _readBankName) String bankName,@JsonKey(readValue: _readBankIconUrl) String? bankIconUrl,@JsonKey(readValue: _readUsername) String username,@JsonKey(readValue: _readPassword) String password,@JsonKey(readValue: _readWebsite) String? website,@JsonKey(readValue: _readLastUpdated, fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime lastUpdated,@JsonKey(fromJson: nullableColorFromJson, toJson: nullableColorToJson) Color? brandColor,@JsonKey(readValue: _readCurrency) String currency, double balance
});




}
/// @nodoc
class __$AccountCredentialCopyWithImpl<$Res>
    implements _$AccountCredentialCopyWith<$Res> {
  __$AccountCredentialCopyWithImpl(this._self, this._then);

  final _AccountCredential _self;
  final $Res Function(_AccountCredential) _then;

/// Create a copy of AccountCredential
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? bankName = null,Object? bankIconUrl = freezed,Object? username = null,Object? password = null,Object? website = freezed,Object? lastUpdated = null,Object? brandColor = freezed,Object? currency = null,Object? balance = null,}) {
  return _then(_AccountCredential(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,bankIconUrl: freezed == bankIconUrl ? _self.bankIconUrl : bankIconUrl // ignore: cast_nullable_to_non_nullable
as String?,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime,brandColor: freezed == brandColor ? _self.brandColor : brandColor // ignore: cast_nullable_to_non_nullable
as Color?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
