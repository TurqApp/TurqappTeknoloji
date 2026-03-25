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
import 'package:turqappv2/Modules/SignIn/sign_in.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/metadata_cache_policy.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/metadata_read_policy.dart';
import 'package:turqappv2/Core/Repositories/user_subdoc_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Utils/account_status_utils.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/account_session_vault.dart';
import 'package:turqappv2/Services/device_session_service.dart';

import '../Models/current_user_model.dart';

part 'current_user_service_cache_part.dart';
part 'current_user_service_access_part.dart';
part 'current_user_service_account_part.dart';
part 'current_user_service_auth_part.dart';
part 'current_user_service_lifecycle_part.dart';
part 'current_user_service_sync_part.dart';

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
class CurrentUserService extends GetxController with WidgetsBindingObserver {
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🏗️ Singleton Pattern
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static CurrentUserService? _instance;

  static CurrentUserService get instance {
    _instance ??= CurrentUserService._internal();
    return _instance!;
  }

  static CurrentUserService? maybeFind() {
    final isRegistered = Get.isRegistered<CurrentUserService>();
    if (!isRegistered) return null;
    return Get.find<CurrentUserService>();
  }

  static CurrentUserService ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(instance, permanent: permanent);
  }

  CurrentUserService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

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
  String get userId {
    final cached = (_currentUser?.userID ?? '').trim();
    if (cached.isNotEmpty) return cached;
    return effectiveUserId;
  }

  /// Auth fallback dahil efektif kullanıcı ID'si.
  String get effectiveUserId => _performEffectiveUserId();

  User? get currentAuthUser => _performCurrentAuthUser();

  bool get hasAuthUser => _performHasAuthUser();

  String get authUserId => _performAuthUserId();

  String get authEmail => _performAuthEmail();

  String get authDisplayName => _performAuthDisplayName();

  String get effectiveEmail => _performEffectiveEmail();

  String get effectivePhoneNumber => _performEffectivePhoneNumber();

  String get effectiveDisplayName => _performEffectiveDisplayName();

  Stream<User?> authStateChanges() => _performAuthStateChanges();

  Future<User?> resolveAuthUser({
    bool waitForAuthState = false,
    Duration timeout = const Duration(seconds: 3),
  }) =>
      _performResolveAuthUser(
        waitForAuthState: waitForAuthState,
        timeout: timeout,
      );

  Future<User?> reloadCurrentAuthUser() => _performReloadCurrentAuthUser();

  Future<String?> ensureAuthReady({
    bool waitForAuthState = false,
    bool forceTokenRefresh = false,
    Duration timeout = const Duration(seconds: 3),
  }) =>
      _performEnsureAuthReady(
        waitForAuthState: waitForAuthState,
        forceTokenRefresh: forceTokenRefresh,
        timeout: timeout,
      );

  Future<void> refreshAuthTokenIfNeeded({
    bool waitForAuthState = true,
  }) =>
      _performRefreshAuthTokenIfNeeded(
        waitForAuthState: waitForAuthState,
      );

  Future<void> signOutAuth() => _performSignOutAuth();

  Future<void> deleteAuthUserIfPresent() => _performDeleteAuthUserIfPresent();

  /// Current user nickname (shortcut)
  String get nickname => _currentUser?.nickname ?? '';

  String get firstName => _currentUser?.firstName ?? '';

  String get lastName => _currentUser?.lastName ?? '';

  String get rozet => _currentUser?.rozet ?? '';

  String get email => _currentUser?.email ?? '';

  String get phoneNumber => _currentUser?.phoneNumber ?? '';

  String get bio => _currentUser?.bio ?? '';

  String get meslekKategori => _currentUser?.meslekKategori ?? '';

  String get adres => _currentUser?.adres ?? '';

  int get counterOfPosts => _currentUser?.counterOfPosts ?? 0;

  int get counterOfLikes => _currentUser?.counterOfLikes ?? 0;

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
  Timer? _exclusiveSessionHeartbeat;
  static const Duration _exclusiveSessionHeartbeatInterval =
      Duration(seconds: 10);

  static const String _cacheKeyPrefix = 'cached_current_user';
  static const String _cacheTimestampKeyPrefix =
      'cached_current_user_timestamp';
  static const String _activeCacheUidKey = 'cached_current_user_active_uid';
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
  bool _handlingPermanentBan = false;
  bool _handlingSessionDisplacement = false;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🚀 Initialization
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Initialize service (can be called multiple times, e.g., after fresh login)
  ///
  /// Returns true if user loaded from cache/Firebase
  Future<bool> initialize() => _performInitialize();

  /// Force refresh from Firebase (bypasses cache)
  Future<void> forceRefresh() => _performForceRefresh();

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 💾 Cache Management
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔥 Firebase Sync
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Start Firebase realtime sync
  Future<void> _startFirebaseSync() => _performStartFirebaseSync();

  Future<void> _adoptFreshSessionKeyIfNeeded() =>
      _performAdoptFreshSessionKeyIfNeeded();

  void _startExclusiveSessionHeartbeat(String uid) =>
      _performStartExclusiveSessionHeartbeat(uid);

  Future<void> _validateExclusiveSessionFromServer(String uid) =>
      _performValidateExclusiveSessionFromServer(uid);

  Future<Map<String, dynamic>> _buildMergedUserData({
    required String uid,
    required Map<String, dynamic> rootData,
  }) =>
      _performBuildMergedUserData(
        uid: uid,
        rootData: rootData,
      );

  /// Stop Firebase sync
  Future<void> _stopFirebaseSync() => _performStopFirebaseSync();

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔄 User Updates
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Update current user (internal)
  Future<void> _updateUser(CurrentUserModel user) async {
    await _performUpdateUser(user);
  }

  Future<bool> _handlePermanentBanIfNeeded(CurrentUserModel user) async {
    return _performHandlePermanentBanIfNeeded(user);
  }

  Future<bool> _handleExclusiveSessionIfNeeded(
    String uid,
    Map<String, dynamic> data,
  ) async {
    return _performHandleExclusiveSessionIfNeeded(uid, data);
  }

  bool _publishResolvedUser(CurrentUserModel user) {
    return _performPublishResolvedUser(user);
  }

  Future<void> _warmAvatar(CurrentUserModel? user) async {
    await _performWarmAvatar(user);
  }

  Future<void> _signOutToSignIn({
    String initialIdentifier = '',
  }) async {
    await _performSignOutToSignIn(initialIdentifier: initialIdentifier);
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
  bool isUserBlocked(String userId) {
    return _currentUser?.blockedUsers.contains(userId) ?? false;
  }

  bool hasReadStory(String storyId) {
    return _currentUser?.readStories.contains(storyId) ?? false;
  }

  int? getStoryReadTime(String userId) {
    return _currentUser?.readStoriesTimes[userId];
  }

  bool get isVerified => _currentUser?.isVerified ?? false;

  bool get isEmailVerified => emailVerifiedRx.value;

  // Email verification state (Firebase Auth)
  final RxBool emailVerifiedRx = true.obs;
  DateTime? _lastEmailPromptAt;
  Duration _emailPromptCooldown = const Duration(days: 7);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🚪 Logout
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Logout and clear all data
  Future<void> logout() async {
    await _performLogout();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🧹 Cleanup
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  void onClose() {
    _disposeLifecycleResources();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _handleLifecycleStateChange(state);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔍 Debug Info
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
}
