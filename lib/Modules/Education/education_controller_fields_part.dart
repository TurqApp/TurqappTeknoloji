part of 'education_controller.dart';

class _EducationControllerState {
  final searchController = TextEditingController();
  final searchFocus = FocusNode();
  final isSearchMode = false.obs;
  final searchText = ''.obs;
  final tabSearchQueries = <int, String>{};
  final isKeyboardOpen = false.obs;
  final selectedTab = 0.obs;
  final pageController = PageController();
  final tabScrollController = ScrollController();
  final visibleTabIndexes = List<int>.generate(pasajTabs.length, (i) => i).obs;
  final pasajConfigLoaded = false.obs;
  DateTime lastNavToggleAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool didRunVisibleSurfaceReset = false;
  final settingsController = ensureSettingsController();
  StreamSubscription<Map<String, dynamic>>? pasajConfigSub;
  final adminPasajVisibility = <String, bool>{};
  String? startupPreferredTabId;
  bool didApplyStartupPreferredTab = false;
}

extension EducationControllerFieldsPart on EducationController {
  TextEditingController get searchController => _state.searchController;
  FocusNode get searchFocus => _state.searchFocus;
  RxBool get isSearchMode => _state.isSearchMode;
  RxString get searchText => _state.searchText;
  Map<int, String> get tabSearchQueries => _state.tabSearchQueries;
  RxBool get isKeyboardOpen => _state.isKeyboardOpen;
  RxInt get selectedTab => _state.selectedTab;
  PageController get pageController => _state.pageController;
  ScrollController get tabScrollController => _state.tabScrollController;
  RxList<int> get visibleTabIndexes => _state.visibleTabIndexes;
  RxBool get pasajConfigLoaded => _state.pasajConfigLoaded;
  DateTime get _lastNavToggleAt => _state.lastNavToggleAt;
  set _lastNavToggleAt(DateTime value) => _state.lastNavToggleAt = value;
  bool get _didRunVisibleSurfaceReset => _state.didRunVisibleSurfaceReset;
  set _didRunVisibleSurfaceReset(bool value) =>
      _state.didRunVisibleSurfaceReset = value;
  SettingsController get settingsController => _state.settingsController;
  StreamSubscription<Map<String, dynamic>>? get _pasajConfigSub =>
      _state.pasajConfigSub;
  set _pasajConfigSub(StreamSubscription<Map<String, dynamic>>? value) =>
      _state.pasajConfigSub = value;
  Map<String, bool> get _adminPasajVisibility => _state.adminPasajVisibility;
  String? get _startupPreferredTabId => _state.startupPreferredTabId;
  set _startupPreferredTabId(String? value) =>
      _state.startupPreferredTabId = value;
  bool get _didApplyStartupPreferredTab => _state.didApplyStartupPreferredTab;
  set _didApplyStartupPreferredTab(bool value) =>
      _state.didApplyStartupPreferredTab = value;
  List<String> get titles => pasajTabs;
}
