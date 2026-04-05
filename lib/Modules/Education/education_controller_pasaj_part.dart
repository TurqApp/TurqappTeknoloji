part of 'education_controller.dart';

extension EducationControllerPasajPart on EducationController {
  void _initializeEducationController() {
    for (var i = 0; i < titles.length; i++) {
      tabSearchQueries[i] = '';
    }
    searchFocus.addListener(() {
      isKeyboardOpen.value = searchFocus.hasFocus;
      isSearchMode.value = searchFocus.hasFocus;
    });

    ever(searchText, (_) => _forwardSearch());
    ever<List<String>>(
      settingsController.pasajOrder,
      (_) => _recomputeVisibleTabs(),
    );
    ever<Map<String, bool>>(
      settingsController.pasajVisibility,
      (_) => _recomputeVisibleTabs(),
    );
    ever<int>(selectedTab, (_) {
      _suppressBackgroundFeedMedia();
      unawaited(_persistStartupEducationTabHint());
    });
    _bindPasajConfig();
    unawaited(_loadStartupPreferredTabHint());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _suppressBackgroundFeedMedia();
      unawaited(_persistStartupEducationTabHint());
    });
  }

  void _disposeEducationController() {
    _pasajConfigSub?.cancel();
    _didRunVisibleSurfaceReset = false;
    maybeFindNavBarController()?.showBar.value = true;
    tabScrollController.dispose();
    searchController.dispose();
    searchFocus.dispose();
    pageController.dispose();
  }

  void _bindPasajConfig() {
    _pasajConfigSub =
        ensureConfigRepository().watchAdminConfigDoc('pasaj').listen(
      (snap) {
        _adminPasajVisibility.clear();
        _adminPasajVisibility.addAll(readPasajAdminVisibilitySnapshot(snap));
        pasajConfigLoaded.value = true;
        _recomputeVisibleTabs();
      },
      onError: (_) {
        _adminPasajVisibility
          ..clear()
          ..addAll(normalizePasajVisibilitySnapshot(null));
        pasajConfigLoaded.value = true;
        _recomputeVisibleTabs();
      },
    );
  }

  void _recomputeVisibleTabs() {
    final effectiveVisibility = resolveEffectivePasajVisibilitySnapshot(
      localVisibility: settingsController.pasajVisibility,
      adminVisibility: _adminPasajVisibility,
    );
    final nextVisible = <int>[];
    for (final title in titles) {
      if (effectiveVisibility[title] ?? true) {
        nextVisible.add(titles.indexOf(title));
      }
    }

    visibleTabIndexes.assignAll(nextVisible);
    if (nextVisible.isEmpty) return;

    final preferredActual = _resolveStartupPreferredActualIndex(nextVisible);

    if (!_didApplyStartupPreferredTab &&
        preferredActual != null &&
        preferredActual != selectedTab.value) {
      _didApplyStartupPreferredTab = true;
      selectedTab.value = preferredActual;
      final visibleIndex = visibleIndexForActual(preferredActual);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pageController.hasClients) {
          pageController.jumpToPage(visibleIndex);
        }
      });
      _restoreSearchForTab(preferredActual);
      _primeVisiblePasajSurface(preferredActual);
      return;
    }

    if (!nextVisible.contains(selectedTab.value)) {
      final firstActual = preferredActual ?? nextVisible.first;
      if (preferredActual != null) {
        _didApplyStartupPreferredTab = true;
      }
      selectedTab.value = firstActual;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pageController.hasClients) {
          pageController.jumpToPage(0);
        }
      });
      _restoreSearchForTab(firstActual);
      _primeVisiblePasajSurface(firstActual);
      return;
    }

    final visibleIndex = visibleIndexForActual(selectedTab.value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pageController.hasClients &&
          pageController.page?.round() != visibleIndex) {
        pageController.jumpToPage(visibleIndex);
      }
    });
    _primeVisiblePasajSurface(selectedTab.value);
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

    bool resetNow() {
      if (!controller.hasClients) return false;
      try {
        controller.jumpTo(0);
        return true;
      } catch (_) {}
      return false;
    }

    void scheduleRetry(int attemptsLeft) {
      if (attemptsLeft <= 0) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (resetNow()) return;
        Future<void>.delayed(const Duration(milliseconds: 80), () {
          scheduleRetry(attemptsLeft - 1);
        });
      });
    }

    if (resetNow()) return;
    scheduleRetry(24);
  }

  void _performResetSurfaceForTabTransition() {
    if (titles.isEmpty) return;

    for (final tabIndex in List<int>.from(tabSearchQueries.keys)) {
      tabSearchQueries[tabIndex] = '';
      _clearModuleSearch(tabIndex);
    }
    searchFocus.unfocus();
    searchController.clear();
    searchText.value = '';
    isKeyboardOpen.value = false;
    isSearchMode.value = false;

    if (!hasVisibleTabs) return;
    final firstActual = visibleTabIndexes.first;
    selectedTab.value = firstActual;
    _syncTabBarPosition(0);
    if (pageController.hasClients) {
      pageController.jumpToPage(0);
    }
    _restoreSearchForTab(firstActual);
    resetActivePasajSurfaceToTop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pageController.hasClients) {
        pageController.jumpToPage(0);
      }
      resetActivePasajSurfaceToTop();
    });
  }

  void _ensureVisibleSurfaceResetImpl() {
    if (_didRunVisibleSurfaceReset) return;
    _didRunVisibleSurfaceReset = true;

    void resetSelectedSurface() {
      if (!hasVisibleTabs) return;
      final visibleIndex = visibleIndexForActual(selectedTab.value);
      if (pageController.hasClients &&
          pageController.page?.round() != visibleIndex) {
        pageController.jumpToPage(visibleIndex);
      }
      _syncTabBarPosition(visibleIndex);
      resetActivePasajSurfaceToTop();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      resetSelectedSurface();
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        resetSelectedSurface();
      });
      Future<void>.delayed(const Duration(milliseconds: 260), () {
        resetSelectedSurface();
      });
    });
  }

  void resetActivePasajSurfaceToTop() {
    switch (titles[selectedTab.value]) {
      case PasajTabIds.market:
        final market = maybeFindMarketController();
        if (market != null) {
          _resetTrackedScrollController(market.scrollController);
          market.scrollOffset.value = 0;
        }
        break;
      case PasajTabIds.scholarships:
        final scholarships = maybeFindScholarshipsController();
        if (scholarships != null) {
          _resetTrackedScrollController(scholarships.scrollController);
          scholarships.scrollOffset.value = 0;
        }
        break;
      case PasajTabIds.practiceExams:
        final practiceExams = maybeFindCikmisSorularController();
        if (practiceExams != null) {
          practiceExams.requestScrollReset();
          _resetTrackedScrollController(practiceExams.scrollController);
          practiceExams.scrollOffset.value = 0;
        }
        break;
      case PasajTabIds.onlineExam:
        final exams = maybeFindDenemeSinavlariController();
        if (exams != null) {
          _resetTrackedScrollController(exams.scrollController);
          exams.scrollOffset.value = 0;
        }
        break;
      case PasajTabIds.answerKey:
        final answerKey = maybeFindAnswerKeyController();
        if (answerKey != null) {
          _resetTrackedScrollController(answerKey.scrollController);
          answerKey.scrollOffset.value = 0;
        }
        break;
      case PasajTabIds.tutoring:
        final tutoring = maybeFindTutoringController();
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
    final nav = maybeFindNavBarController();
    if (nav == null || direction == ScrollDirection.idle) return;

    final now = DateTime.now();
    if (now.difference(_lastNavToggleAt).inMilliseconds < 120) return;
    _lastNavToggleAt = now;

    if (direction == ScrollDirection.reverse) {
      nav.showBar.value = false;
    } else if (direction == ScrollDirection.forward) {
      nav.showBar.value = true;
    }
  }

  bool handleEducationBoundarySwipe(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.horizontal) return false;

    final nav = maybeFindNavBarController();
    if (nav != null && !nav.showBar.value) {
      nav.showBar.value = true;
    }

    if (hasVisibleTabs && selectedTab.value == visibleTabIndexes.first) {
      return false;
    }

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
    _primeVisiblePasajSurface(actualIndex);
  }

  void onPageChanged(int visibleIndex) {
    final actualIndex = actualIndexForVisible(visibleIndex);
    selectedTab.value = actualIndex;
    _syncTabBarPosition(visibleIndex);
    _restoreSearchForTab(actualIndex);
    resetActivePasajSurfaceToTop();
    _suppressBackgroundFeedMedia();
    _primeVisiblePasajSurface(actualIndex);
  }

  void _primeVisiblePasajSurface(int actualIndex) {
    if (actualIndex < 0 || actualIndex >= titles.length) return;
    final tabId = titles[actualIndex];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = maybeFindNavBarController();
      final hasEducation = settingsController.educationScreenIsOn.value;
      final educationIndex = hasEducation ? 3 : -1;
      if (nav?.selectedIndex.value != educationIndex) {
        return;
      }
      switch (tabId) {
        case PasajTabIds.market:
          unawaited(maybeFindMarketController()?.onPrimarySurfaceVisible());
          break;
        case PasajTabIds.jobFinder:
          unawaited(maybeFindJobFinderController()?.onPrimarySurfaceVisible());
          break;
      }
    });
  }

  void _suppressBackgroundFeedMedia() {
    final nav = maybeFindNavBarController();
    final hasEducation = settingsController.educationScreenIsOn.value;
    final educationIndex = hasEducation ? 3 : -1;
    if (nav?.selectedIndex.value != educationIndex) {
      return;
    }

    try {
      maybeFindAgendaController()?.suspendPlaybackForOverlay();
    } catch (_) {}
    try {
      nav?.pauseGlobalTabMedia();
    } catch (_) {}
  }

  bool get canExitToFeed =>
      hasVisibleTabs && selectedTab.value == visibleTabIndexes.first;

  void handleBackFromEducation() {
    if (!hasVisibleTabs || selectedTab.value == visibleTabIndexes.first) {
      Get.back();
      return;
    }
    onTabTap(0);
  }

  Future<void> _loadStartupPreferredTabHint() async {
    final uid = CurrentUserService.instance.effectiveUserId.trim();
    if (uid.isEmpty) return;
    try {
      final manifest = await ensureStartupSnapshotManifestStore().load(
        userId: uid,
      );
      final tabId = (manifest?.extra['educationTabId'] ?? '').toString().trim();
      if (!pasajTabs.contains(tabId)) return;
      _startupPreferredTabId = tabId;
      _didApplyStartupPreferredTab = false;
      _recomputeVisibleTabs();
    } catch (_) {}
  }

  int? _resolveStartupPreferredActualIndex(List<int> nextVisible) {
    final tabId = (_startupPreferredTabId ?? '').trim();
    if (tabId.isEmpty) return null;
    final actualIndex = titles.indexOf(tabId);
    if (actualIndex < 0) return null;
    if (!nextVisible.contains(actualIndex)) return null;
    return actualIndex;
  }

  Future<void> _persistStartupEducationTabHint() async {
    final uid = CurrentUserService.instance.effectiveUserId.trim();
    if (uid.isEmpty || !hasVisibleTabs) return;
    final currentIndex = selectedTab.value;
    if (currentIndex < 0 || currentIndex >= titles.length) return;
    final tabId = titles[currentIndex];
    if (tabId.trim().isEmpty) return;
    try {
      await ensureStartupSnapshotManifestStore().updateRouteHint(
        userId: uid,
        routeHint: 'nav_education',
        loggedIn: true,
        extra: <String, dynamic>{
          'educationTabId': tabId,
        },
      );
    } catch (_) {}
  }
}
