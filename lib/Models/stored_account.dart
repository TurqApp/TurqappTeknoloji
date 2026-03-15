import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:turqappv2/Models/current_user_model.dart';

class StoredAccount {
  const StoredAccount({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.providers,
    required this.lastUsedAt,
    required this.isSessionValid,
    required this.requiresReauth,
    required this.accountState,
    required this.isPinned,
    required this.sortOrder,
    required this.lastSuccessfulSignInAt,
  });

  final String uid;
  final String username;
  final String displayName;
  final String avatarUrl;
  final List<String> providers;
  final int lastUsedAt;
  final bool isSessionValid;
  final bool requiresReauth;
  final String accountState;
  final bool isPinned;
  final int sortOrder;
  final int lastSuccessfulSignInAt;

  bool get hasPasswordProvider => providers.contains('password');

  String get primaryProvider {
    if (providers.contains('password')) return 'password';
    if (providers.isNotEmpty) return providers.first;
    return '';
  }

  StoredAccount copyWith({
    String? uid,
    String? username,
    String? displayName,
    String? avatarUrl,
    List<String>? providers,
    int? lastUsedAt,
    bool? isSessionValid,
    bool? requiresReauth,
    String? accountState,
    bool? isPinned,
    int? sortOrder,
    int? lastSuccessfulSignInAt,
  }) {
    return StoredAccount(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      providers: providers ?? this.providers,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isSessionValid: isSessionValid ?? this.isSessionValid,
      requiresReauth: requiresReauth ?? this.requiresReauth,
      accountState: accountState ?? this.accountState,
      isPinned: isPinned ?? this.isPinned,
      sortOrder: sortOrder ?? this.sortOrder,
      lastSuccessfulSignInAt:
          lastSuccessfulSignInAt ?? this.lastSuccessfulSignInAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'providers': providers,
      'lastUsedAt': lastUsedAt,
      'isSessionValid': isSessionValid,
      'requiresReauth': requiresReauth,
      'accountState': accountState,
      'isPinned': isPinned,
      'sortOrder': sortOrder,
      'lastSuccessfulSignInAt': lastSuccessfulSignInAt,
    };
  }

  factory StoredAccount.fromJson(Map<String, dynamic> json) {
    return StoredAccount(
      uid: (json['uid'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      avatarUrl: (json['avatarUrl'] ?? '').toString(),
      providers: (json['providers'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList(growable: false) ??
          const <String>[],
      lastUsedAt: (json['lastUsedAt'] as num?)?.toInt() ?? 0,
      isSessionValid: json['isSessionValid'] != false,
      requiresReauth: json['requiresReauth'] == true,
      accountState: (json['accountState'] ?? 'active').toString(),
      isPinned: json['isPinned'] == true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      lastSuccessfulSignInAt:
          (json['lastSuccessfulSignInAt'] as num?)?.toInt() ?? 0,
    );
  }

  static StoredAccount fromCurrentUser({
    required CurrentUserModel user,
    required User firebaseUser,
  }) {
    final username = user.nickname.trim();
    final displayName = user.fullName.trim().isNotEmpty
        ? user.fullName.trim()
        : username;
    final providers = firebaseUser.providerData
        .map((e) => e.providerId.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return StoredAccount(
      uid: user.userID,
      username: username,
      displayName: displayName,
      avatarUrl: user.avatarUrl.trim(),
      providers: providers,
      lastUsedAt: DateTime.now().millisecondsSinceEpoch,
      isSessionValid: true,
      requiresReauth: false,
      accountState: user.isBanned ? 'disabled' : 'active',
      isPinned: false,
      sortOrder: 0,
      lastSuccessfulSignInAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static List<StoredAccount> decodeList(String raw) {
    if (raw.trim().isEmpty) return const <StoredAccount>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <StoredAccount>[];
    return decoded
        .whereType<Map>()
        .map((item) => StoredAccount.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.uid.trim().isNotEmpty)
        .toList(growable: false);
  }

  static String encodeList(List<StoredAccount> accounts) {
    return jsonEncode(accounts.map((item) => item.toJson()).toList());
  }
}
