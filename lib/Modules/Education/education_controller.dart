import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_controller.dart';
import 'package:turqappv2/Modules/JobFinder/job_finder_controller.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';

class EducationController extends GetxController {
  static const List<String> allTitles = [
    "Burslar",
    "Soru Bankası",
    "Denemeler",
    "Online Sınav",
    "Cevap Anahtarı",
    "Özel Ders",
    "İş Bul",
  ];

  final searchController = TextEditingController();
  final searchFocus = FocusNode();
  final isSearchMode = false.obs;
  final searchText = ''.obs;
  final Map<int, String> tabSearchQueries = <int, String>{};
  final isKeyboardOpen = false.obs;
  final selectedTab = 0.obs;
  final pageController = PageController();
  final tabScrollController = ScrollController();
  final visibleTabIndexes = List<int>.generate(allTitles.length, (i) => i).obs;
  final pasajConfigLoaded = false.obs;
  DateTime _lastNavToggleAt = DateTime.fromMillisecondsSinceEpoch(0);
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _pasajConfigSub;

  List<String> get titles => allTitles;

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
      }
    });

    // Arama metnini aktif sekmeye yönlendir
    ever(searchText, (_) => _forwardSearch());
    _bindPasajConfig();
  }

  @override
  void onClose() {
    _pasajConfigSub?.cancel();
    if (Get.isRegistered<NavBarController>()) {
      Get.find<NavBarController>().showBar.value = true;
    }
    tabScrollController.dispose();
    searchController.dispose();
    searchFocus.dispose();
    pageController.dispose();
    super.onClose();
  }

  void _bindPasajConfig() {
    _pasajConfigSub = FirebaseFirestore.instance
        .collection('adminConfig')
        .doc('pasaj')
        .snapshots()
        .listen(
      (snap) {
        final data = snap.data() ?? const <String, dynamic>{};
        final nextVisible = <int>[];

        for (var i = 0; i < titles.length; i++) {
          final raw = data[titles[i]];
          final isVisible = raw is bool ? raw : true;
          if (isVisible) nextVisible.add(i);
        }

        visibleTabIndexes.assignAll(nextVisible);
        pasajConfigLoaded.value = true;

        if (nextVisible.isEmpty) return;

        if (!nextVisible.contains(selectedTab.value)) {
          final firstActual = nextVisible.first;
          selectedTab.value = firstActual;
          final visibleIndex = 0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (pageController.hasClients) {
              pageController.jumpToPage(visibleIndex);
            }
          });
          _restoreSearchForTab(firstActual);
        } else {
          final visibleIndex = visibleIndexForActual(selectedTab.value);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (pageController.hasClients &&
                pageController.page?.round() != visibleIndex) {
              pageController.jumpToPage(visibleIndex);
            }
          });
        }
      },
      onError: (_) {
        visibleTabIndexes.assignAll(List<int>.generate(titles.length, (i) => i));
        pasajConfigLoaded.value = true;
      },
    );
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
    if (!Get.isRegistered<NavBarController>()) return;
    if (direction == ScrollDirection.idle) return;

    // Avoid rapid flicker from tiny scroll oscillations.
    final now = DateTime.now();
    if (now.difference(_lastNavToggleAt).inMilliseconds < 120) return;
    _lastNavToggleAt = now;

    final nav = Get.find<NavBarController>();
    if (direction == ScrollDirection.reverse) {
      nav.showBar.value = false; // scrolling down => hide
    } else if (direction == ScrollDirection.forward) {
      nav.showBar.value = true; // scrolling up => show
    }
  }

  bool handleEducationBoundarySwipe(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.horizontal) return false;

    // Yatay hareketlerde tab bar tekrar görünsün.
    if (Get.isRegistered<NavBarController>()) {
      final nav = Get.find<NavBarController>();
      if (!nav.showBar.value) {
        nav.showBar.value = true;
      }
    }

    // Sadece Burslar sekmesinde (index 0) dış geçiş davranışına izin ver.
    if (selectedTab.value == 0) {
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
  }

  void onPageChanged(int visibleIndex) {
    final actualIndex = actualIndexForVisible(visibleIndex);
    selectedTab.value = actualIndex;
    _syncTabBarPosition(visibleIndex);
    _restoreSearchForTab(actualIndex);
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
    if (searchText.value != query) {
      searchText.value = query;
    } else {
      _forwardSearch();
    }
  }

  /// Arama metnini aktif sekmenin controller'ına ilet
  void _forwardSearch() {
    final query = searchText.value;
    switch (selectedTab.value) {
      case 0: // Burslar
        if (Get.isRegistered<ScholarshipsController>()) {
          Get.find<ScholarshipsController>().setSearchQuery(query);
        }
        break;
      case 6: // İş Bul
        if (Get.isRegistered<JobFinderController>()) {
          final jc = Get.find<JobFinderController>();
          jc.search.text = query;
        }
        break;
    }
  }

  /// Sekme değiştiğinde önceki sekmenin aramasını sıfırla
  void _clearModuleSearch(int tabIndex) {
    switch (tabIndex) {
      case 0:
        if (Get.isRegistered<ScholarshipsController>()) {
          Get.find<ScholarshipsController>().setSearchQuery('');
        }
        break;
      case 6:
        if (Get.isRegistered<JobFinderController>()) {
          final jc = Get.find<JobFinderController>();
          jc.search.clear();
        }
        break;
    }
  }
}
