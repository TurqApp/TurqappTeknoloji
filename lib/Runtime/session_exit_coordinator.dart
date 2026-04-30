import 'package:turqappv2/Runtime/app_root_navigation_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';

enum SessionExitReason {
  unknown,
  manualLogout,
  accountDeleted,
  accountBanned,
  accountSwitched,
  sessionDisplaced,
}

class SessionExitResult {
  const SessionExitResult({
    required this.reason,
    required this.localSessionCleared,
    required this.authSignedOut,
    required this.navigatedToSignIn,
  });

  final SessionExitReason reason;
  final bool localSessionCleared;
  final bool authSignedOut;
  final bool navigatedToSignIn;
}

typedef SignInNavigationAction = Future<void> Function({
  String initialIdentifier,
  String storedAccountUid,
});

class SessionExitCoordinator {
  const SessionExitCoordinator({
    Future<void> Function()? clearLocalSession,
    Future<void> Function()? signOutAuth,
    SignInNavigationAction? navigateToSignIn,
  })  : _clearLocalSession = clearLocalSession,
        _signOutAuth = signOutAuth,
        _navigateToSignIn = navigateToSignIn;

  final Future<void> Function()? _clearLocalSession;
  final Future<void> Function()? _signOutAuth;
  final SignInNavigationAction? _navigateToSignIn;

  Future<SessionExitResult> exitToSignIn({
    SessionExitReason reason = SessionExitReason.unknown,
    String initialIdentifier = '',
    String storedAccountUid = '',
    bool clearLocalSession = true,
    bool signOutAuth = true,
  }) async {
    var localSessionCleared = false;
    var authSignedOut = false;
    var navigatedToSignIn = false;

    if (clearLocalSession) {
      await (_clearLocalSession ?? CurrentUserService.instance.logout)();
      localSessionCleared = true;
    }

    if (signOutAuth) {
      await (_signOutAuth ?? CurrentUserService.instance.signOutAuth)();
      authSignedOut = true;
    }

    await (_navigateToSignIn ?? AppRootNavigationService.offAllToSignIn)(
      initialIdentifier: initialIdentifier,
      storedAccountUid: storedAccountUid,
    );
    navigatedToSignIn = true;

    return SessionExitResult(
      reason: reason,
      localSessionCleared: localSessionCleared,
      authSignedOut: authSignedOut,
      navigatedToSignIn: navigatedToSignIn,
    );
  }
}
