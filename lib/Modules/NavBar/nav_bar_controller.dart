import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:async';

import '../Short/short_controller.dart';
import '../Agenda/agenda_controller.dart';
import '../Explore/explore_controller.dart';
import '../Story/StoryRow/story_row_controller.dart';
import '../../Core/Services/ContentPolicy/content_policy.dart';
import '../../Core/Services/upload_queue_service.dart';
import '../../Core/Services/video_state_manager.dart';

typedef TextUpdate = String;

class NavBarController extends GetxController
    with GetTickerProviderStateMixin, WidgetsBindingObserver {
  var selectedIndex = 0.obs;
  var showBar = true.obs;
  ShortController?
      _shortCtrl; // ⚠️ CRITICAL FIX: Make nullable for safe lazy init
  final String fullText = "TurqApp";

  // ⚠️ CRITICAL FIX: Safe getter for ShortController
  ShortController get shortCtrl {
    if (_shortCtrl == null) {
      if (Get.isRegistered<ShortController>()) {
        _shortCtrl = Get.find<ShortController>();
      } else {
        _shortCtrl = Get.put(ShortController());
      }
    }
    return _shortCtrl!;
  }

  late final Rx<AnimationController> typingController;
  late final Rx<AnimationController> deletingController;
  late final Rx<AnimationController> animationController;

  var visibleCharCount = 0.obs;
  var removeCharCount = 0.obs;
  var hideAcilis = false.obs;

  // Upload activity indicator for NavBar profile avatar
  final uploadingPosts = false.obs;

  // ⚠️ CRITICAL FIX: Track disposal state to prevent animation errors
  bool _isDisposed = false;
  bool _proactiveShortPreloadStarted = false;
  Timer? _backgroundCacheTimer;
  Timer? _uploadIndicatorTimer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    // Animation Controllers
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    ).obs;
    animationController.value.repeat();

    typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    ).obs;
    typingController.value.addListener(() {
      visibleCharCount.value =
          (fullText.length * typingController.value.value).floor();
    });

    deletingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    ).obs;
    deletingController.value.addListener(() {
      removeCharCount.value =
          (deletingController.value.value * fullText.length).floor();
    });

    _runAcilisAnimation();
    // Açılış akışını bloklamasın; version kontrolünü gecikmeli başlat.
    Future.delayed(const Duration(seconds: 12), () {
      if (!_isDisposed) {
        checkAppVersion();
      }
    });

    // ⚠️ CRITICAL FIX: Safely initialize ShortController
    try {
      shortCtrl.preloadRange(7);
    } catch (e) {
      print('[NavBar] ShortController preload error: $e');
    }

    _startBackgroundCacheLoop();
    _startUploadIndicatorSync();
  }

  void _startBackgroundCacheLoop() {
    _backgroundCacheTimer?.cancel();
    _backgroundCacheTimer =
        Timer.periodic(const Duration(seconds: 20), (_) async {
      if (_isDisposed) return;
      if (!ContentPolicy.allowBackgroundRefresh(ContentScreenKind.feed)) {
        return;
      }

      try {
        if (Get.isRegistered<AgendaController>()) {
          Get.find<AgendaController>().ensureFeedCacheWarm();
        }
      } catch (_) {}

      try {
        if (Get.isRegistered<ShortController>()) {
          shortCtrl.warmStart(targetCount: 8, maxPages: 2);
        }
      } catch (_) {}

      try {
        if (Get.isRegistered<StoryRowController>()) {
          await Get.find<StoryRowController>().loadStories(
            limit: 30,
            cacheFirst: true,
            silentLoad: true,
          );
        }
      } catch (_) {}
    });
  }

  void _startUploadIndicatorSync() {
    _uploadIndicatorTimer?.cancel();
    _uploadIndicatorTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isDisposed) return;
      if (!Get.isRegistered<UploadQueueService>()) return;
      final queue = Get.find<UploadQueueService>();
      final stats = queue.getQueueStats();
      final pending = (stats['pending'] as int?) ?? 0;
      final processing = (stats['processing'] as bool?) ?? false;
      if (processing || pending > 0) {
        uploadingPosts.value = true;
      }
    });
  }

  Future<void> _runAcilisAnimation() async {
    try {
      // ⚠️ CRITICAL FIX: Check if controller is still alive before animating
      if (!_isDisposed) {
        await typingController.value.forward();
      }
      if (!_isDisposed) {
        await Future.delayed(const Duration(seconds: 1));
      }
      if (!_isDisposed) {
        await deletingController.value.forward();
      }
      if (!_isDisposed) {
        hideAcilis.value = true;
      }
    } catch (e) {
      // Animation was interrupted (controller disposed), silently ignore
      print('[NavBar] Animation interrupted: $e');
    }
  }

  @override
  void onClose() {
    // ⚠️ CRITICAL FIX: Mark as disposed first to stop animations
    _isDisposed = true;

    _backgroundCacheTimer?.cancel();
    _backgroundCacheTimer = null;
    _uploadIndicatorTimer?.cancel();
    _uploadIndicatorTimer = null;
    WidgetsBinding.instance.removeObserver(this);

    // Dispose animation controllers safely
    try {
      typingController.value.dispose();
    } catch (e) {
      print('[NavBar] typingController dispose error: $e');
    }

    try {
      deletingController.value.dispose();
    } catch (e) {
      print('[NavBar] deletingController dispose error: $e');
    }

    try {
      animationController.value.dispose();
    } catch (e) {
      print('[NavBar] animationController dispose error: $e');
    }

    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      try {
        VideoStateManager.instance.pauseAllVideos(force: true);
      } catch (_) {}
      return;
    }

    if (state == AppLifecycleState.resumed && selectedIndex.value == 0) {
      try {
        if (Get.isRegistered<AgendaController>()) {
          Get.find<AgendaController>().resumeFeedPlayback();
        }
      } catch (_) {}
    }
  }

  void changeIndex(int index) {
    final previous = selectedIndex.value;
    selectedIndex.value = index;

    if (previous == 0 && index != 0) {
      try {
        VideoStateManager.instance.pauseAllVideos(force: true);
      } catch (_) {}
    }

    if (index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed) return;
        try {
          if (Get.isRegistered<AgendaController>()) {
            Get.find<AgendaController>().resumeFeedPlayback();
          }
        } catch (_) {}
      });
    }

    if (previous == 1 && index != 1 && Get.isRegistered<ExploreController>()) {
      // Keşfet'ten çıkarken resetle; geri dönünce Gündem ile açılır.
      Get.find<ExploreController>().resetSearchToDefault();
    }
  }

  Future<void> ensureProactiveShortPreloadStarted() async {
    if (_proactiveShortPreloadStarted) return;
    _proactiveShortPreloadStarted = true;
    try {
      await shortCtrl.backgroundPreload();
    } catch (_) {}
  }

  Future<void> checkAppVersion() async {
    try {
      // Debug modda version kontrolünü bypass et
      if (kDebugMode) {
        print("🔧 DEBUG MODE: Version kontrolü bypass edildi");
        return;
      }

      // Mevcut uygulama bilgilerini al
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      print("📱 Cihaz versiyonu: $currentVersion");

      // Firebase'den minimum version bilgilerini al
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("Yönetim")
          .doc("Genel")
          .get();

      String requiredVersion = "";
      if (Platform.isAndroid) {
        requiredVersion = doc.get("androidMinVersion") ?? "";
      } else if (Platform.isIOS) {
        requiredVersion = doc.get("iosMinVersion") ?? "";
      }

      print("🔥 Firebase minimum versiyon: $requiredVersion");

      // Version karşılaştırması yap
      if (requiredVersion.isNotEmpty &&
          _isVersionLower(currentVersion, requiredVersion)) {
        print(
            "⚠️ Güncelleme gerekli: Mevcut $currentVersion < Gerekli $requiredVersion");
        _showUpdateDialog();
      } else {
        print("✅ Version uygun: $currentVersion");
      }
    } catch (e) {
      print("❌ Version kontrolü hatası: $e");
      // Fail-open: ağ/izin/Firestore hatasında kullanıcıyı kilitleme.
    }
  }

  bool _isVersionLower(String currentVersion, String requiredVersion) {
    List<int> current = currentVersion.split('.').map(int.parse).toList();
    List<int> required = requiredVersion.split('.').map(int.parse).toList();

    // Version numaralarını karşılaştır
    for (int i = 0; i < 3; i++) {
      int currentPart = i < current.length ? current[i] : 0;
      int requiredPart = i < required.length ? required[i] : 0;

      if (currentPart < requiredPart) return true;
      if (currentPart > requiredPart) return false;
    }

    return false; // Eşit version
  }

  void _showUpdateDialog() {
    Get.bottomSheet(
      isDismissible: false,
      enableDrag: false,
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle çubuğu
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Güncelleme ikonu
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Container(
                  //   width: 80,
                  //   height: 80,
                  //   decoration: BoxDecoration(
                  //     color: Colors.blue.withValues(alpha: 0.1),
                  //     borderRadius: BorderRadius.circular(40),
                  //   ),
                  //   child: const Icon(
                  //     Icons.system_update,
                  //     size: 40,
                  //     color: Colors.blue,
                  //   ),
                  // ),
                  // 12.pw,
                  Image.asset(
                    "assets/logo/logo.webp",
                    color: Colors.black,
                    height: 80,
                    width: 80,
                  )
                ],
              ),
              const SizedBox(height: 20),

              // Başlık
              const Text(
                "Yeni Güncelleme Mevcut",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: "MontserratBold",
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Açıklama
              const Text(
                "TurqApp'in yeni versiyonu mevcut. Daha iyi performans ve yeni özellikler için lütfen uygulamanızı güncelleyin.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontFamily: "MontserratMedium",
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              30.ph,

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _launchStore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Şimdi Güncelle",
                    style: TextStyle(
                        fontSize: 15,
                        fontFamily: "MontserratMedium",
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Daha sonra butonu
              // SizedBox(
              //   width: double.infinity,
              //   height: 50,
              //   child: TextButton(
              //     onPressed: () => Get.back(),
              //     child: const Text(
              //       "Daha Sonra",
              //       style: TextStyle(
              //         fontSize: 16,
              //         color: Colors.grey,
              //         fontFamily: "MontserratMedium",
              //       ),
              //     ),
              //   ),
              // ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchStore() async {
    String storeUrl = "";

    if (Platform.isAndroid) {
      storeUrl =
          "https://play.google.com/store/apps/details?id=com.turqapp.app";
    } else if (Platform.isIOS) {
      storeUrl = "https://apps.apple.com/tr/app/turqapp/id6740809479?l=tr";
    }

    if (storeUrl.isNotEmpty) {
      final Uri url = Uri.parse(storeUrl);
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        print("Mağaza açma hatası: $e");
        AppSnackbar(
          "Hata",
          "Mağaza açılırken bir hata oluştu",
          backgroundColor: Colors.red.withValues(alpha: 0.7),
        );
      }
    }
  }
}
