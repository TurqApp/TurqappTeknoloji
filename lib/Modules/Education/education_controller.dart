import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';
import 'package:turqappv2/Modules/Education/Antreman3/antreman_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/deneme_sinavlari_controller.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/answer_key_controller.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Market/market_controller.dart';
import 'package:turqappv2/Modules/JobFinder/job_finder_controller.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';
import 'package:turqappv2/Modules/Profile/Settings/settings_controller.dart';

class EducationController extends GetxController {
  static EducationController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(EducationController(), permanent: permanent);
  }

  static EducationController? maybeFind() {
    final isRegistered = Get.isRegistered<EducationController>();
    if (!isRegistered) return null;
    return Get.find<EducationController>();
  }

  final searchController = TextEditingController();
  final searchFocus = FocusNode();
  final isSearchMode = false.obs;
  final searchText = ''.obs;
  final Map<int, String> tabSearchQueries = <int, String>{};
  final isKeyboardOpen = false.obs;
  final selectedTab = 0.obs;
  final pageController = PageController();
  final tabScrollController = ScrollController();
  final visibleTabIndexes = List<int>.generate(pasajTabs.length, (i) => i).obs;
  final pasajConfigLoaded = false.obs;
  DateTime _lastNavToggleAt = DateTime.fromMillisecondsSinceEpoch(0);
  final SettingsController settingsController = SettingsController.ensure();
  StreamSubscription<Map<String, dynamic>>? _pasajConfigSub;
  final Map<String, bool> _adminPasajVisibility = <String, bool>{};

  List<String> get titles => pasajTabs;

  @override
  void onInit() {
    super.onInit();
    for (var i = 0; i < titles.length; i++) {
      tabSearchQueries[i] = '';
    }
    searchFocus.addListener(() {
      isKeyboardOpen.value = searchFocus.hasFocus;
      if (searchFocus.hasFocus) {
        isSearchMode.value = true;
      } else {
        isSearchMode.value = false;
      }
    });

    // Arama metnini aktif sekmeye yönlendir
    ever(searchText, (_) => _forwardSearch());
    ever<List<String>>(
        settingsController.pasajOrder, (_) => _recomputeVisibleTabs());
    ever<Map<String, bool>>(
      settingsController.pasajVisibility,
      (_) => _recomputeVisibleTabs(),
    );
    ever<int>(selectedTab, (_) => _suppressBackgroundFeedMedia());
    _bindPasajConfig();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _suppressBackgroundFeedMedia();
    });
  }

  @override
  void onClose() {
    _pasajConfigSub?.cancel();
    NavBarController.maybeFind()?.showBar.value = true;
    tabScrollController.dispose();
    searchController.dispose();
    searchFocus.dispose();
    pageController.dispose();
    super.onClose();
  }

  void _bindPasajConfig() {
    _pasajConfigSub =
        ConfigRepository.ensure().watchAdminConfigDoc('pasaj').listen(
      (snap) {
        final data = snap;
        _adminPasajVisibility.clear();
        for (var i = 0; i < titles.length; i++) {
          final title = titles[i];
          final raw = data[pasajAdminConfigKey(title)];
          final isVisible = raw is bool ? raw : true;
          _adminPasajVisibility[title] = isVisible;
        }
        pasajConfigLoaded.value = true;
        _recomputeVisibleTabs();
      },
      onError: (_) {
        _adminPasajVisibility
          ..clear()
          ..addEntries(titles.map((title) => MapEntry(title, true)));
        pasajConfigLoaded.value = true;
        _recomputeVisibleTabs();
      },
    );
  }

  void _recomputeVisibleTabs() {
    final nextVisible = <int>[];
    for (final title in titles) {
      final adminVisible = _adminPasajVisibility[title] ?? true;
      final localVisible = settingsController.pasajVisibility[title] ?? true;
      if (adminVisible && localVisible) {
        nextVisible.add(titles.indexOf(title));
      }
    }

    visibleTabIndexes.assignAll(nextVisible);
    if (nextVisible.isEmpty) return;

    if (!nextVisible.contains(selectedTab.value)) {
      final firstActual = nextVisible.first;
      selectedTab.value = firstActual;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pageController.hasClients) {
          pageController.jumpToPage(0);
        }
      });
      _restoreSearchForTab(firstActual);
      return;
    }

    final visibleIndex = visibleIndexForActual(selectedTab.value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pageController.hasClients &&
          pageController.page?.round() != visibleIndex) {
        pageController.jumpToPage(visibleIndex);
      }
    });
  }

  int actualIndexForVisible(int visibleIndex) {
    if (visibleIndex < 0 || visibleIndex >= visibleTabIndexes.length) {
      return 0;
    }
    return visibleTabIndexes[visibleIndex];
  }

  int visibleIndexForActual(int actualIndex) {
    final visibleIndex = visibleTabIndexes.indexOf(actualIndex);
    return visibleIndex >= 0 ? visibleIndex : 0;
  }

  bool get hasVisibleTabs => visibleTabIndexes.isNotEmpty;

  void _resetTrackedScrollController(ScrollController? controller) {
    if (controller == null) return;

    void resetNow() {
      if (!controller.hasClients) return;
      try {
        controller.jumpTo(0);
      } catch (_) {}
    }

    resetNow();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      resetNow();
    });
  }

  void resetActivePasajSurfaceToTop() {
    switch (titles[selectedTab.value]) {
      case PasajTabIds.market:
        final market = MarketController.maybeFind();
        if (market != null) {
          _resetTrackedScrollController(market.scrollController);
          market.scrollOffset.value = 0;
        }
        break;
      case PasajTabIds.scholarships:
        final scholarships = ScholarshipsController.maybeFind();
        if (scholarships != null) {
          _resetTrackedScrollController(scholarships.scrollController);
          scholarships.scrollOffset.value = 0;
        }
        break;
      case PasajTabIds.onlineExam:
        final exams = DenemeSinavlariController.maybeFind();
        if (exams != null) {
          _resetTrackedScrollController(exams.scrollController);
          exams.scrollOffset.value = 0;
        }
        break;
      case PasajTabIds.answerKey:
        final answerKey = AnswerKeyController.maybeFind();
        if (answerKey != null) {
          _resetTrackedScrollController(answerKey.scrollController);
          answerKey.scrollOffset.value = 0;
        }
        break;
      case PasajTabIds.tutoring:
        final tutoring = TutoringController.maybeFind();
        if (tutoring != null) {
          _resetTrackedScrollController(tutoring.scrollController);
          tutoring.scrollOffset.value = 0;
        }
        break;
      default:
        break;
    }
  }

  void _syncTabBarPosition(int visibleIndex) {
    if (!tabScrollController.hasClients) return;
    const tabStep = 120.0;
    final target = visibleIndex <= 3 ? 0.0 : tabStep * (visibleIndex - 2);
    final max = tabScrollController.position.maxScrollExtent;
    final clamped = target.clamp(0.0, max);
    tabScrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void onVerticalScrollDirection(ScrollDirection direction) {
    final nav = NavBarController.maybeFind();
    if (nav == null) return;
    if (direction == ScrollDirection.idle) return;

    // Avoid rapid flicker from tiny scroll oscillations.
    final now = DateTime.now();
    if (now.difference(_lastNavToggleAt).inMilliseconds < 120) return;
    _lastNavToggleAt = now;

    if (direction == ScrollDirection.reverse) {
      nav.showBar.value = false; // scrolling down => hide
    } else if (direction == ScrollDirection.forward) {
      nav.showBar.value = true; // scrolling up => show
    }
  }

  bool handleEducationBoundarySwipe(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.horizontal) return false;

    // Yatay hareketlerde tab bar tekrar görünsün.
    final nav = NavBarController.maybeFind();
    if (nav != null && !nav.showBar.value) {
      nav.showBar.value = true;
    }

    // Sadece ilk gorunen sekmede dis gecis davranisina izin ver.
    if (hasVisibleTabs && selectedTab.value == visibleTabIndexes.first) {
      return false;
    }

    // Diğer sekmelerde sınırda oluşan yatay kaydırmayı burada tüket.
    // Böylece son/ilk sekmede swipe feed'e taşmaz.
    if (notification is OverscrollNotification) {
      return true;
    }
    if (notification is ScrollUpdateNotification &&
        notification.metrics.outOfRange) {
      return true;
    }

    return false;
  }

  void onTabTap(int visibleIndex) {
    final actualIndex = actualIndexForVisible(visibleIndex);
    selectedTab.value = actualIndex;
    pageController.jumpToPage(visibleIndex);
    _syncTabBarPosition(visibleIndex);
    _restoreSearchForTab(actualIndex);
    resetActivePasajSurfaceToTop();
    _suppressBackgroundFeedMedia();
  }

  void onPageChanged(int visibleIndex) {
    final actualIndex = actualIndexForVisible(visibleIndex);
    selectedTab.value = actualIndex;
    _syncTabBarPosition(visibleIndex);
    _restoreSearchForTab(actualIndex);
    resetActivePasajSurfaceToTop();
    _suppressBackgroundFeedMedia();
  }

  void _suppressBackgroundFeedMedia() {
    try {
      AgendaController.maybeFind()?.suspendPlaybackForOverlay();
    } catch (_) {}
    try {
      NavBarController.maybeFind()?.pauseGlobalTabMedia();
    } catch (_) {}
  }

  bool get canExitToFeed =>
      hasVisibleTabs && selectedTab.value == visibleTabIndexes.first;

  void handleBackFromEducation() {
    if (!hasVisibleTabs) {
      Get.back();
      return;
    }
    if (selectedTab.value == visibleTabIndexes.first) {
      Get.back();
      return;
    }
    onTabTap(0);
  }

  void clearSearch(BuildContext context) {
    searchFocus.unfocus();
    tabSearchQueries[selectedTab.value] = '';
    searchController.clear();
    searchText.value = '';
    isKeyboardOpen.value = false;
    isSearchMode.value = false;
    _clearModuleSearch(selectedTab.value);
    FocusScope.of(context).unfocus();
  }

  void updateSearchText(String value) {
    tabSearchQueries[selectedTab.value] = value;
    searchText.value = value;
  }

  void _restoreSearchForTab(int tabIndex) {
    final query = tabSearchQueries[tabIndex] ?? '';
    searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    if (query.isEmpty && searchFocus.hasFocus) {
      searchFocus.unfocus();
      isKeyboardOpen.value = false;
      isSearchMode.value = false;
    }
    if (searchText.value != query) {
      searchText.value = query;
    } else {
      _forwardSearch();
    }
  }

  /// Arama metnini aktif sekmenin controller'ına ilet
  void _forwardSearch() {
    final query = searchText.value;
    switch (titles[selectedTab.value]) {
      case PasajTabIds.scholarships:
        ScholarshipsController.maybeFind()?.setSearchQuery(query);
        break;
      case PasajTabIds.jobFinder:
        final jc = JobFinderController.maybeFind();
        if (jc != null) {
          jc.search.text = query;
        }
        break;
      case PasajTabIds.market:
        MarketController.maybeFind()?.setSearchQuery(query);
        break;
      case PasajTabIds.questionBank:
        AntremanController.maybeFind()?.setSearchQuery(query);
        break;
      case PasajTabIds.practiceExams:
        CikmisSorularController.maybeFind()?.setSearchQuery(query);
        break;
      case PasajTabIds.onlineExam:
        DenemeSinavlariController.maybeFind()?.setSearchQuery(query);
        break;
      case PasajTabIds.answerKey:
        AnswerKeyController.maybeFind()?.setSearchQuery(query);
        break;
      case PasajTabIds.tutoring:
        TutoringController.maybeFind()?.setSearchQuery(query);
        break;
    }
  }

  /// Sekme değiştiğinde önceki sekmenin aramasını sıfırla
  void _clearModuleSearch(int tabIndex) {
    switch (titles[tabIndex]) {
      case PasajTabIds.scholarships:
        ScholarshipsController.maybeFind()?.setSearchQuery('');
        break;
      case PasajTabIds.jobFinder:
        JobFinderController.maybeFind()?.search.clear();
        break;
      case PasajTabIds.market:
        MarketController.maybeFind()?.setSearchQuery('');
        break;
      case PasajTabIds.questionBank:
        AntremanController.maybeFind()?.setSearchQuery('');
        break;
      case PasajTabIds.practiceExams:
        CikmisSorularController.maybeFind()?.setSearchQuery('');
        break;
      case PasajTabIds.onlineExam:
        DenemeSinavlariController.maybeFind()?.setSearchQuery('');
        break;
      case PasajTabIds.answerKey:
        AnswerKeyController.maybeFind()?.setSearchQuery('');
        break;
      case PasajTabIds.tutoring:
        TutoringController.maybeFind()?.setSearchQuery('');
        break;
    }
  }
}
