import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_controller.dart';
import 'package:turqappv2/Modules/JobFinder/job_finder_controller.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';

class EducationController extends GetxController {
  final searchController = TextEditingController();
  final searchFocus = FocusNode();
  final isSearchMode = false.obs;
  final searchText = ''.obs;
  final Map<int, String> tabSearchQueries = <int, String>{};
  final isKeyboardOpen = false.obs;
  final selectedTab = 0.obs;
  final pageController = PageController();
  final tabScrollController = ScrollController();
  int _previousTabIndex = 0;
  DateTime _lastNavToggleAt = DateTime.fromMillisecondsSinceEpoch(0);

  final titles = [
    "Burslar",
    "Çöz Geç",
    "Denemeler",
    "Online Sınav",
    "Cevap Anahtarı",
    "Özel Ders",
    "İş Bul",
  ];

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
  }

  @override
  void onClose() {
    if (Get.isRegistered<NavBarController>()) {
      Get.find<NavBarController>().showBar.value = true;
    }
    tabScrollController.dispose();
    searchController.dispose();
    searchFocus.dispose();
    pageController.dispose();
    super.onClose();
  }

  void _syncTabBarPosition(int index, {required bool isForward}) {
    if (!tabScrollController.hasClients) return;
    // Sadece 2 hareket:
    // 1) Sağa kaydırıp 5. sekmeye gelince (index 4) şeridi bir kez kaydır.
    // 2) Sola kaydırıp 4. sekmeye gelince (index 3) şeridi başa al.

    if (!isForward && index == 3) {
      tabScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
      return;
    }

    if (!(isForward && index == 4)) return;

    const tabStep = 120.0;
    const firstShift = tabStep * 4; // 5. sekme sol başa yaklaşsın
    final target = firstShift;
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

  void onTabTap(int index) {
    final isForward = index > _previousTabIndex;
    _previousTabIndex = index;
    selectedTab.value = index;
    pageController.jumpToPage(index);
    _syncTabBarPosition(index, isForward: isForward);
    _restoreSearchForTab(index);
  }

  void onPageChanged(int index) {
    final isForward = index > _previousTabIndex;
    _previousTabIndex = index;
    selectedTab.value = index;
    _syncTabBarPosition(index, isForward: isForward);
    _restoreSearchForTab(index);
  }

  bool get canExitToFeed => selectedTab.value == 0;

  void handleBackFromEducation() {
    if (selectedTab.value == 0) {
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
