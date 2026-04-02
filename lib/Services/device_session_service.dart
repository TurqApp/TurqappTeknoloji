import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceSessionService {
  DeviceSessionService._();

  static DeviceSessionService? _instance;
  static DeviceSessionService? maybeFind() => _instance;

  static DeviceSessionService ensure() =>
      maybeFind() ?? (_instance = DeviceSessionService._());

  static DeviceSessionService get instance => ensure();

  static const String _deviceKeyPref = 'device_session.device_key';
  static const String _secureKey = 'device_session.secure_device_key';
  static const String _secureKeyV2 = 'device_session.secure_device_key_v2';
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  String _pendingClaimUid = '';
  DateTime? _pendingClaimUntil;
  static const Duration _pendingClaimWindow = Duration(seconds: 20);
  bool _freshKeyGeneratedThisLaunch = false;
  String _cachedDeviceKey = '';
  Future<String>? _deviceKeyFuture;
  final Map<String, int> _ownershipClaimAtByUid = <String, int>{};

  String get cachedDeviceKey => _cachedDeviceKey.trim();

  void beginSessionClaim(String uid) {
    final normalized = uid.trim();
    if (normalized.isEmpty) return;
    _ownershipClaimAtByUid[normalized] = DateTime.now().millisecondsSinceEpoch;
    _pendingClaimUid = normalized;
    _pendingClaimUntil = DateTime.now().add(_pendingClaimWindow);
  }

  bool hasOwnershipGuard(String uid) {
    final normalized = uid.trim();
    if (normalized.isEmpty) return false;
    final claimedAt = _ownershipClaimAtByUid[normalized];
    if (claimedAt == null || claimedAt <= 0) return false;
    final expiresAt = claimedAt + _pendingClaimWindow.inMilliseconds;
    if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
      clearOwnershipGuard(normalized);
      return false;
    }
    return true;
  }

  int getOwnershipClaimAt(String uid) {
    final normalized = uid.trim();
    if (normalized.isEmpty) return 0;
    return _ownershipClaimAtByUid[normalized] ?? 0;
  }

  void clearOwnershipGuard(String uid) {
    final normalized = uid.trim();
    if (normalized.isEmpty) return;
    _ownershipClaimAtByUid.remove(normalized);
  }

  bool hasPendingSessionClaim(String uid) {
    final normalized = uid.trim();
    if (normalized.isEmpty) return false;
    final until = _pendingClaimUntil;
    if (_pendingClaimUid != normalized || until == null) return false;
    if (DateTime.now().isAfter(until)) {
      clearPendingSessionClaim(normalized);
      return false;
    }
    return true;
  }

  void clearPendingSessionClaim(String uid) {
    final normalized = uid.trim();
    if (normalized.isEmpty || _pendingClaimUid != normalized) return;
    _pendingClaimUid = '';
    _pendingClaimUntil = null;
  }

  Future<String> getOrCreateDeviceKey() async {
    final cached = cachedDeviceKey;
    if (cached.isNotEmpty) return cached;

    final active = _deviceKeyFuture;
    if (active != null) {
      return active;
    }

    final future = _loadOrCreateDeviceKey();
    _deviceKeyFuture = future;
    return future.whenComplete(() {
      if (identical(_deviceKeyFuture, future)) {
        _deviceKeyFuture = null;
      }
    });
  }

  Future<void> warmDeviceKey() async {
    try {
      await getOrCreateDeviceKey();
    } catch (_) {}
  }

  Future<String> _loadOrCreateDeviceKey() async {
    final secureExisting =
        (await _storage.read(key: _secureKeyV2) ?? '').trim();
    if (secureExisting.isNotEmpty) {
      _cachedDeviceKey = secureExisting;
      return secureExisting;
    }

    final generated = await _generateDeviceScopedKey();
    await _writeSecureKeyWithRecovery(generated);
    await _clearLegacyKeys();
    _freshKeyGeneratedThisLaunch = true;
    _cachedDeviceKey = generated;
    return generated;
  }

  bool consumeFreshKeyGenerationFlag() {
    final value = _freshKeyGeneratedThisLaunch;
    _freshKeyGeneratedThisLaunch = false;
    return value;
  }

  bool hasFreshKeyGenerationFlag() => _freshKeyGeneratedThisLaunch;

  void clearFreshKeyGenerationFlag() {
    _freshKeyGeneratedThisLaunch = false;
  }

  Future<String?> getLegacyDeviceKey() async {
    final secureExisting = (await _storage.read(key: _secureKey) ?? '').trim();
    if (secureExisting.isNotEmpty) return secureExisting;

    final prefs = await SharedPreferences.getInstance();
    final existing = (prefs.getString(_deviceKeyPref) ?? '').trim();
    if (existing.isNotEmpty) return existing;
    return null;
  }

  Future<String> _generateDeviceScopedKey() async {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final buffer = StringBuffer(
      DateTime.now().millisecondsSinceEpoch.toRadixString(16),
    );
    final deviceSeed = await _readDeviceSeed();
    if (deviceSeed.isNotEmpty) {
      buffer.write(deviceSeed);
    }
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  Future<String> _readDeviceSeed() async {
    try {
      final plugin = DeviceInfoPlugin();
      final android = await plugin.androidInfo;
      final candidate = [
        android.id,
        android.fingerprint,
        android.board,
        android.brand,
        android.device,
      ].join('_');
      if (candidate.trim().isNotEmpty) {
        return candidate.replaceAll(' ', '_');
      }
    } catch (_) {}

    try {
      final plugin = DeviceInfoPlugin();
      final ios = await plugin.iosInfo;
      final candidate = [
        ios.identifierForVendor,
        ios.model,
        ios.systemName,
        ios.name,
      ].join('_');
      if (candidate.trim().isNotEmpty) {
        return candidate.replaceAll(' ', '_');
      }
    } catch (_) {}

    return '';
  }

  Future<void> _clearLegacyKeys() async {
    await _storage.delete(key: _secureKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceKeyPref);
  }

  Future<void> _writeSecureKeyWithRecovery(String generated) async {
    try {
      await _storage.write(key: _secureKeyV2, value: generated);
      return;
    } on PlatformException catch (error) {
      final message = (error.message ?? '').toLowerCase();
      final isDuplicateKeychainItem =
          error.code == '-25299' || message.contains('already exists');
      if (!isDuplicateKeychainItem) rethrow;

      final existing = (await _storage.read(key: _secureKeyV2) ?? '').trim();
      if (existing.isNotEmpty) return;

      await _storage.delete(key: _secureKeyV2);
      await _storage.write(key: _secureKeyV2, value: generated);
    }
  }
}
