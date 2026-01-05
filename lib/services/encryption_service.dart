// lib/services/encryption_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:morpheus/services/error_reporter.dart';

class EncryptionService {
  static const String _legacyFallbackKey = 'YOUR_32_CHARACTER_LONG_KEY_HERE'; // 32 chars
  static const String _legacyFallbackIv = 'YOUR_16_CHARACTER_LONG_IV'; // 16 chars
  static const String _cipherVersionPrefix = 'v1:';
  static const String _keyStorageKey = 'morpheus.encryption.key';
  static const String _ivStorageKey = 'morpheus.encryption.iv';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static String _keyValue = _legacyFallbackKey;
  static String _ivValue = _legacyFallbackIv;
  static Encrypter? _encrypter;
  static Encrypter? _legacyEncrypter;
  static IV? _iv;
  static bool _initialized = false;

  static Future<void> initialize({FlutterSecureStorage? storage}) async {
    if (_initialized) return;
    final secureStorage = storage ?? _storage;
    String? storedKey;
    String? storedIv;
    try {
      storedKey = await secureStorage.read(key: _keyStorageKey);
      storedIv = await secureStorage.read(key: _ivStorageKey);
    } catch (e, stack) {
      await ErrorReporter.recordError(e, stack, reason: 'Read encryption keys failed');
    }

    final hasStoredKey = storedKey != null;
    final hasStoredIv = storedIv != null;
    final missingPair = !hasStoredKey && !hasStoredIv;

    var nextKey = missingPair ? _legacyFallbackKey : (storedKey ?? _legacyFallbackKey);
    var nextIv = missingPair ? _legacyFallbackIv : (storedIv ?? _legacyFallbackIv);
    var shouldWriteKey = missingPair || !hasStoredKey;
    var shouldWriteIv = missingPair || !hasStoredIv;

    _keyValue = nextKey;
    _ivValue = nextIv;
    if (!_configureCipher()) {
      nextKey = _generateKeyValue();
      nextIv = _generateIvValue();
      _keyValue = nextKey;
      _ivValue = nextIv;
      _configureCipher();
      shouldWriteKey = true;
      shouldWriteIv = true;
    }

    try {
      if (shouldWriteKey) {
        await secureStorage.write(key: _keyStorageKey, value: _keyValue);
      }
      if (shouldWriteIv) {
        await secureStorage.write(key: _ivStorageKey, value: _ivValue);
      }
    } catch (e, stack) {
      await ErrorReporter.recordError(e, stack, reason: 'Persist encryption keys failed');
    }
    _initialized = true;
  }

  static void _ensureReady() {
    if (_encrypter != null && _iv != null && _legacyEncrypter != null) return;
    if (!_initialized) {
      debugPrint('EncryptionService used before initialize; using fallback key/iv.');
    }
    _configureCipher();
  }

  static String encryptData(String data) {
    _ensureReady();
    final encrypted = _encrypter!.encrypt(data, iv: _iv!).base64;
    return '$_cipherVersionPrefix$encrypted';
  }

  static String decryptData(String encryptedData) {
    _ensureReady();
    final raw = encryptedData.trim();
    if (raw.startsWith(_cipherVersionPrefix)) {
      final payload = raw.substring(_cipherVersionPrefix.length);
      return _encrypter!.decrypt64(payload, iv: _iv!);
    }
    try {
      return _legacyEncrypter!.decrypt64(raw, iv: _iv!);
    } catch (_) {
      return _encrypter!.decrypt64(raw, iv: _iv!);
    }
  }

  static String encryptPin(String pin) {
    _ensureReady();
    return sha256.convert(utf8.encode(pin + _keyValue)).toString();
  }

  static String _generateKeyValue() {
    return Key.fromSecureRandom(32).base64;
  }

  static String _generateIvValue() {
    return IV.fromSecureRandom(16).base64;
  }

  static bool _configureCipher() {
    try {
      final key = _keyFromStorageValue(_keyValue);
      _encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      _legacyEncrypter = Encrypter(AES(key, mode: AESMode.sic));
      _iv = _ivFromStorageValue(_ivValue);
      return true;
    } catch (e, stack) {
      unawaited(ErrorReporter.recordError(e, stack, reason: 'Invalid encryption key/iv; reinitializing'));
      _encrypter = Encrypter(AES(Key.fromUtf8(_legacyFallbackKey), mode: AESMode.cbc));
      _legacyEncrypter = Encrypter(AES(Key.fromUtf8(_legacyFallbackKey), mode: AESMode.sic));
      _iv = IV.fromUtf8(_legacyFallbackIv);
      return false;
    }
  }

  static Key _keyFromStorageValue(String value) {
    final bytes = _tryBase64Decode(value);
    if (bytes != null && bytes.length == 32) {
      return Key(bytes);
    }
    if (value.length == 32) {
      return Key.fromUtf8(value);
    }
    throw ArgumentError('Invalid key length');
  }

  static IV _ivFromStorageValue(String value) {
    final bytes = _tryBase64Decode(value);
    if (bytes != null && bytes.length == 16) {
      return IV(bytes);
    }
    if (value.length == 16) {
      return IV.fromUtf8(value);
    }
    throw ArgumentError('Invalid iv length');
  }

  static Uint8List? _tryBase64Decode(String value) {
    try {
      return base64.decode(value);
    } catch (_) {
      return null;
    }
  }
}
