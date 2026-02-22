// 📁 lib/Services/current_user_service.dart
// 🎯 Enterprise-grade singleton service for current user management
// 💾 Features: Local cache (SharedPreferences) + Firebase realtime sync
// 🚀 Optimized for: Fast startup, reduced network traffic, reactive updates

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String get pfImage => _currentUser?.pfImage ?? '';

  /// Current user full name (shortcut)
  String get fullName => _currentUser?.fullName ?? '';

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔧 Private Variables
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  SharedPreferences? _prefs;
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;

  static const String _cacheKey = 'cached_current_user';
  static const String _cacheTimestampKey = 'cached_current_user_timestamp';
  static const Duration _cacheExpiration = Duration(days: 7);

  bool _isInitialized = false;
  bool _isSyncing = false;

  // ⚠️ OPTIMIZATION: Debounce cache writes to prevent duplicate saves
  Timer? _cacheSaveTimer;
  String? _lastCachedNickname; // Track last saved user to prevent duplicates

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
        return false;
      }

      // If already initialized and user exists, just ensure sync is running
      if (_isInitialized && _currentUser != null && _currentUser!.userID == firebaseUser.uid) {
        // Same user, ensure Firebase sync is active
        if (!_isSyncing) {
          unawaited(_startFirebaseSync());
        }
        return true;
      }

      // Different user or first init - reload everything
      print('🔄 Initializing CurrentUserService for user: ${firebaseUser.uid}');

      // 1️⃣ Try loading from cache first (FAST - ~10ms)
      final cacheLoaded = await _loadFromCache();

      // 2️⃣ Start Firebase sync in background (await etme — cache yeterli)
      unawaited(_startFirebaseSync());

      _isInitialized = true;
      return cacheLoaded || isLoggedIn;
    } catch (e) {
      print('❌ CurrentUserService initialization error: $e');
      _isInitialized = true;
      return false;
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
        await _updateUser(CurrentUserModel.fromFirestore(doc));
      }
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
        print('⏰ Cache expired (${Duration(milliseconds: cacheAge).inDays} days old)');
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
      // ⚠️ OPTIMIZATION: Skip if same user was just cached
      if (_lastCachedNickname == user.nickname) {
        return;
      }

      // Cancel pending cache write
      _cacheSaveTimer?.cancel();

      // Debounce: Wait 300ms before actually writing
      _cacheSaveTimer = Timer(const Duration(milliseconds: 300), () async {
        try {
          final json = jsonEncode(user.toJson());
          await _prefs?.setString(_cacheKey, json);
          await _prefs?.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
          _lastCachedNickname = user.nickname;
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

              final user = CurrentUserModel.fromFirestore(doc);
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
      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .update(fields);

      print('✅ Fields updated: ${fields.keys.join(', ')}');
    } catch (e) {
      print('❌ Update fields error: $e');
      rethrow;
    }
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
      _lastCachedNickname = null;

      _currentUser = null;
      currentUserRx.value = null;
      _userStreamController.add(null);

      // 🔥 CRITICAL: Reset initialization flag to allow re-initialization
      _isInitialized = false;
      _isSyncing = false;

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
