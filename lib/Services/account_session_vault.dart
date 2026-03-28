import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:turqappv2/Core/Utils/email_utils.dart';
import 'package:turqappv2/Runtime/startup_session_failure.dart';

class AccountSessionCredential {
  const AccountSessionCredential({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  // Password persistence is intentionally disabled. We only keep the
  // identifier needed to prefill a re-auth flow.
  Map<String, String> toJson() => {
        'email': email,
      };

  factory AccountSessionCredential.fromJson(Map<String, dynamic> json) {
    return AccountSessionCredential(
      email: normalizeEmailAddress((json['email'] ?? '').toString()),
      password: '',
    );
  }
}

class AccountSessionVault {
  AccountSessionVault._();

  static AccountSessionVault? _instance;
  static AccountSessionVault? maybeFind() => _instance;

  static AccountSessionVault ensure() =>
      maybeFind() ?? (_instance = AccountSessionVault._());

  static AccountSessionVault get instance => ensure();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _prefix = 'account_session_vault';

  String _keyFor(String uid) => '$_prefix:$uid';

  Future<void> saveEmailHint({
    required String uid,
    required String email,
    required String password,
  }) async {
    final normalizedUid = uid.trim();
    final normalizedEmail = normalizeEmailAddress(email);
    if (normalizedUid.isEmpty || normalizedEmail.isEmpty) {
      return;
    }
    final payload = jsonEncode(
      AccountSessionCredential(
        email: normalizedEmail,
        password: '',
      ).toJson(),
    );
    await _storage.write(key: _keyFor(normalizedUid), value: payload);
  }

  Future<AccountSessionCredential?> read(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return null;
    final raw = await _storage.read(key: _keyFor(normalizedUid));
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final payload = Map<String, dynamic>.from(decoded);
      final credential = AccountSessionCredential.fromJson(payload);
      if (credential.email.isEmpty) {
        return null;
      }
      final sanitizedPayload = jsonEncode(credential.toJson());
      if (raw != sanitizedPayload) {
        await _storage.write(key: _keyFor(normalizedUid), value: sanitizedPayload);
      }
      return credential;
    } catch (error, stackTrace) {
      StartupSessionFailureReporter.defaultReporter.record(
        kind: StartupSessionFailureKind.vaultRead,
        operation: 'AccountSessionVault.read',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<bool> hasCredential(String uid) async {
    return await read(uid) != null;
  }

  Future<void> delete(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return;
    await _storage.delete(key: _keyFor(normalizedUid));
  }

  Future<void> deleteAll() async {
    final all = await _storage.readAll();
    for (final key in all.keys) {
      if (key.startsWith(_prefix)) {
        await _storage.delete(key: key);
      }
    }
  }

  Future<void> removeStoredPasswords() async {
    final all = await _storage.readAll();
    for (final entry in all.entries) {
      if (!entry.key.startsWith(_prefix)) continue;
      final raw = entry.value;
      if (raw.trim().isEmpty) {
        await _storage.delete(key: entry.key);
        continue;
      }
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) {
          await _storage.delete(key: entry.key);
          continue;
        }
        final credential = AccountSessionCredential.fromJson(
          Map<String, dynamic>.from(decoded),
        );
        if (credential.email.isEmpty) {
          await _storage.delete(key: entry.key);
          continue;
        }
        final sanitizedPayload = jsonEncode(credential.toJson());
        if (raw != sanitizedPayload) {
          await _storage.write(key: entry.key, value: sanitizedPayload);
        }
      } catch (error, stackTrace) {
        StartupSessionFailureReporter.defaultReporter.record(
          kind: StartupSessionFailureKind.vaultScrub,
          operation: 'AccountSessionVault.removeStoredPasswords',
          error: error,
          stackTrace: stackTrace,
        );
        await _storage.delete(key: entry.key);
      }
    }
  }
}
