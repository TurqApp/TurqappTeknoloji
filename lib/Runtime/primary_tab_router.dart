import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';
import 'package:turqappv2/Modules/Profile/Settings/settings_controller.dart';
import 'package:turqappv2/Runtime/app_decision_coordinator.dart';
import 'package:turqappv2/Runtime/startup_decision.dart';

typedef PrimaryTabChangeAction = void Function(int index);
typedef EducationEnabledProvider = bool Function();

class PrimaryTabRouter {
  const PrimaryTabRouter({
    PrimaryTabChangeAction? changeIndex,
    EducationEnabledProvider? educationEnabled,
  })  : _changeIndex = changeIndex,
        _educationEnabled = educationEnabled;

  final PrimaryTabChangeAction? _changeIndex;
  final EducationEnabledProvider? _educationEnabled;

  static int selectedIndexFor(
    StartupPrimaryTab tab, {
    required bool educationEnabled,
  }) {
    switch (tab) {
      case StartupPrimaryTab.feed:
        return 0;
      case StartupPrimaryTab.explore:
        return 1;
      case StartupPrimaryTab.short:
        return 2;
      case StartupPrimaryTab.education:
        return educationEnabled ? 3 : 0;
      case StartupPrimaryTab.profile:
        return educationEnabled ? 4 : 3;
    }
  }

  static int? selectedIndexForDecision(
    StartupDecision decision, {
    required bool educationEnabled,
  }) {
    if (!decision.shouldOpenAuthenticatedHome || decision.primaryTab == null) {
      return null;
    }
    return selectedIndexFor(
      decision.primaryTab!,
      educationEnabled: educationEnabled,
    );
  }

  static String routeHintFor(
    StartupPrimaryTab tab, {
    required bool educationEnabled,
  }) {
    switch (tab) {
      case StartupPrimaryTab.feed:
      case StartupPrimaryTab.short:
        return StartupRouteHint.feed.value;
      case StartupPrimaryTab.explore:
        return StartupRouteHint.explore.value;
      case StartupPrimaryTab.education:
        return educationEnabled
            ? StartupRouteHint.education.value
            : StartupRouteHint.feed.value;
      case StartupPrimaryTab.profile:
        return StartupRouteHint.profile.value;
    }
  }

  static String routeHintForSelectedIndex(
    int index, {
    required bool educationEnabled,
  }) {
    var normalizedIndex = index;
    if (normalizedIndex == 2) normalizedIndex = 0;
    if (normalizedIndex < 0) normalizedIndex = 0;
    if (normalizedIndex > 4) normalizedIndex = 4;

    if (normalizedIndex ==
        selectedIndexFor(
          StartupPrimaryTab.explore,
          educationEnabled: educationEnabled,
        )) {
      return routeHintFor(
        StartupPrimaryTab.explore,
        educationEnabled: educationEnabled,
      );
    }
    if (educationEnabled &&
        normalizedIndex ==
            selectedIndexFor(
              StartupPrimaryTab.education,
              educationEnabled: true,
            )) {
      return routeHintFor(
        StartupPrimaryTab.education,
        educationEnabled: true,
      );
    }
    if (normalizedIndex ==
        selectedIndexFor(
          StartupPrimaryTab.profile,
          educationEnabled: educationEnabled,
        )) {
      return routeHintFor(
        StartupPrimaryTab.profile,
        educationEnabled: educationEnabled,
      );
    }
    return routeHintFor(
      StartupPrimaryTab.feed,
      educationEnabled: educationEnabled,
    );
  }

  bool openPrimaryTab(StartupPrimaryTab tab) {
    if (tab == StartupPrimaryTab.short) {
      return false;
    }
    final hasEducation = _isEducationEnabled();
    final target = selectedIndexFor(tab, educationEnabled: hasEducation);
    _performChangeIndex(target);
    return tab != StartupPrimaryTab.education || hasEducation;
  }

  bool openFeed() => openPrimaryTab(StartupPrimaryTab.feed);

  bool openEducation() => openPrimaryTab(StartupPrimaryTab.education);

  bool _isEducationEnabled() {
    final provider = _educationEnabled;
    if (provider != null) {
      return provider();
    }
    return maybeFindSettingsController()?.educationScreenIsOn.value ?? true;
  }

  void _performChangeIndex(int index) {
    final action = _changeIndex;
    if (action != null) {
      action(index);
      return;
    }
    ensureNavBarController().changeIndex(index);
  }
}
