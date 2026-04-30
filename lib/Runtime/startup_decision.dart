enum StartupAuthState {
  unknown,
  authenticated,
  unauthenticated,
}

enum StartupRootTarget {
  splash,
  signIn,
  authenticatedHome,
}

enum StartupPrimaryTab {
  feed,
  explore,
  short,
  education,
  profile,
}

class StartupDecision {
  const StartupDecision({
    required this.authState,
    required this.rootTarget,
    this.primaryTab,
    this.effectiveUserId = '',
    this.minimumStartupPrepared = false,
    this.degraded = false,
    this.fallbackReason = '',
  });

  final StartupAuthState authState;
  final StartupRootTarget rootTarget;
  final StartupPrimaryTab? primaryTab;
  final String effectiveUserId;
  final bool minimumStartupPrepared;
  final bool degraded;
  final String fallbackReason;

  bool get shouldStayOnSplash => rootTarget == StartupRootTarget.splash;

  bool get shouldOpenSignIn => rootTarget == StartupRootTarget.signIn;

  bool get shouldOpenAuthenticatedHome =>
      rootTarget == StartupRootTarget.authenticatedHome;

  StartupDecision copyWith({
    StartupAuthState? authState,
    StartupRootTarget? rootTarget,
    StartupPrimaryTab? primaryTab,
    bool clearPrimaryTab = false,
    String? effectiveUserId,
    bool? minimumStartupPrepared,
    bool? degraded,
    String? fallbackReason,
  }) {
    return StartupDecision(
      authState: authState ?? this.authState,
      rootTarget: rootTarget ?? this.rootTarget,
      primaryTab: clearPrimaryTab ? null : primaryTab ?? this.primaryTab,
      effectiveUserId: effectiveUserId ?? this.effectiveUserId,
      minimumStartupPrepared:
          minimumStartupPrepared ?? this.minimumStartupPrepared,
      degraded: degraded ?? this.degraded,
      fallbackReason: fallbackReason ?? this.fallbackReason,
    );
  }
}
