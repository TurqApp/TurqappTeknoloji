// 📁 lib/Services/current_user_service.dart
// 🎯 Enterprise-grade singleton service for current user management
// 💾 Features: Local cache (SharedPreferences) + Firebase realtime sync
// 🚀 Optimized for: Fast startup, reduced network traffic, reactive updates

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/metadata_cache_policy.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/metadata_read_policy.dart';
import 'package:turqappv2/Core/Repositories/user_subdoc_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';

import '../Models/current_user_model.dart';

part 'current_user_service_cache_part.dart';

class _TimedValue<T> {
  final T value;
  final DateTime fetchedAt;

  const _TimedValue({
    required this.value,
    required this.fetchedAt,
  });
}

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

  void _emitUserEvent(CurrentUserModel? user) {
    if (_userStreamController.isClosed) return;
    _userStreamController.add(user);
  }

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
    return isDefaultAvatarUrl(raw) ? '' : raw;
  }

  /// Current user full name (shortcut)
  String get fullName => _currentUser?.fullName ?? '';

  /// Feed view selection with local fallback.
  /// 0: Classic, 1: Modern
  int get effectiveViewSelection => viewSelectionRx.value;
  final RxInt viewSelectionRx = 1.obs;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔧 Private Variables
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  SharedPreferences? _prefs;
  StreamSubscription<Map<String, dynamic>?>? _firestoreSubscription;

  static const String _cacheKey = 'cached_current_user';
  static const String _cacheTimestampKey = 'cached_current_user_timestamp';
  static const String _viewSelectionPrefKeyPrefix =
      'preferred_feed_view_selection';
  static const String _emailPromptTimestampKeyPrefix =
      'email_verify_prompt_last_shown';
  static Duration get _cacheExpiration =>
      MetadataCachePolicy.ttlFor(MetadataCacheBucket.currentUserSummary);

  bool _isInitialized = false;
  bool _isSyncing = false;
  int? _lastKnownViewSelection;
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();
  static const Duration _rootDocCacheTtl = Duration(minutes: 2);
  static const Duration _subdocCacheTtl = Duration(minutes: 10);
  static const Duration _listCacheTtl = Duration(minutes: 2);
  final Map<String, _TimedValue<Map<String, dynamic>>> _rootDocCache = {};
  final Map<String, _TimedValue<Map<String, dynamic>>> _subdocCache = {};
  final Map<String, _TimedValue<Map<String, dynamic>>> _listCache = {};
  final Map<String, DateTime> _silentLogAt = {};

  // ⚠️ OPTIMIZATION: Debounce cache writes to prevent duplicate saves
  Timer? _cacheSaveTimer;
  String?
      _lastCacheSignature; // Track last saved snapshot to prevent duplicates
  String? _lastReactiveSignature;
  String? _lastRootSyncSignature;
  String? _lastWarmedAvatarUrl;

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
        _purgeUserScopedCaches(_currentUser?.userID);
        _isInitialized = true;
        emailVerifiedRx.value = true;
        return false;
      }
      emailVerifiedRx.value = firebaseUser.emailVerified;
      _lastKnownViewSelection =
          _prefs?.getInt(_viewSelectionKey(firebaseUser.uid));
      viewSelectionRx.value = _lastKnownViewSelection ?? 1;

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
      if (_currentUser != null && _currentUser!.userID != firebaseUser.uid) {
        _purgeUserScopedCaches(_currentUser!.userID);
        await _clearCache();
        if (Get.isRegistered<UserProfileCacheService>()) {
          await Get.find<UserProfileCacheService>().clearAll();
        }
      }
      // 1️⃣ Try loading from cache first (FAST - ~10ms)
      final cacheLoaded = await _loadFromCache(expectedUid: firebaseUser.uid);

      // 1.5️⃣ Theme/view mode kritik bir ayar: sync'i beklemeden Firestore'dan
      // tek alan okuyup ilk render öncesi kesinleştir.
      await _primeViewSelectionFromFirestore(firebaseUser.uid)
          .timeout(const Duration(milliseconds: 350), onTimeout: () {});

      // 2️⃣ Ağır ağ işlerini arka planda başlat; startup'ı bloklamasın.
      unawaited(_restorePendingDeletionIfNeeded(firebaseUser.uid));
      unawaited(refreshEmailVerificationStatus(reloadAuthUser: false));
      unawaited(_loadEmailVerifyConfig());

      // 3️⃣ Start Firebase sync in background (await etme — cache yeterli)
      unawaited(_startFirebaseSync());

      _isInitialized = true;
      return cacheLoaded || isLoggedIn;
    } catch (_) {
      _isInitialized = true;
      return false;
    }
  }

  Future<void> _restorePendingDeletionIfNeeded(String uid) async {
    try {
      final userRepository = UserRepository.ensure();
      final data = await _readRootUserData(uid, preferCache: true);
      if (data.isEmpty) return;

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

      await userRepository.updateUserFields(uid, {
        'accountStatus': 'active',
        'isDeleted': false,
        'isPrivate': false,
        'updatedDate': DateTime.now().millisecondsSinceEpoch,
      });

      try {
        final actions = await _userSubcollectionRepository.getEntries(
          uid,
          subcollection: 'account_actions',
          preferCache: true,
        );
        final pendingDeletion = actions.firstWhereOrNull(
          (entry) =>
              (entry.data['type'] ?? '').toString() == 'deletion' &&
              (entry.data['status'] ?? '').toString() == 'pending',
        );
        if (pendingDeletion != null) {
          await _userSubcollectionRepository.upsertEntry(
            uid,
            subcollection: 'account_actions',
            docId: pendingDeletion.id,
            data: {
              'status': 'cancelled',
              'cancelledAt': DateTime.now().millisecondsSinceEpoch,
            },
          );
          final next = actions.map((entry) {
            if (entry.id != pendingDeletion.id) return entry;
            return UserSubcollectionEntry(
              id: entry.id,
              data: {
                ...entry.data,
                'status': 'cancelled',
                'cancelledAt': DateTime.now().millisecondsSinceEpoch,
              },
            );
          }).toList(growable: false);
          await _userSubcollectionRepository.setEntries(
            uid,
            subcollection: 'account_actions',
            items: next,
          );
        }
      } catch (e, st) {
        _logSilently('restore.account_actions', e, st);
      }

      await PostRepository.ensure().restoreDeletedPostsForUser(uid);
    } catch (_) {}
  }

  Future<void> restorePendingDeletionIfNeededForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    await _restorePendingDeletionIfNeeded(uid);
  }

  /// Force refresh from Firebase (bypasses cache)
  Future<void> forceRefresh() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    try {
      _purgeUserScopedCaches(firebaseUser.uid);
      final data = await _readRootUserData(
        firebaseUser.uid,
        preferCache: false,
        forceServer: true,
      );

      if (data.isNotEmpty) {
        final merged = await _buildMergedUserData(
          uid: firebaseUser.uid,
          rootData: data,
        );
        await _updateUser(CurrentUserModel.fromJson(merged));
      }
      await refreshEmailVerificationStatus(reloadAuthUser: true);
    } catch (_) {}
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 💾 Cache Management
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
      _firestoreSubscription =
          UserRepository.ensure().watchUserRaw(firebaseUser.uid).listen(
        (data) async {
          if (data == null || data.isEmpty) {
            return;
          }
          final rootSignature = jsonEncode(data);
          if (_currentUser?.userID == firebaseUser.uid &&
              _lastRootSyncSignature == rootSignature) {
            return;
          }
          _storeRootUserData(firebaseUser.uid, data);
          _lastRootSyncSignature = rootSignature;

          final merged = await _buildMergedUserData(
            uid: firebaseUser.uid,
            rootData: data,
          );
          final user = CurrentUserModel.fromJson(merged);
          await _updateUser(user);
        },
        onError: (_) {},
      );
    } catch (_) {
      _isSyncing = false;
    }
  }

  Future<Map<String, dynamic>> _buildMergedUserData({
    required String uid,
    required Map<String, dynamic> rootData,
  }) async {
    final merged = <String, dynamic>{...rootData};
    final currentSnapshot =
        (_currentUser != null && _currentUser!.userID == uid)
            ? _currentUser!.toJson()
            : const <String, dynamic>{};

    Map<String, dynamic> extractRootMap(String key) {
      final raw = rootData[key];
      if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
      if (raw is Map) {
        return raw.map((mapKey, value) => MapEntry(mapKey.toString(), value));
      }
      return <String, dynamic>{};
    }

    Map<String, dynamic> extractCurrentMap(String key) {
      final raw = currentSnapshot[key];
      if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
      if (raw is Map) {
        return raw.map((mapKey, value) => MapEntry(mapKey.toString(), value));
      }
      return <String, dynamic>{};
    }

    Future<Map<String, dynamic>> readSubdocCached(
      String col,
      String doc,
    ) async {
      final repository = UserSubdocRepository.ensure();
      try {
        final data = await repository.getDoc(
          uid,
          collection: col,
          docId: doc,
          preferCache: true,
          ttl: _subdocCacheTtl,
        );
        return data;
      } catch (e, st) {
        _logSilently('subdoc.$col.$doc', e, st);
        return <String, dynamic>{};
      }
    }

    Future<Map<String, dynamic>> readListCache(
      String key,
      Future<Map<String, dynamic>> Function() loader,
    ) async {
      final cacheKey = _listCacheKey(uid, key);
      final cached = _listCache[cacheKey];
      if (cached != null && _isFresh(cached.fetchedAt, _listCacheTtl)) {
        return Map<String, dynamic>.from(cached.value);
      }
      try {
        final loaded = await loader();
        _listCache[cacheKey] = _TimedValue<Map<String, dynamic>>(
          value: loaded,
          fetchedAt: DateTime.now(),
        );
        return loaded;
      } catch (e, st) {
        _logSilently('subcol.$key', e, st);
        if (cached != null) {
          return Map<String, dynamic>.from(cached.value);
        }
        return <String, dynamic>{};
      }
    }

    // Read amplification guard:
    // If root already has canonical map blocks, skip extra sub-doc reads.
    final rootPrivate = extractRootMap('private');
    final rootEducation = extractRootMap('education');
    final rootFamily = extractRootMap('family');
    final rootSettings = extractRootMap('settings');
    final rootStats = extractRootMap('stats');
    final currentPrivate = extractCurrentMap('private');
    final currentEducation = extractCurrentMap('education');
    final currentFamily = extractCurrentMap('family');
    final currentSettings = extractCurrentMap('settings');
    final currentStats = extractCurrentMap('stats');

    final privateAccount = rootPrivate.isNotEmpty
        ? rootPrivate
        : (currentPrivate.isNotEmpty
            ? currentPrivate
            : await readSubdocCached('private', 'account'));
    final education = rootEducation.isNotEmpty
        ? rootEducation
        : (currentEducation.isNotEmpty
            ? currentEducation
            : await readSubdocCached('education', 'info'));
    final family = rootFamily.isNotEmpty
        ? rootFamily
        : (currentFamily.isNotEmpty
            ? currentFamily
            : await readSubdocCached('family', 'info'));
    final settings = rootSettings.isNotEmpty
        ? rootSettings
        : (currentSettings.isNotEmpty
            ? currentSettings
            : await readSubdocCached('settings', 'preferences'));
    final stats = rootStats.isNotEmpty
        ? rootStats
        : (currentStats.isNotEmpty
            ? currentStats
            : await readSubdocCached('stats', 'summary'));

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

    bool hasNonEmptyString(dynamic value) =>
        value is String && value.trim().isNotEmpty;

    void preferRootString(String key) {
      if (!rootData.containsKey(key)) return;
      final value = rootData[key];
      if (hasNonEmptyString(value)) {
        merged[key] = value;
      }
    }

    void preferCurrentString(String key) {
      if (hasNonEmptyString(merged[key])) return;
      final value = currentSnapshot[key];
      if (hasNonEmptyString(value)) {
        merged[key] = value;
      }
    }

    void preferRootScalar(String key) {
      if (!rootData.containsKey(key)) return;
      final value = rootData[key];
      if (value != null) {
        merged[key] = value;
      }
    }

    // Root canonical identity fields must win over legacy nested maps.
    for (final key in const [
      'avatarUrl',
      'nickname',
      'nickName',
      'username',
      'userName',
      'usernameLower',
      'displayName',
      'firstName',
      'lastName',
      'email',
      'phoneNumber',
      'bio',
      'rozet',
      'badge',
      'meslekKategori',
      'token',
    ]) {
      preferRootString(key);
    }
    for (final key in const [
      'avatarUrl',
      'nickname',
      'nickName',
      'username',
      'userName',
      'usernameLower',
      'displayName',
      'firstName',
      'lastName',
      'email',
      'phoneNumber',
      'bio',
      'rozet',
      'badge',
      'meslekKategori',
      'token',
    ]) {
      preferCurrentString(key);
    }
    for (final key in const [
      'counterOfFollowers',
      'counterOfFollowings',
      'counterOfPosts',
      'counterOfLikes',
      'antPoint',
      'dailyDurations',
      'createdDate',
      'updatedDate',
      'viewSelection',
    ]) {
      preferRootScalar(key);
    }

    // blockedUsers/readStories/lastSearches canonical subcollections.
    final currentBlocked = currentSnapshot['blockedUsers'];
    if (merged['blockedUsers'] is! List) {
      if (currentBlocked is List && currentBlocked.isNotEmpty) {
        merged['blockedUsers'] =
            currentBlocked.map((e) => e.toString()).toList(growable: false);
      } else {
        final blocked = await readListCache('blockedUsers', () async {
          final entries = await _userSubcollectionRepository.getEntries(
            uid,
            subcollection: 'blockedUsers',
            preferCache: true,
          );
          return <String, dynamic>{
            'blockedUsers': entries.map((d) => d.id).toList(growable: false),
          };
        });
        final list = blocked['blockedUsers'];
        if (list is List) {
          merged['blockedUsers'] = list.map((e) => e.toString()).toList();
        }
      }
    }
    final currentReadStories = currentSnapshot['readStories'];
    final currentReadStoriesTimes = currentSnapshot['readStoriesTimes'];
    if (merged['readStories'] is! List) {
      if (currentReadStories is List && currentReadStories.isNotEmpty) {
        merged['readStories'] =
            currentReadStories.map((e) => e.toString()).toList(growable: false);
        if (currentReadStoriesTimes is Map &&
            currentReadStoriesTimes.isNotEmpty) {
          final normalized = <String, int>{};
          currentReadStoriesTimes.forEach((k, v) {
            if (v is num) normalized[k.toString()] = v.toInt();
          });
          if (normalized.isNotEmpty) {
            merged['readStoriesTimes'] = normalized;
          }
        }
      } else {
        final readStories = await readListCache('readStories', () async {
          final entries = await _userSubcollectionRepository.getEntries(
            uid,
            subcollection: 'readStories',
            preferCache: true,
          );
          final times = <String, int>{};
          for (final entry in entries) {
            final t = entry.data['readDate'];
            if (t is num) times[entry.id] = t.toInt();
          }
          return <String, dynamic>{
            'readStories': entries.map((e) => e.id).toList(growable: false),
            'readStoriesTimes': times,
          };
        });
        final list = readStories['readStories'];
        if (list is List) {
          merged['readStories'] = list.map((e) => e.toString()).toList();
        }
        final times = readStories['readStoriesTimes'];
        if (times is Map) {
          final normalized = <String, int>{};
          times.forEach((k, v) {
            if (v is num) normalized[k.toString()] = v.toInt();
          });
          if (normalized.isNotEmpty) {
            merged['readStoriesTimes'] = normalized;
          }
        }
      }
    }
    final currentLastSearchList = currentSnapshot['lastSearchList'];
    if (merged['lastSearchList'] is! List) {
      if (currentLastSearchList is List && currentLastSearchList.isNotEmpty) {
        merged['lastSearchList'] = currentLastSearchList
            .map((e) => e.toString())
            .toList(growable: false);
      } else {
        final searches = await readListCache('lastSearches', () async {
          final entries = await _userSubcollectionRepository.getEntries(
            uid,
            subcollection: 'lastSearches',
            preferCache: true,
          );
          final docs = entries.toList()
            ..sort((a, b) {
              final aData = a.data;
              final bData = b.data;
              final aTs = (aData['updatedDate'] is num)
                  ? (aData['updatedDate'] as num).toInt()
                  : ((aData['timeStamp'] is num)
                      ? (aData['timeStamp'] as num).toInt()
                      : 0);
              final bTs = (bData['updatedDate'] is num)
                  ? (bData['updatedDate'] as num).toInt()
                  : ((bData['timeStamp'] is num)
                      ? (bData['timeStamp'] as num).toInt()
                      : 0);
              return bTs.compareTo(aTs);
            });
          return <String, dynamic>{
            'lastSearchList':
                docs.take(100).map((d) => d.id).toList(growable: false),
          };
        });
        final list = searches['lastSearchList'];
        if (list is List) {
          merged['lastSearchList'] = list.map((e) => e.toString()).toList();
        }
      }
    }

    return merged;
  }

  /// Stop Firebase sync
  Future<void> _stopFirebaseSync() async {
    await _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
    _isSyncing = false;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔄 User Updates
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Update current user (internal)
  Future<void> _updateUser(CurrentUserModel user) async {
    final resolvedUser = await _applyStoredViewSelection(user);
    _currentUser = resolvedUser;
    final didPublish = _publishResolvedUser(resolvedUser);
    await UserRepository.ensure().seedCurrentUser(resolvedUser);
    unawaited(_warmAvatar(resolvedUser));
    if (didPublish) {
      await _saveToCache(resolvedUser);
    }
  }

  bool _publishResolvedUser(CurrentUserModel user) {
    viewSelectionRx.value = user.viewSelection;
    final nextSignature = jsonEncode(user.toJson());
    if (_lastReactiveSignature == nextSignature) {
      return false;
    }
    _lastReactiveSignature = nextSignature;
    currentUserRx.value = user;
    _emitUserEvent(user);
    return true;
  }

  Future<void> _warmAvatar(CurrentUserModel? user) async {
    final url = (user?.avatarUrl ?? '').trim();
    if (url.isEmpty) return;
    if (_lastWarmedAvatarUrl == url) return;
    try {
      await TurqImageCacheManager.instance.getSingleFile(url);
      _lastWarmedAvatarUrl = url;
    } catch (_) {}
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
      final requestedViewSelection =
          _extractRequestedViewSelection(normalizedFields);
      if (requestedViewSelection != null) {
        await _persistViewSelection(
          firebaseUser.uid,
          requestedViewSelection,
        );
        await _applyOptimisticLocalPatch({
          'viewSelection': requestedViewSelection,
        });
      }
      // Update Firestore through the central user repository.
      await UserRepository.ensure().updateUserFields(
        firebaseUser.uid,
        normalizedFields,
        mergeIntoCache: false,
      );

      await _applyOptimisticLocalPatch(normalizedFields);
      _purgeUserScopedCaches(firebaseUser.uid);
      if (Get.isRegistered<UserProfileCacheService>()) {
        await Get.find<UserProfileCacheService>().invalidateUser(
          firebaseUser.uid,
        );
      }
    } catch (_) {
      rethrow;
    }
  }

  Future<void> _applyOptimisticLocalPatch(
    Map<String, dynamic> normalizedFields,
  ) async {
    final current = _currentUser;
    if (current == null) return;

    bool isDeleteMarker(dynamic value) => value is FieldValue;

    String stringValue(String key, String fallback) {
      if (!normalizedFields.containsKey(key)) return fallback;
      final raw = normalizedFields[key];
      if (raw == null || isDeleteMarker(raw)) return fallback;
      return raw.toString();
    }

    int intValue(String key, int fallback) {
      if (!normalizedFields.containsKey(key)) return fallback;
      final raw = normalizedFields[key];
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw == null || isDeleteMarker(raw)) return fallback;
      return int.tryParse(raw.toString()) ?? fallback;
    }

    bool boolValue(String key, bool fallback) {
      if (!normalizedFields.containsKey(key)) return fallback;
      final raw = normalizedFields[key];
      if (raw is bool) return raw;
      if (raw == null || isDeleteMarker(raw)) return fallback;
      if (raw is num) return raw != 0;
      return raw.toString().toLowerCase() == 'true';
    }

    String avatarValue() {
      if (!normalizedFields.containsKey('avatarUrl')) return current.avatarUrl;
      final raw = normalizedFields['avatarUrl'];
      if (raw == null || isDeleteMarker(raw)) return current.avatarUrl;
      final trimmed = raw.toString().trim();
      return isDefaultAvatarUrl(trimmed) ? '' : trimmed;
    }

    final patched = current.copyWith(
      firstName: stringValue('firstName', current.firstName),
      lastName: stringValue('lastName', current.lastName),
      nickname: stringValue('nickname', current.nickname),
      avatarUrl: avatarValue(),
      email: stringValue('email', current.email),
      phoneNumber: stringValue('phoneNumber', current.phoneNumber),
      bio: stringValue('bio', current.bio),
      rozet: stringValue(
        'rozet',
        stringValue('badge', current.rozet),
      ),
      viewSelection: intValue('viewSelection', current.viewSelection),
      counterOfFollowers:
          intValue('counterOfFollowers', current.counterOfFollowers),
      counterOfFollowings:
          intValue('counterOfFollowings', current.counterOfFollowings),
      counterOfPosts: intValue('counterOfPosts', current.counterOfPosts),
      counterOfLikes: intValue('counterOfLikes', current.counterOfLikes),
      gizliHesap: boolValue('isPrivate', current.gizliHesap),
      hesapOnayi: boolValue('isApproved', current.hesapOnayi),
    );

    await _updateUser(patched);
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

    // Canonical public profile field (single source of truth: avatarUrl)
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
    if (out.containsKey('avatarUrl')) {
      final normalizedAvatar = (out['avatarUrl'] ?? '').toString().trim();
      out['avatarUrl'] =
          isDefaultAvatarUrl(normalizedAvatar) ? '' : normalizedAvatar;
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
      final data = await ConfigRepository.ensure().getAdminConfigDoc(
            'emailVerify',
            preferCache: true,
            ttl: const Duration(hours: 6),
          ) ??
          const <String, dynamic>{};
      final verifyDay = data['verifyDay'];
      final days = verifyDay is num ? verifyDay.toInt() : 7;
      _emailPromptCooldown = Duration(days: days.clamp(1, 30));
    } catch (e, st) {
      _logSilently('email.verify.config', e, st);
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
            final data = await _readRootUserData(uid, preferCache: true);
            isVerified = data['emailVerified'] == true;
          }
        } catch (e, st) {
          _logSilently('email.verify.root-check', e, st);
        }
      }
      emailVerifiedRx.value = isVerified;
    } catch (e, st) {
      _logSilently('email.verify.refresh', e, st);
      final authVerified =
          FirebaseAuth.instance.currentUser?.emailVerified ?? false;
      if (authVerified) {
        emailVerifiedRx.value = true;
        return;
      }
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null && uid.isNotEmpty) {
          final data = await _readRootUserData(uid, preferCache: true);
          emailVerifiedRx.value = data['emailVerified'] == true;
          return;
        }
      } catch (inner, innerSt) {
        _logSilently('email.verify.fallback-root', inner, innerSt);
      }
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
    } catch (e, st) {
      _logSilently('email.verify.send', e, st);
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
      final oldUid = _currentUser?.userID;
      await _stopFirebaseSync();
      await _clearCache();
      _purgeUserScopedCaches(oldUid);
      if (Get.isRegistered<UserProfileCacheService>()) {
        await Get.find<UserProfileCacheService>().clearAll();
      }
      if (Get.isRegistered<FollowRepository>()) {
        await Get.find<FollowRepository>().clearAll();
      }
      _silentLogAt.clear();

      // Cancel pending cache writes
      _cacheSaveTimer?.cancel();
      _cacheSaveTimer = null;
      _lastCacheSignature = null;
      _lastReactiveSignature = null;
      _lastRootSyncSignature = null;
      _lastWarmedAvatarUrl = null;

      _currentUser = null;
      viewSelectionRx.value = 1;
      currentUserRx.value = null;
      _emitUserEvent(null);

      // 🔥 CRITICAL: Reset initialization flag to allow re-initialization
      _isInitialized = false;
      _isSyncing = false;
      emailVerifiedRx.value = true;
      _lastEmailPromptAt = null;
    } catch (_) {}
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🧹 Cleanup
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  void onClose() {
    _stopFirebaseSync();
    _subdocCache.clear();
    _listCache.clear();
    _silentLogAt.clear();
    _userStreamController.close();
    _instance = null;
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
    if (!kDebugMode) return;
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('CurrentUserService Debug Info:');
    getDebugInfo().forEach((key, value) {
      debugPrint('  $key: $value');
    });
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }
}
