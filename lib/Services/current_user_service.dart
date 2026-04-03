import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Helpers/UnreadMessagesController/unread_messages_controller.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Core/Repositories/feed_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Repositories/profile_posts_snapshot_repository.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/metadata_cache_policy.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/metadata_read_policy.dart';
import 'package:turqappv2/Runtime/app_root_navigation_service.dart';
import 'package:turqappv2/Core/Repositories/user_subdoc_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Repositories/short_snapshot_repository.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Services/viewer_surface_invalidation_service.dart';
import 'package:turqappv2/Core/Utils/account_status_utils.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Runtime/startup_session_failure.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/account_session_vault.dart';
import 'package:turqappv2/Services/device_session_service.dart';

import '../Models/current_user_model.dart';

part 'current_user_service_support_part.dart';
part 'current_user_service_auth_role_part.dart';
part 'current_user_service_cache_role_part.dart';
part 'current_user_service_sync_role_part.dart';
part 'current_user_service_account_center_role_part.dart';
part 'current_user_service_cache_part.dart';
part 'current_user_service_access_part.dart';
part 'current_user_service_account_part.dart';
part 'current_user_service_auth_part.dart';
part 'current_user_service_lifecycle_part.dart';
part 'current_user_service_sync_part.dart';

class _CurrentUserServiceState {
  CurrentUserModel? currentUser;
  final Rx<CurrentUserModel?> currentUserRx = Rx<CurrentUserModel?>(null);
  final StreamController<CurrentUserModel?> userStreamController =
      StreamController<CurrentUserModel?>.broadcast();
  final RxInt viewSelectionRx = 1.obs;
}

abstract class _CurrentUserServiceBase extends GetxService
    with WidgetsBindingObserver {
  final _state = _CurrentUserServiceState();

  @override
  void onClose() {
    _handleCurrentUserServiceClose(this as CurrentUserService);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _handleCurrentUserLifecycleState(this as CurrentUserService, state);
  }
}

class CurrentUserService extends _CurrentUserServiceBase {
  static CurrentUserService? _instance;

  static CurrentUserService get instance => _currentUserServiceInstance();

  CurrentUserService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }
}

CurrentUserService _currentUserServiceInstance() {
  CurrentUserService._instance ??= CurrentUserService._internal();
  return CurrentUserService._instance!;
}

CurrentUserService? maybeFindCurrentUserService() {
  final isRegistered = Get.isRegistered<CurrentUserService>();
  if (!isRegistered) return null;
  return Get.find<CurrentUserService>();
}

CurrentUserService ensureCurrentUserService({bool permanent = false}) {
  final existing = maybeFindCurrentUserService();
  if (existing != null) return existing;
  return Get.put(CurrentUserService.instance, permanent: permanent);
}

void _handleCurrentUserServiceClose(CurrentUserService controller) {
  controller._disposeLifecycleResources();
}

void _handleCurrentUserLifecycleState(
  CurrentUserService controller,
  AppLifecycleState state,
) {
  controller._handleLifecycleStateChange(state);
}

extension CurrentUserServiceFieldsPart on CurrentUserService {
  CurrentUserModel? get _currentUser => _state.currentUser;
  set _currentUser(CurrentUserModel? value) => _state.currentUser = value;

  Rx<CurrentUserModel?> get currentUserRx => _state.currentUserRx;

  StreamController<CurrentUserModel?> get _userStreamController =>
      _state.userStreamController;

  Stream<CurrentUserModel?> get userStream => _userStreamController.stream;

  RxInt get viewSelectionRx => _state.viewSelectionRx;
}

extension CurrentUserServiceFacadePart on CurrentUserService {
  String get effectiveUserId => _performEffectiveUserId();

  CurrentUserModel? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  String get userId {
    final cached = (_currentUser?.userID ?? '').trim();
    if (cached.isNotEmpty) return cached;
    return effectiveUserId;
  }

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

  String get avatarUrl {
    final raw = (_currentUser?.avatarUrl ?? '').trim();
    return isDefaultAvatarUrl(raw) ? '' : raw;
  }

  String get fullName => _currentUser?.fullName ?? '';

  int get effectiveViewSelection => viewSelectionRx.value;

  Future<bool> initialize() => _performInitialize();

  Future<void> forceRefresh() => _performForceRefresh();

  Future<void> ensureResolvedCurrentUser({
    required String expectedUid,
    bool reloadEmailVerification = false,
  }) =>
      _performEnsureResolvedCurrentUser(
        expectedUid: expectedUid,
        reloadEmailVerification: reloadEmailVerification,
      );

  Future<void> _validateExclusiveSessionFromServer(String uid) =>
      _performValidateExclusiveSessionFromServer(uid);

  Future<void> _stopFirebaseSync() => _performStopFirebaseSync();

  Future<void> _updateUser(CurrentUserModel user) async {
    await _performUpdateUser(user);
  }

  Future<bool> _handlePermanentBanIfNeeded(CurrentUserModel user) async {
    return _performHandlePermanentBanIfNeeded(user);
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

  bool isUserBlocked(String userId) {
    return _currentUser?.blockedUsers.contains(userId) ?? false;
  }

  bool get isEmailVerified => emailVerifiedRx.value;

  Future<void> logout() async {
    await _performLogout();
  }
}
