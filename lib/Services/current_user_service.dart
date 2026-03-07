// 📁 lib/Services/current_user_service.dart
// 🎯 Enterprise-grade singleton service for current user management
// 💾 Features: Local cache (SharedPreferences) + Firebase realtime sync
// 🚀 Optimized for: Fast startup, reduced network traffic, reactive updates

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/app_snackbar.dart';

import '../Models/current_user_model.dart';

/// 🎯 Singleton service for managing current user data
///
/// **Usage:**
/// ```dart
/// // Get instance
/// final userService = CurrentUserService.instance;
///
/// // Access current user
/// final user = userService.currentUser;
///
/// // Listen to changes
/// userService.userStream.listen((user) {
///   print('User updated: ${user?.nickname}');
/// });
///
/// // Reactive GetX (if using Obx)
/// Obx(() => Text(userService.currentUserRx.value?.nickname ?? 'Guest'))
/// ```
class CurrentUserService extends GetxController {
  static const String _defaultProfileImageUrl =
      'https://firebasestorage.googleapis.com/v0/b/turqappteknoloji.firebasestorage.app/o/profileImage.png?alt=media&token=4e8e9d1f-658b-4c34-b8da-79cfe09acef2';
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🏗️ Singleton Pattern
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static CurrentUserService? _instance;

  static CurrentUserService get instance {
    _instance ??= CurrentUserService._internal();
    return _instance!;
  }

  CurrentUserService._internal();

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📦 State Management
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Current user model (null if not logged in)
  CurrentUserModel? _currentUser;

  /// Reactive wrapper for GetX (use with Obx)
  final Rx<CurrentUserModel?> currentUserRx = Rx<CurrentUserModel?>(null);

  /// Stream controller for user updates
  final StreamController<CurrentUserModel?> _userStreamController =
      StreamController<CurrentUserModel?>.broadcast();

  /// Stream of user updates
  Stream<CurrentUserModel?> get userStream => _userStreamController.stream;

  /// Current user (synchronous access)
  CurrentUserModel? get currentUser => _currentUser;

  /// Is user logged in
  bool get isLoggedIn => _currentUser != null;

  /// Current user ID (shortcut)
  String get userId => _currentUser?.userID ?? '';

  /// Current user nickname (shortcut)
  String get nickname => _currentUser?.nickname ?? '';

  /// Current user profile image (shortcut)
  String get avatarUrl {
    final raw = (_currentUser?.avatarUrl ?? '').trim();
    return raw.isEmpty ? _defaultProfileImageUrl : raw;
  }

  /// Current user full name (shortcut)
  String get fullName => _currentUser?.fullName ?? '';

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔧 Private Variables
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  SharedPreferences? _prefs;
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;

  static const String _cacheKey = 'cached_current_user';
  static const String _cacheTimestampKey = 'cached_current_user_timestamp';
  static const String _emailPromptTimestampKeyPrefix =
      'email_verify_prompt_last_shown';
  static const Duration _cacheExpiration = Duration(days: 7);

  bool _isInitialized = false;
  bool _isSyncing = false;

  // ⚠️ OPTIMIZATION: Debounce cache writes to prevent duplicate saves
  Timer? _cacheSaveTimer;
  String?
      _lastCacheSignature; // Track last saved snapshot to prevent duplicates

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🚀 Initialization
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Initialize service (can be called multiple times, e.g., after fresh login)
  ///
  /// Returns true if user loaded from cache/Firebase
  Future<bool> initialize() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        _isInitialized = true;
        emailVerifiedRx.value = true;
        return false;
      }
      emailVerifiedRx.value = firebaseUser.emailVerified;

      // If already initialized and user exists, just ensure sync is running
      if (_isInitialized &&
          _currentUser != null &&
          _currentUser!.userID == firebaseUser.uid) {
        // Same user, ensure Firebase sync is active
        if (!_isSyncing) {
          unawaited(_startFirebaseSync());
        }
        unawaited(_restorePendingDeletionIfNeeded(firebaseUser.uid));
        // Auth tarafı gecikmeli/yanlış dönebileceği için Firestore alanı ile
        // arka planda kesinleştir.
        unawaited(refreshEmailVerificationStatus(reloadAuthUser: false));
        unawaited(_loadEmailVerifyConfig());
        return true;
      }

      // Different user or first init - reload everything
      print('🔄 Initializing CurrentUserService for user: ${firebaseUser.uid}');

      // 1️⃣ Try loading from cache first (FAST - ~10ms)
      final cacheLoaded = await _loadFromCache();

      // 2️⃣ Ağır ağ işlerini arka planda başlat; startup'ı bloklamasın.
      unawaited(_restorePendingDeletionIfNeeded(firebaseUser.uid));
      unawaited(refreshEmailVerificationStatus(reloadAuthUser: false));
      unawaited(_loadEmailVerifyConfig());

      // 3️⃣ Start Firebase sync in background (await etme — cache yeterli)
      unawaited(_startFirebaseSync());

      _isInitialized = true;
      return cacheLoaded || isLoggedIn;
    } catch (e) {
      print('❌ CurrentUserService initialization error: $e');
      _isInitialized = true;
      return false;
    }
  }

  Future<void> _restorePendingDeletionIfNeeded(String uid) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final userSnap = await userRef.get();
      final data = userSnap.data();
      if (data == null) return;

      final status = (data['accountStatus'] ?? '').toString().toLowerCase();
      if (status != 'pending_deletion') return;

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      int? scheduledAtMs;
      final dynamic scheduledRaw = data['deletionScheduledAt'];
      if (scheduledRaw is Timestamp) {
        scheduledAtMs = scheduledRaw.millisecondsSinceEpoch;
      } else if (scheduledRaw is num) {
        scheduledAtMs = scheduledRaw.toInt();
      }
      if (scheduledAtMs != null && scheduledAtMs <= nowMs) {
        return;
      }

      await userRef.set({
        'accountStatus': 'active',
        'isDeleted': false,
        'isPrivate': false,
        'updatedDate': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));

      try {
        final actionSnap = await userRef
            .collection('account_actions')
            .where('type', isEqualTo: 'deletion')
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();
        if (actionSnap.docs.isNotEmpty) {
          await actionSnap.docs.first.reference.set({
            'status': 'cancelled',
            'cancelledAt': DateTime.now().millisecondsSinceEpoch,
          }, SetOptions(merge: true));
        }
      } catch (_) {}

      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('Posts')
          .where('userID', isEqualTo: uid)
          .where('deletedPost', isEqualTo: true)
          .limit(400);

      while (true) {
        final snap = await query.get();
        if (snap.docs.isEmpty) break;

        final batch = FirebaseFirestore.instance.batch();
        for (final doc in snap.docs) {
          batch.update(doc.reference, {
            'deletedPost': false,
            'deletedPostTime': 0,
            'updatedDate': DateTime.now().millisecondsSinceEpoch,
          });
        }
        await batch.commit();

        if (snap.docs.length < 400) break;
        query = FirebaseFirestore.instance
            .collection('Posts')
            .where('userID', isEqualTo: uid)
            .where('deletedPost', isEqualTo: true)
            .startAfterDocument(snap.docs.last)
            .limit(400);
      }
    } catch (e) {
      print('⚠️ pending_deletion restore skipped: $e');
    }
  }

  /// Force refresh from Firebase (bypasses cache)
  Future<void> forceRefresh() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (doc.exists) {
        final merged = await _buildMergedUserData(
          uid: firebaseUser.uid,
          rootData: doc.data() ?? const <String, dynamic>{},
        );
        await _updateUser(CurrentUserModel.fromJson(merged));
      }
      await refreshEmailVerificationStatus(reloadAuthUser: true);
    } catch (e) {
      print('❌ Force refresh error: $e');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 💾 Cache Management
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Load user from cache
  Future<bool> _loadFromCache() async {
    try {
      final cachedJson = _prefs?.getString(_cacheKey);
      final cachedTimestamp = _prefs?.getInt(_cacheTimestampKey);

      if (cachedJson == null || cachedTimestamp == null) {
        return false;
      }

      // Check cache expiration
      final cacheAge = DateTime.now().millisecondsSinceEpoch - cachedTimestamp;
      if (cacheAge > _cacheExpiration.inMilliseconds) {
        print(
            '⏰ Cache expired (${Duration(milliseconds: cacheAge).inDays} days old)');
        return false;
      }

      final json = jsonDecode(cachedJson) as Map<String, dynamic>;
      final user = CurrentUserModel.fromJson(json);

      _currentUser = user;
      currentUserRx.value = user;
      _userStreamController.add(user);

      print('✅ User loaded from cache: ${user.nickname}');
      return true;
    } catch (e) {
      print('❌ Cache load error: $e');
      return false;
    }
  }

  /// Save user to cache (debounced to prevent duplicate saves)
  Future<void> _saveToCache(CurrentUserModel user) async {
    try {
      final cacheSignature =
          '${user.userID}|${user.nickname}|${user.avatarUrl}|${user.counterOfFollowers}|'
          '${user.counterOfFollowings}|${user.counterOfPosts}|${user.bio}|${user.gizliHesap}';
      // ⚠️ OPTIMIZATION: Skip if same user was just cached
      if (_lastCacheSignature == cacheSignature) {
        return;
      }

      // Cancel pending cache write
      _cacheSaveTimer?.cancel();

      // Debounce: Wait 300ms before actually writing
      _cacheSaveTimer = Timer(const Duration(milliseconds: 300), () async {
        try {
          final json = jsonEncode(user.toJson());
          await _prefs?.setString(_cacheKey, json);
          await _prefs?.setInt(
              _cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
          _lastCacheSignature = cacheSignature;
          print('💾 User cached: ${user.nickname}');
        } catch (e) {
          print('❌ Cache save error: $e');
        }
      });
    } catch (e) {
      print('❌ Cache save error: $e');
    }
  }

  /// Clear cache
  Future<void> _clearCache() async {
    try {
      await _prefs?.remove(_cacheKey);
      await _prefs?.remove(_cacheTimestampKey);
      print('🗑️ Cache cleared');
    } catch (e) {
      print('❌ Cache clear error: $e');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔥 Firebase Sync
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Start Firebase realtime sync
  Future<void> _startFirebaseSync() async {
    if (_isSyncing) return;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    try {
      _isSyncing = true;

      // Cancel existing subscription
      await _firestoreSubscription?.cancel();

      // Listen to user document changes
      _firestoreSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .listen(
        (doc) async {
          if (!doc.exists) {
            print('❌ User document not found in Firestore');
            return;
          }

          final merged = await _buildMergedUserData(
            uid: firebaseUser.uid,
            rootData: doc.data() ?? const <String, dynamic>{},
          );
          final user = CurrentUserModel.fromJson(merged);
          await _updateUser(user);
        },
        onError: (error) {
          print('❌ Firebase sync error: $error');
        },
      );

      print('🔥 Firebase sync started');
    } catch (e) {
      print('❌ Firebase sync start error: $e');
      _isSyncing = false;
    }
  }

  Future<Map<String, dynamic>> _buildMergedUserData({
    required String uid,
    required Map<String, dynamic> rootData,
  }) async {
    final merged = <String, dynamic>{...rootData};
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    Future<Map<String, dynamic>> readSubdoc(String col, String doc) async {
      try {
        final s = await userRef.collection(col).doc(doc).get();
        if (!s.exists) return <String, dynamic>{};
        return Map<String, dynamic>.from(s.data() ?? const <String, dynamic>{});
      } catch (_) {
        return <String, dynamic>{};
      }
    }

    final privateAccount = await readSubdoc('private', 'account');
    final education = await readSubdoc('education', 'info');
    final family = await readSubdoc('family', 'info');
    final settings = await readSubdoc('settings', 'preferences');
    final stats = await readSubdoc('stats', 'summary');

    void mergeOverride(Map<String, dynamic> source) {
      source.forEach((k, v) {
        merged[k] = v;
      });
    }

    void mergeRootScope(String scope) {
      final raw = rootData[scope];
      if (raw is Map<String, dynamic>) {
        mergeOverride(raw);
        return;
      }
      if (raw is Map) {
        mergeOverride(
          raw.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    }

    // Support canonical map blocks on root document.
    mergeRootScope('profile');
    mergeRootScope('private');
    mergeRootScope('education');
    mergeRootScope('family');
    mergeRootScope('settings');
    mergeRootScope('stats');
    mergeRootScope('account');
    mergeRootScope('preferences');
    mergeRootScope('finance');

    // Canonical source is sub-docs; override root values when present.
    mergeOverride(privateAccount);
    mergeOverride(education);
    mergeOverride(family);
    mergeOverride(settings);
    mergeOverride(stats);

    // blockedUsers/readStories/lastSearches canonical subcollections.
    if (merged['blockedUsers'] is! List) {
      try {
        final snap = await userRef.collection('blockedUsers').get();
        merged['blockedUsers'] = snap.docs.map((d) => d.id).toList();
      } catch (_) {}
    }
    if (merged['readStories'] is! List) {
      try {
        final snap = await userRef.collection('readStories').get();
        merged['readStories'] = snap.docs.map((d) => d.id).toList();
        final times = <String, int>{};
        for (final d in snap.docs) {
          final t = d.data()['readDate'];
          if (t is num) times[d.id] = t.toInt();
        }
        if (times.isNotEmpty) merged['readStoriesTimes'] = times;
      } catch (_) {}
    }
    if (merged['lastSearchList'] is! List) {
      try {
        final snap = await userRef
            .collection('lastSearches')
            .orderBy('timeStamp', descending: true)
            .limit(100)
            .get();
        merged['lastSearchList'] = snap.docs.map((d) => d.id).toList();
      } catch (_) {}
    }

    return merged;
  }

  /// Stop Firebase sync
  Future<void> _stopFirebaseSync() async {
    await _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
    _isSyncing = false;
    print('🔥 Firebase sync stopped');
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔄 User Updates
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Update current user (internal)
  Future<void> _updateUser(CurrentUserModel user) async {
    _currentUser = user;
    currentUserRx.value = user;
    _userStreamController.add(user);
    await _saveToCache(user);
  }

  /// Update specific fields (optimistic update)
  ///
  /// **Example:**
  /// ```dart
  /// await userService.updateFields({
  ///   'nickname': 'new_nickname',
  ///   'bio': 'New bio text',
  /// });
  /// ```
  Future<void> updateFields(Map<String, dynamic> fields) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    try {
      final normalizedFields = _normalizeUserWriteFields(fields);
      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .update(normalizedFields);

      print('✅ Fields updated: ${normalizedFields.keys.join(', ')}');
    } catch (e) {
      print('❌ Update fields error: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _normalizeUserWriteFields(Map<String, dynamic> input) {
    final out = <String, dynamic>{...input};

    void promoteAlias({
      required String canonical,
      required List<String> aliases,
    }) {
      if (out.containsKey(canonical)) {
        for (final alias in aliases) {
          if (out.containsKey(alias)) {
            out[alias] = FieldValue.delete();
          }
        }
        return;
      }
      for (final alias in aliases) {
        if (out.containsKey(alias)) {
          out[canonical] = out[alias];
          out[alias] = FieldValue.delete();
          break;
        }
      }
    }

    void mapRootFields({
      required String scope,
      required List<String> keys,
    }) {
      for (final key in keys) {
        if (!out.containsKey(key)) continue;
        out['$scope.$key'] = out[key];
        out[key] = FieldValue.delete();
      }
    }

    // Canonical public profile aliases (single source of truth: displayName/avatarUrl)
    if (!out.containsKey('displayName')) {
      final firstName = (out['firstName'] ?? '').toString().trim();
      final lastName = (out['lastName'] ?? '').toString().trim();
      final fullName =
          [firstName, lastName].where((v) => v.isNotEmpty).join(' ').trim();
      if (fullName.isNotEmpty) {
        out['displayName'] = fullName;
      } else if (out.containsKey('nickname')) {
        out['displayName'] = out['nickname'];
      }
    }
    if (!out.containsKey('avatarUrl')) {
      out['avatarUrl'] = _defaultProfileImageUrl;
    }
    final normalizedAvatar = (out['avatarUrl'] ?? '').toString().trim();
    if (normalizedAvatar.isEmpty) {
      out['avatarUrl'] = _defaultProfileImageUrl;
    }
    if (out.containsKey('account.fcmToken')) {
      if (!out.containsKey('fcmToken')) {
        out['fcmToken'] = out['account.fcmToken'];
      }
      out['account.fcmToken'] = FieldValue.delete();
    }

    // Counter canonicalization (single source of truth: counterOf*)
    promoteAlias(
      canonical: 'counterOfFollowers',
      aliases: const ['followerCount', 'takipciSayisi'],
    );
    promoteAlias(
      canonical: 'counterOfFollowings',
      aliases: const ['followingCount', 'takipEdilenSayisi'],
    );
    promoteAlias(
      canonical: 'counterOfPosts',
      aliases: const ['postCount', 'gonderSayisi'],
    );

    // Move legacy root fields into scoped maps and remove root duplicates.
    mapRootFields(
      scope: 'education',
      keys: const [
        'bolum',
        'defAnaBaslik',
        'defDers',
        'defSinavTuru',
        'educationLevel',
        'fakulte',
        'lise',
        'ogrenciNo',
        'ogretimTipi',
        'okul',
        'okulIlce',
        'okulSehir',
        'ortaOkul',
        'ortalamaPuan',
        'ortalamaPuan1',
        'ortalamaPuan2',
        'osymPuanTuru',
        'osysPuan',
        'osysPuani1',
        'osysPuani2',
        'sinif',
        'universite',
        'yuzlukSistem',
      ],
    );
    mapRootFields(
      scope: 'family',
      keys: const [
        'bursVerebilir',
        'engelliRaporu',
        'evMulkiyeti',
        'familyInfo',
        'fatherJob',
        'fatherLiving',
        'fatherName',
        'fatherPhone',
        'fatherSalary',
        'fatherSurname',
        'isDisabled',
        'motherJob',
        'motherLiving',
        'motherName',
        'motherPhone',
        'motherSalary',
        'motherSurname',
        'mulkiyet',
        'totalLiving',
        'yurt',
      ],
    );

    return out;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎯 Quick Access Methods
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Is user blocked?
  bool isUserBlocked(String userId) {
    return _currentUser?.blockedUsers.contains(userId) ?? false;
  }

  /// Has user read story?
  bool hasReadStory(String storyId) {
    return _currentUser?.readStories.contains(storyId) ?? false;
  }

  /// Get story read time
  int? getStoryReadTime(String userId) {
    return _currentUser?.readStoriesTimes[userId];
  }

  /// Is verified account
  bool get isVerified => _currentUser?.isVerified ?? false;

  /// Email verification state (Firebase Auth)
  final RxBool emailVerifiedRx = true.obs;
  DateTime? _lastEmailPromptAt;
  Duration _emailPromptCooldown = const Duration(days: 7);

  bool get isEmailVerified => emailVerifiedRx.value;

  String? _emailPromptTimestampKey() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    return '$_emailPromptTimestampKeyPrefix:$uid';
  }

  Future<void> _loadLastEmailPromptAt() async {
    _prefs ??= await SharedPreferences.getInstance();
    final key = _emailPromptTimestampKey();
    if (key == null) {
      _lastEmailPromptAt = null;
      return;
    }
    final raw = _prefs?.getInt(key);
    _lastEmailPromptAt =
        raw == null ? null : DateTime.fromMillisecondsSinceEpoch(raw);
  }

  Future<void> _saveLastEmailPromptAt(DateTime value) async {
    _prefs ??= await SharedPreferences.getInstance();
    final key = _emailPromptTimestampKey();
    if (key == null) return;
    await _prefs?.setInt(key, value.millisecondsSinceEpoch);
    _lastEmailPromptAt = value;
  }

  Future<void> _loadEmailVerifyConfig() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('adminConfig')
          .doc('emailVerify')
          .get();
      final verifyDay = (snap.data() ?? const {})['verifyDay'];
      final days = verifyDay is num ? verifyDay.toInt() : 7;
      _emailPromptCooldown = Duration(days: days.clamp(1, 30));
    } catch (_) {
      _emailPromptCooldown = const Duration(days: 7);
    }
  }

  Future<void> refreshEmailVerificationStatus(
      {bool reloadAuthUser = true}) async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        emailVerifiedRx.value = true;
        return;
      }
      if (reloadAuthUser) {
        await user.reload();
        user = FirebaseAuth.instance.currentUser;
      }
      var isVerified = user?.emailVerified ?? false;
      if (!isVerified) {
        try {
          final uid = user?.uid;
          if (uid != null && uid.isNotEmpty) {
            final snap = await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .get();
            isVerified = (snap.data() ?? const {})['emailVerified'] == true;
          }
        } catch (_) {}
      }
      emailVerifiedRx.value = isVerified;
    } catch (_) {
      final authVerified =
          FirebaseAuth.instance.currentUser?.emailVerified ?? false;
      if (authVerified) {
        emailVerifiedRx.value = true;
        return;
      }
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null && uid.isNotEmpty) {
          final snap = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          emailVerifiedRx.value =
              (snap.data() ?? const {})['emailVerified'] == true;
          return;
        }
      } catch (_) {}
      emailVerifiedRx.value = false;
    }
  }

  Future<void> sendVerificationEmailIfNeeded({bool force = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await refreshEmailVerificationStatus(reloadAuthUser: true);
    if (!force && isEmailVerified) return;
    if (isEmailVerified) return;
    try {
      await user.sendEmailVerification();
      AppSnackbar(
          "Doğrulama E-postası", "E-posta doğrulama bağlantısı gönderildi.");
    } catch (_) {
      AppSnackbar(
          "Uyarı", "Doğrulama e-postası gönderilemedi. Lütfen tekrar deneyin.");
    }
  }

  Future<bool> ensureEmailVerifiedForRestrictedAction({
    required String actionName,
    bool showPrompt = true,
  }) async {
    await refreshEmailVerificationStatus(reloadAuthUser: true);
    if (isEmailVerified) return true;
    AppSnackbar("E-posta Doğrulama Gerekli",
        "$actionName için e-posta doğrulaması gerekli.");
    if (showPrompt) {
      await maybeShowEmailVerificationPrompt(actionName: actionName);
    }
    return false;
  }

  Future<void> maybeShowEmailVerificationPrompt({
    String? actionName,
    bool force = false,
  }) async {
    await refreshEmailVerificationStatus(reloadAuthUser: true);
    if (isEmailVerified) return;
    await _loadLastEmailPromptAt();
    final now = DateTime.now();
    if (!force &&
        _lastEmailPromptAt != null &&
        now.difference(_lastEmailPromptAt!) < _emailPromptCooldown) {
      return;
    }
    if (Get.isDialogOpen == true) return;
    await _saveLastEmailPromptAt(now);

    await Get.dialog(
      AlertDialog(
        title: const Text("E-posta Doğrulaması"),
        content: Text(
          actionName == null
              ? "Hesabını güvenli kullanmak için e-posta adresini doğrulamalısın."
              : "$actionName için e-posta adresini doğrulamalısın.",
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Daha Sonra"),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await sendVerificationEmailIfNeeded(force: true);
            },
            child: const Text("Tekrar Gönder"),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  /// Is private account
  bool get isPrivate => _currentUser?.isPrivate ?? false;

  /// Is banned
  bool get isBanned => _currentUser?.isBanned ?? false;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🚪 Logout
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Logout and clear all data
  Future<void> logout() async {
    try {
      await _stopFirebaseSync();
      await _clearCache();

      // Cancel pending cache writes
      _cacheSaveTimer?.cancel();
      _cacheSaveTimer = null;
      _lastCacheSignature = null;

      _currentUser = null;
      currentUserRx.value = null;
      _userStreamController.add(null);

      // 🔥 CRITICAL: Reset initialization flag to allow re-initialization
      _isInitialized = false;
      _isSyncing = false;
      emailVerifiedRx.value = true;
      _lastEmailPromptAt = null;

      print('👋 User logged out - State cleared');
    } catch (e) {
      print('❌ Logout error: $e');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🧹 Cleanup
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  void onClose() {
    _stopFirebaseSync();
    _userStreamController.close();
    super.onClose();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔍 Debug Info
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Get debug info
  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'isLoggedIn': isLoggedIn,
      'isSyncing': _isSyncing,
      'userId': userId,
      'nickname': nickname,
      'cacheExists': _prefs?.containsKey(_cacheKey) ?? false,
    };
  }

  /// Print debug info
  void printDebugInfo() {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔍 CurrentUserService Debug Info:');
    getDebugInfo().forEach((key, value) {
      print('  $key: $value');
    });
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }
}
