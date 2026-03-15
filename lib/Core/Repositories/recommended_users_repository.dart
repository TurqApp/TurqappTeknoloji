import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Utils/user_scoped_key.dart';
import 'package:turqappv2/Models/recommended_user_model.dart';

class RecommendedUsersRepository extends GetxService {
  static const String _prefsKeyPrefix = 'recommended_users_repository_v1';
  static const Duration _ttl = Duration(minutes: 10);

  List<RecommendedUserModel> _memory = const <RecommendedUserModel>[];
  DateTime? _cachedAt;
  SharedPreferences? _prefs;
  bool _initialized = false;
  StreamSubscription<User?>? _authSub;

  static RecommendedUsersRepository ensure() {
    if (Get.isRegistered<RecommendedUsersRepository>()) {
      return Get.find<RecommendedUsersRepository>();
    }
    return Get.put(RecommendedUsersRepository(), permanent: true);
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _restoreFromPrefs();
    _authSub ??= FirebaseAuth.instance.authStateChanges().listen((_) {
      _memory = const <RecommendedUserModel>[];
      _cachedAt = null;
      _restoreFromPrefs();
    });
    _initialized = true;
  }

  String get _prefsKey => userScopedKey(_prefsKeyPrefix);

  Future<List<RecommendedUserModel>> fetchCandidates({
    int limit = 500,
    bool preferCache = true,
  }) async {
    await _ensureInitialized();

    if (preferCache && _isFresh && _memory.length >= limit) {
      return List<RecommendedUserModel>.from(_memory.take(limit));
    }

    if (preferCache && _isFresh && _memory.isNotEmpty) {
      return List<RecommendedUserModel>.from(_memory.take(limit));
    }

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('isPrivate', isEqualTo: false)
        .limit(limit)
        .get(const GetOptions(source: Source.serverAndCache));

    final fetched = snap.docs
        .map(RecommendedUserModel.fromDocument)
        .toList(growable: false);
    _memory = fetched;
    _cachedAt = DateTime.now();
    await _persistToPrefs();
    return List<RecommendedUserModel>.from(fetched);
  }

  bool get _isFresh =>
      _cachedAt != null && DateTime.now().difference(_cachedAt!) <= _ttl;

  void _restoreFromPrefs() {
    try {
      final raw = _prefs?.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final cachedAtMs = (decoded['cachedAt'] as num?)?.toInt() ?? 0;
      final items = (decoded['items'] as List?) ?? const [];
      if (cachedAtMs <= 0 || items.isEmpty) return;
      final restored = <RecommendedUserModel>[];
      for (final item in items) {
        if (item is! Map) continue;
        final map = item.cast<String, dynamic>();
        final uid = (map['userID'] ?? '').toString().trim();
        if (uid.isEmpty) continue;
        restored.add(RecommendedUserModel.fromMap(uid, map));
      }
      if (restored.isEmpty) return;
      _memory = restored;
      _cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
    } catch (_) {}
  }

  Future<void> _persistToPrefs() async {
    try {
      await _prefs?.setString(
        _prefsKey,
        jsonEncode({
          'cachedAt': _cachedAt?.millisecondsSinceEpoch ?? 0,
          'items': _memory.map((e) => e.toMap()).toList(),
        }),
      );
    } catch (_) {}
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }
}
