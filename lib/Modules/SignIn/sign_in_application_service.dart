import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:turqappv2/Core/Helpers/UnreadMessagesController/unread_messages_controller.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/mandatory_follow_service.dart';
import 'package:turqappv2/Core/Utils/email_utils.dart';
import 'package:turqappv2/Core/Utils/stored_account_reauth_policy.dart';
import 'package:turqappv2/Core/notification_service.dart';
import 'package:turqappv2/Models/stored_account.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:turqappv2/Runtime/feature_runtime_services.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/account_session_vault.dart';
import 'package:turqappv2/Services/current_user_service.dart';

typedef _PasswordSignIn = Future<void> Function({
  required String email,
  required String password,
});
typedef _MarkSessionState = Future<void> Function({
  required String uid,
  required bool isSessionValid,
  bool? requiresReauth,
});

class SignInPasswordAttemptResult {
  const SignInPasswordAttemptResult._({
    required this.isSuccess,
    required this.recoveredAfterAuth,
    this.failureCode,
    this.failureMessage,
  });

  const SignInPasswordAttemptResult.success({
    bool recoveredAfterAuth = false,
  }) : this._(
          isSuccess: true,
          recoveredAfterAuth: recoveredAfterAuth,
        );

  const SignInPasswordAttemptResult.authFailure({
    required String code,
    String? message,
  }) : this._(
          isSuccess: false,
          recoveredAfterAuth: false,
          failureCode: code,
          failureMessage: message,
        );

  const SignInPasswordAttemptResult.genericFailure()
      : this._(
          isSuccess: false,
          recoveredAfterAuth: false,
        );

  final bool isSuccess;
  final bool recoveredAfterAuth;
  final String? failureCode;
  final String? failureMessage;
}

class StoredAccountSignInContext {
  const StoredAccountSignInContext({
    required this.account,
    required this.identifier,
  });

  final StoredAccount account;
  final String identifier;
}

class SignInApplicationService {
  SignInApplicationService({
    UserRepository? userRepository,
    CurrentUserService? currentUserService,
    AccountCenterService? accountCenterService,
    AccountSessionVault? accountSessionVault,
    _PasswordSignIn? passwordSignIn,
    String Function()? authUserIdProvider,
    bool Function()? hasAuthUserProvider,
    void Function(String uid)? beginSessionClaim,
    Future<void> Function()? registerCurrentDeviceSession,
    Future<void> Function(String email)? schedulePostAuthTasks,
    Future<AccountSessionCredential?> Function(String uid)?
        readStoredCredential,
    _MarkSessionState? markSessionState,
  })  : _userRepository = userRepository,
        _currentUserService = currentUserService,
        _accountCenterService = accountCenterService,
        _accountSessionVault = accountSessionVault,
        _passwordSignIn = passwordSignIn ?? _defaultPasswordSignIn,
        _authUserIdProvider = authUserIdProvider ??
            (() => CurrentUserService.instance.authUserId),
        _hasAuthUserProvider = hasAuthUserProvider ??
            (() => CurrentUserService.instance.hasAuthUser),
        _beginSessionClaim = beginSessionClaim ??
            const DeviceSessionRuntimeService().beginSessionClaim {
    _registerCurrentDeviceSession = registerCurrentDeviceSession ??
        (() => _ensureAccountCenterService()
            .registerCurrentDeviceSessionIfEnabled());
    _schedulePostAuthTasks =
        schedulePostAuthTasks ?? _defaultSchedulePostAuthTasks;
    _readStoredCredential = readStoredCredential ??
        ((uid) => _ensureAccountSessionVault().read(uid));
    _markSessionState = markSessionState ??
        ({
          required String uid,
          required bool isSessionValid,
          bool? requiresReauth,
        }) =>
            _ensureAccountCenterService().markSessionState(
              uid: uid,
              isSessionValid: isSessionValid,
              requiresReauth: requiresReauth,
            );
  }

  UserRepository? _userRepository;
  CurrentUserService? _currentUserService;
  AccountCenterService? _accountCenterService;
  AccountSessionVault? _accountSessionVault;
  final _PasswordSignIn _passwordSignIn;
  final String Function() _authUserIdProvider;
  final bool Function() _hasAuthUserProvider;
  final void Function(String uid) _beginSessionClaim;
  late final Future<void> Function() _registerCurrentDeviceSession;
  late final Future<void> Function(String email) _schedulePostAuthTasks;
  late final Future<AccountSessionCredential?> Function(String uid)
      _readStoredCredential;
  late final _MarkSessionState _markSessionState;

  UserRepository _ensureUserRepository() {
    return _userRepository ??= UserRepository.ensure();
  }

  CurrentUserService _ensureCurrentUserService() {
    return _currentUserService ??= CurrentUserService.instance;
  }

  AccountCenterService _ensureAccountCenterService() {
    return _accountCenterService ??= ensureAccountCenterService();
  }

  AccountSessionVault _ensureAccountSessionVault() {
    return _accountSessionVault ??= AccountSessionVault.instance;
  }

  Future<SignInPasswordAttemptResult> signInWithPassword({
    required String email,
    required String password,
  }) async {
    var authSucceeded = false;
    try {
      await _passwordSignIn(
        email: email,
        password: password,
      );
      final signedUid = _authUserIdProvider().trim();
      if (signedUid.isNotEmpty) {
        _beginSessionClaim(signedUid);
        try {
          await _registerCurrentDeviceSession();
        } catch (_) {}
      }
      authSucceeded = true;
      await _schedulePostAuthTasks(email);
      return const SignInPasswordAttemptResult.success();
    } on FirebaseAuthException catch (error) {
      return SignInPasswordAttemptResult.authFailure(
        code: error.code,
        message: error.message,
      );
    } catch (_) {
      if (authSucceeded || _hasAuthUserProvider()) {
        return const SignInPasswordAttemptResult.success(
          recoveredAfterAuth: true,
        );
      }
      return const SignInPasswordAttemptResult.genericFailure();
    }
  }

  Future<bool> signInWithStoredAccount(StoredAccount account) async {
    if (!account.hasPasswordProvider) return false;
    await _markSessionState(
      uid: account.uid,
      isSessionValid: false,
      requiresReauth: requiresManualStoredAccountReauth(account),
    );
    return false;
  }

  Future<String> preferredIdentifierForStoredAccount(
      StoredAccount account) async {
    final emailFromAccount = normalizeEmailAddress(account.email);
    if (emailFromAccount.isNotEmpty) return emailFromAccount;
    if (account.hasPasswordProvider) {
      final credential = await _readStoredCredential(account.uid);
      final email = normalizeEmailAddress(credential?.email);
      return email;
    }
    return account.username;
  }

  Future<StoredAccountSignInContext> continueWithStoredAccount(
    StoredAccount account,
  ) async {
    return StoredAccountSignInContext(
      account: account,
      identifier: await preferredIdentifierForStoredAccount(account),
    );
  }

  Future<void> trackCurrentAccountForDevice() async {
    final currentUserService = _ensureCurrentUserService();
    final firebaseUser = currentUserService.currentAuthUser;
    final currentUser = currentUserService.currentUser;
    if (firebaseUser == null) return;
    if (kDebugMode) {
      debugPrint(
        '[AccountCenterTrack] start uid=${firebaseUser.uid} currentUserReady=${currentUser != null}',
      );
    }
    final accountCenterService = _ensureAccountCenterService();
    await accountCenterService.init();
    if (currentUser != null) {
      if (kDebugMode) {
        debugPrint(
          '[AccountCenterTrack] source=currentUser nickname=${currentUser.nickname} uid=${currentUser.userID}',
        );
      }
      await accountCenterService.addCurrentAccount(
        currentUser: currentUser,
        firebaseUser: firebaseUser,
        markSuccessfulSignIn: true,
      );
    } else {
      final summary = await _ensureUserRepository().getUser(
        firebaseUser.uid,
        preferCache: true,
      );
      if (summary != null) {
        if (kDebugMode) {
          debugPrint(
            '[AccountCenterTrack] source=userSummary username=${summary.username} uid=${summary.userID}',
          );
        }
        await accountCenterService.addOrUpdateAccount(
          StoredAccount.fromUserSummary(
            user: summary,
            firebaseUser: firebaseUser,
          ),
          markSuccessfulSignIn: true,
        );
      } else {
        if (kDebugMode) {
          debugPrint(
            '[AccountCenterTrack] source=firebaseUser email=${firebaseUser.email} uid=${firebaseUser.uid}',
          );
        }
        await accountCenterService.addOrUpdateAccount(
          StoredAccount.fromFirebaseUser(firebaseUser),
          markSuccessfulSignIn: true,
        );
      }
    }
    if (kDebugMode) {
      debugPrint(
        '[AccountCenterTrack] done uid=${firebaseUser.uid} accounts=${accountCenterService.accounts.map((e) => e.uid).toList()}',
      );
    }
  }

  Future<void> persistStoredSessionHint({
    String? email,
  }) async {
    final currentUserService = _ensureCurrentUserService();
    final authUser = currentUserService.currentAuthUser;
    final resolvedEmail =
        normalizeEmailAddress(email ?? currentUserService.effectiveEmail);
    if (authUser == null || resolvedEmail.isEmpty) {
      return;
    }
    await _ensureAccountSessionVault().saveEmailHint(
      uid: authUser.uid,
      email: resolvedEmail,
      password: '',
    );
  }

  static Future<void> _defaultPasswordSignIn({
    required String email,
    required String password,
  }) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> _defaultSchedulePostAuthTasks(String email) async {
    unawaited(() async {
      Future<void> runStep(
        String label,
        Future<void> Function() action, {
        Duration timeout = const Duration(seconds: 6),
      }) async {
        try {
          await action().timeout(timeout);
        } catch (error) {
          if (kDebugMode) {
            debugPrint('[SignIn] post-auth step skipped ($label): $error');
          }
        }
      }

      await runStep(
        'refreshEmailVerificationStatus',
        () => _ensureCurrentUserService().refreshEmailVerificationStatus(
          reloadAuthUser: true,
        ),
      );
      unawaited(MandatoryFollowService.instance.enforceForCurrentUser());
      unawaited(_postLoginWarmup());
      await runStep(
        'trackCurrentAccountForDevice',
        trackCurrentAccountForDevice,
      );
      await runStep(
        'registerCurrentDeviceSessionIfEnabled',
        _ensureAccountCenterService().registerCurrentDeviceSessionIfEnabled,
      );
      await runStep(
        'persistStoredSessionHint',
        () => persistStoredSessionHint(email: email),
        timeout: const Duration(seconds: 3),
      );

      try {
        maybeFindUnreadMessagesController()?.startListeners();
      } catch (error) {
        if (kDebugMode) {
          debugPrint('[SignIn] unread listener skipped: $error');
        }
      }
    }());
  }

  Future<void> _postLoginWarmup() async {
    try {
      await Future.any([
        _ensureCurrentUserService().initialize(),
        Future.delayed(const Duration(seconds: 3)),
      ]);
      unawaited(NotificationService.instance.initialize());
      unawaited(_clearSessionCachesAfterAccountSwitch());
      unawaited(_ensureCurrentUserService().forceRefresh());

      try {
        final storyController = maybeFindStoryRowController();
        if (storyController == null) return;
        await Future.any([
          storyController.loadStories(limit: 100, cacheFirst: false),
          Future.delayed(const Duration(seconds: 3)),
        ]);
        if (storyController.users.isEmpty) {
          await storyController.addMyUserImmediately();
        }
      } catch (_) {}

      try {
        final agendaController =
            maybeFindAgendaController() ?? ensureAgendaController();
        await Future.any([
          agendaController.refreshAgenda(),
          Future.delayed(const Duration(seconds: 3)),
        ]);
        if (agendaController.agendaList.isEmpty) {
          unawaited(agendaController.fetchAgendaBigData(initial: true));
        }
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _clearSessionCachesAfterAccountSwitch() async {
    // User switch should preserve global content caches.
    // Warmup methods refresh user-scoped overlays and controllers afterward.
  }

  Future<void> schedulePostAuthTasks(String email) {
    return _schedulePostAuthTasks(email);
  }
}
