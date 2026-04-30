import 'package:turqappv2/Runtime/startup_decision.dart';

enum StartupRouteHint {
  feed('nav_feed'),
  home('nav_home'),
  explore('nav_explore'),
  profile('nav_profile'),
  education('nav_education'),
  unknown('unknown');

  const StartupRouteHint(this.value);

  final String value;
}

StartupRouteHint startupRouteHintKind(String routeHint) {
  final normalized = routeHint.trim();
  for (final hint in StartupRouteHint.values) {
    if (hint.value == normalized) return hint;
  }
  return StartupRouteHint.unknown;
}

String normalizeStartupRouteHint(String routeHint) {
  return startupRouteHintKind(routeHint).value;
}

bool startupRouteHintRequiresWarmReadiness(String routeHint) {
  switch (startupRouteHintKind(routeHint)) {
    case StartupRouteHint.explore:
    case StartupRouteHint.profile:
    case StartupRouteHint.education:
      return true;
    case StartupRouteHint.feed:
    case StartupRouteHint.home:
    case StartupRouteHint.unknown:
      return false;
  }
}

class StartupDecisionInput {
  const StartupDecisionInput({
    required this.authState,
    this.effectiveUserId = '',
    this.requestedRouteHint = 'unknown',
    this.requestedTab,
    this.educationEnabled = false,
    this.minimumStartupPrepared = false,
    this.authRestoreTimedOut = false,
    this.routeHintIsWarm = true,
  });

  final StartupAuthState authState;
  final String effectiveUserId;
  final String requestedRouteHint;
  final StartupPrimaryTab? requestedTab;
  final bool educationEnabled;
  final bool minimumStartupPrepared;
  final bool authRestoreTimedOut;
  final bool routeHintIsWarm;
}

class AppDecisionCoordinator {
  const AppDecisionCoordinator();

  StartupDecision decideStartup(StartupDecisionInput input) {
    if (input.authState == StartupAuthState.unknown) {
      return StartupDecision(
        authState: StartupAuthState.unknown,
        rootTarget: StartupRootTarget.splash,
        effectiveUserId: input.effectiveUserId.trim(),
        minimumStartupPrepared: input.minimumStartupPrepared,
        degraded: input.authRestoreTimedOut,
        fallbackReason: input.authRestoreTimedOut ? 'auth_restore_pending' : '',
      );
    }

    if (input.authState == StartupAuthState.unauthenticated) {
      return StartupDecision(
        authState: StartupAuthState.unauthenticated,
        rootTarget: StartupRootTarget.signIn,
        effectiveUserId: '',
        minimumStartupPrepared: input.minimumStartupPrepared,
      );
    }

    final resolvedTab = _resolvePrimaryTab(input);
    return StartupDecision(
      authState: StartupAuthState.authenticated,
      rootTarget: StartupRootTarget.authenticatedHome,
      primaryTab: resolvedTab,
      effectiveUserId: input.effectiveUserId.trim(),
      minimumStartupPrepared: input.minimumStartupPrepared,
      degraded: !input.routeHintIsWarm,
      fallbackReason: input.routeHintIsWarm ? '' : 'route_hint_not_warm',
    );
  }

  StartupPrimaryTab _resolvePrimaryTab(StartupDecisionInput input) {
    final requestedTab = input.requestedTab;
    if (requestedTab != null) {
      return _normalizePrimaryTab(
        requestedTab,
        educationEnabled: input.educationEnabled,
      );
    }

    switch (startupRouteHintKind(input.requestedRouteHint)) {
      case StartupRouteHint.explore:
        return StartupPrimaryTab.explore;
      case StartupRouteHint.education:
        return input.educationEnabled
            ? StartupPrimaryTab.education
            : StartupPrimaryTab.feed;
      case StartupRouteHint.profile:
        return StartupPrimaryTab.profile;
      case StartupRouteHint.feed:
      case StartupRouteHint.home:
      case StartupRouteHint.unknown:
        return StartupPrimaryTab.feed;
    }
  }

  StartupPrimaryTab _normalizePrimaryTab(
    StartupPrimaryTab tab, {
    required bool educationEnabled,
  }) {
    if (tab == StartupPrimaryTab.short) {
      return StartupPrimaryTab.feed;
    }
    if (tab == StartupPrimaryTab.education && !educationEnabled) {
      return StartupPrimaryTab.feed;
    }
    return tab;
  }
}
