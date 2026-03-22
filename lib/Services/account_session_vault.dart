import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:turqappv2/Core/Utils/email_utils.dart';

class AccountSessionCredential {
  const AccountSessionCredential({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  Map<String, String> toJson() => {
        'email': email,
        'password': password,
      };

  factory AccountSessionCredential.fromJson(Map<String, dynamic> json) {
    return AccountSessionCredential(
      email: normalizeEmailAddress((json['email'] ?? '').toString()),
      password: (json['password'] ?? '').toString(),
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

  Future<void> saveEmailPassword({
    required String uid,
    required String email,
    required String password,
  }) async {
    final normalizedUid = uid.trim();
    final normalizedEmail = normalizeEmailAddress(email);
    if (normalizedUid.isEmpty || normalizedEmail.isEmpty || password.isEmpty) {
      return;
    }
    final payload = jsonEncode(
      AccountSessionCredential(
        email: normalizedEmail,
        password: password,
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
      final credential = AccountSessionCredential.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (credential.email.isEmpty || credential.password.isEmpty) {
        return null;
      }
      return credential;
    } catch (_) {
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
}
