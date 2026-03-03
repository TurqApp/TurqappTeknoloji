import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:svg_flutter/svg.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_toggle.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_controller.dart';
import 'package:turqappv2/Modules/Profile/AboutProfile/about_profile.dart';
import 'package:turqappv2/Modules/Profile/Archives/archives.dart';
import 'package:turqappv2/Modules/Profile/BecomeVerifiedAccount/become_verified_account.dart';
import 'package:turqappv2/Modules/Profile/BlockedUsers/blocked_users.dart';
import 'package:turqappv2/Modules/Profile/Cv/cv.dart';
import 'package:turqappv2/Modules/Profile/EditProfile/edit_profile.dart';
import 'package:turqappv2/Modules/Profile/Interests/interests.dart';
import 'package:turqappv2/Modules/Profile/LikedPosts/liked_posts.dart';
import 'package:turqappv2/Modules/Profile/Policies/policies.dart';
import 'package:turqappv2/Modules/Profile/SavedPosts/saved_posts.dart';
import 'package:turqappv2/Modules/Profile/Settings/settings_controller.dart';
import 'package:turqappv2/Modules/Profile/Settings/permissions_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/admin_push_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/notification_settings_view.dart';
import 'package:turqappv2/Modules/SignIn/sign_in.dart';
import 'package:turqappv2/Services/firebase_my_store.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:turqappv2/Core/Widgets/app_health_dashboard.dart';
import 'package:turqappv2/Core/Widgets/error_report_widget.dart';
import 'package:turqappv2/Core/Services/error_handling_service.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';
import 'package:turqappv2/Core/Services/upload_queue_service.dart';
import 'package:turqappv2/Core/Services/draft_service.dart';
import 'package:turqappv2/Core/Services/post_editing_service.dart';
import 'package:turqappv2/Core/Services/media_enhancement_service.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_metrics.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Services/user_analytics_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends StatelessWidget {
  SettingsView({super.key});
  static const Set<String> _adminUserIds = {
    "jp4ZnrD0CpX7VYkDNTGHeZvgwYA2",
    "hiv3UzAABlRWJaePerm3mtPEolI3",
  };
  static const Set<String> _adminNicknames = {
    "osmannafiz",
    "turqapp",
  };
  final controller = Get.put(SettingsController());
  final scholarshipsController = Get.put(ScholarshipsController());

  // 🎯 Using CurrentUserService for optimized user data
  final userService = CurrentUserService.instance;
  @Deprecated('Use userService instead')
  final user = Get.put(FirebaseMyStore()); // Backward compatibility

  bool get _isDiagnosticsAdmin {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final currentNickname = userService.nickname.trim().toLowerCase();
    return _adminUserIds.contains(currentUid) ||
        _adminNicknames.contains(currentNickname);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Ayarlar"),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      buildSectionTitle("Hesap"),
                      buildRow("Profili Düzenle", CupertinoIcons.pencil_outline,
                          () {
                        Get.to(() => EditProfile());
                      }),
                      if ((userService.currentUser?.rozet ?? "").isEmpty)
                        buildRow(
                            "Onaylı Hesap Ol", CupertinoIcons.checkmark_seal,
                            () {
                          Get.to(() => BecomeVerifiedAccount());
                        }),
                      buildRow("Hesap Gizliliği", CupertinoIcons.lock,
                          () async {
                        final currentPrivacy =
                            userService.currentUser?.gizliHesap ?? false;
                        final newValue = !currentPrivacy;
                        try {
                          await userService
                              .updateFields({"gizliHesap": newValue});
                        } catch (e) {}
                      }),
                      buildRow(
                        "Engellenenler",
                        CupertinoIcons.exclamationmark_circle,
                        () {
                          Get.to(() => BlockedUsers());
                        },
                      ),
                      buildRow("İlgi Alanları", CupertinoIcons.sparkles, () {
                        Get.to(() => Interests());
                      }),
                      buildRow("Özgeçmiş (Cv)", CupertinoIcons.paperclip, () {
                        Get.to(() => Cv());
                      }),
                      buildSectionTitle("İçerik"),
                      buildRow("Kaydedilenler", CupertinoIcons.bookmark, () {
                        Get.to(() => SavedPosts());
                      }),
                      buildRow("Arşiv", CupertinoIcons.refresh_thick, () {
                        Get.to(() => Archives());
                      }),
                      buildRow("Beğenilenler", CupertinoIcons.hand_thumbsup,
                          () {
                        Get.to(() => LikedPosts());
                      }),
                      buildSectionTitle("Uygulama"),
                      buildRow("Bildirimler", CupertinoIcons.bell, () {
                        Get.to(() => const NotificationSettingsView());
                      }),
                      buildRow("İzinler", CupertinoIcons.lock_shield, () {
                        Get.to(() => const PermissionsView());
                      }),
                      buildRow("Eğitim", CupertinoIcons.nosign, () {
                        controller.toggleEducationScreen();
                      }),
                      buildSectionTitle("Güvenlik ve Destek"),
                      buildRow("Hakkında", CupertinoIcons.info, () {
                        Get.to(
                          () => AboutProfile(
                            userID: FirebaseAuth.instance.currentUser!.uid,
                          ),
                        );
                      }),
                      buildRow("Politikalar", CupertinoIcons.shield, () {
                        Get.to(() => Policies());
                      }),
                      buildRow("Bize Yazın", CupertinoIcons.pencil_circle, () {
                        launchUrl(Uri.parse('mailto:info@turqapp.com'));
                      }),
                      if (_isDiagnosticsAdmin) ...[
                        buildSectionTitle("Sistem ve Tanı"),
                        buildRow(
                          "Sistem ve Tanı Menüsü",
                          CupertinoIcons.antenna_radiowaves_left_right,
                          () {
                            _showSystemDiagnosticsMenu();
                          },
                        ),
                        _AdminPushMenuTile(buildRow: buildRow),
                      ],
                      buildSectionTitle("Oturum"),
                      buildRow(
                          "Oturumu Kapat", CupertinoIcons.square_arrow_right,
                          () {
                        noYesAlert(
                          title: "Çıkış Yap",
                          message: "Çıkış yapmak istediğinizden emin misiniz?",
                          onYesPressed: () async {
                            final currentUser =
                                FirebaseAuth.instance.currentUser?.uid;
                            if (currentUser != null) {
                              await FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(currentUser)
                                  .update({"token": ""});
                            }

                            try {
                              await CurrentUserService.instance.logout();
                              Get.find<FirebaseMyStore>().rvesertUserData();
                              await FirebaseAuth.instance.signOut();
                              await Get.offAll(() => SignIn());
                            } catch (e) {
                              print("Çıkış yapılamadı: $e");
                            }
                          },
                          yesText: "Çıkış Yap",
                          cancelText: "Vazgeç",
                        );
                      }),
                      15.ph,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRow(String text, IconData icon, VoidCallback onTap,
      {bool isNew = false}) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            text == "Eğitim"
                ? SvgPicture.asset(
                    "assets/icons/sinav.svg",
                    height: 25,
                    colorFilter:
                        const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                  )
                : Icon(icon, size: 25, color: Colors.black),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),

            // Sağ taraf
            if (text == "Dil")
              Text(
                "Türkçe",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              )
            else if (text == "Eğitim")
              Obx(() {
                return TurqAppToggle(
                  isOn: controller.educationScreenIsOn.value,
                );
              })
            else if (text == "Hesap Gizliliği")
              // 🎯 Using CurrentUserService reactive
              Obx(() {
                return TurqAppToggle(
                  isOn: userService.currentUserRx.value?.gizliHesap ?? false,
                );
              })
            else ...[
              if (isNew) ...[
                SizedBox(width: 6),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    "Yeni",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ),
              ],
              Icon(CupertinoIcons.chevron_right, color: Colors.grey, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 2),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 13,
              fontFamily: "MontserratBold",
            ),
          ),
        ],
      ),
    );
  }

  void _showDataUsageDialog() {
    if (!Get.isRegistered<NetworkAwarenessService>()) {
      Get.put(NetworkAwarenessService());
    }

    final networkService = Get.find<NetworkAwarenessService>();
    final stats = networkService.getNetworkStats();
    final usage = networkService.dataUsage;
    final now = DateTime.now();
    final resetStart = usage.lastReset;
    final resetHours =
        (now.difference(resetStart).inMinutes / 60).clamp(1.0, 99999.0);
    final monthlyTotalMB = (stats['monthlyUsageMB'] as num?)?.toDouble() ?? 0.0;
    final monthlyAvgPerHour = monthlyTotalMB / resetHours;
    final hasCache = Get.isRegistered<SegmentCacheManager>();
    final cacheEntryCount =
        hasCache ? Get.find<SegmentCacheManager>().entryCount : 0;
    final cacheSizeText = hasCache
        ? CacheMetrics.formatBytes(
            Get.find<SegmentCacheManager>().totalSizeBytes)
        : "Bilinmiyor";
    final lastSignIn =
        FirebaseAuth.instance.currentUser?.metadata.lastSignInTime;
    final loginDate = lastSignIn == null
        ? "Bilinmiyor"
        : "${lastSignIn.day.toString().padLeft(2, '0')}.${lastSignIn.month.toString().padLeft(2, '0')}.${lastSignIn.year}";
    final loginTime = lastSignIn == null
        ? "Bilinmiyor"
        : "${lastSignIn.hour.toString().padLeft(2, '0')}:${lastSignIn.minute.toString().padLeft(2, '0')}";
    final loginHours = lastSignIn == null
        ? 0.0
        : (now.difference(lastSignIn).inMinutes / 60).clamp(1.0, 99999.0);
    final sinceLoginEstimatedTotal = lastSignIn == null
        ? 0.0
        : (monthlyAvgPerHour * loginHours).clamp(0.0, monthlyTotalMB);
    final sinceLoginAvgPerHour = lastSignIn == null
        ? 0.0
        : (sinceLoginEstimatedTotal / loginHours).clamp(0.0, monthlyAvgPerHour);

    Get.dialog(
      AlertDialog(
        title: const Text("Veri Tüketimi"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ağ: ${stats['currentNetwork']}"),
            Text("Bağlı: ${stats['isConnected']}"),
            Text(
              "Aylık Toplam: ${stats['monthlyUsageMB']} MB",
            ),
            Text("Aylık Limit: ${stats['monthlyLimitMB']} MB"),
            Text("Kalan: ${stats['remainingMB']} MB"),
            Text(
              "Limit Kullanımı: ${stats['dataUsagePercentage'].toStringAsFixed(1)}%",
            ),
            Text("Wi-Fi Tüketimi: ${stats['wifiUsageMB']} MB"),
            Text("Mobil Tüketim: ${stats['cellularUsageMB']} MB"),
            const SizedBox(height: 8),
            const Text(
              "Zaman Aralıkları",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "1) Bu Ay (Gerçek): ${monthlyTotalMB.toStringAsFixed(1)} MB",
            ),
            Text(
              "Ortalama Saatlik: ${monthlyAvgPerHour.toStringAsFixed(2)} MB/saat",
            ),
            Text(
              "2) Son Girişten Beri (Yaklaşık): ${sinceLoginEstimatedTotal.toStringAsFixed(1)} MB",
            ),
            Text(
              "Ortalama Saatlik: ${sinceLoginAvgPerHour.toStringAsFixed(2)} MB/saat",
            ),
            const SizedBox(height: 8),
            const Text(
              "Detay",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("Upload: ${usage.uploadedMB} MB"),
            Text("Download: ${usage.downloadedMB} MB"),
            const SizedBox(height: 8),
            const Text(
              "Cache",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("Kayıtlı Medya Sayısı: $cacheEntryCount"),
            Text("Kaplanan Alan: $cacheSizeText"),
            const SizedBox(height: 8),
            Text("Giriş Tarihi: $loginDate"),
            Text("Giriş Saati: $loginTime"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Kapat"),
          ),
        ],
      ),
    );
  }

  void _ensureDiagnosticsServices() {
    if (!Get.isRegistered<SettingsController>()) {
      Get.put(SettingsController());
    }
    if (!Get.isRegistered<ErrorHandlingService>()) {
      Get.put(ErrorHandlingService());
    }
    if (!Get.isRegistered<NetworkAwarenessService>()) {
      Get.put(NetworkAwarenessService());
    }
    if (!Get.isRegistered<UploadQueueService>()) {
      Get.put(UploadQueueService());
    }
    if (!Get.isRegistered<DraftService>()) {
      Get.put(DraftService());
    }
    if (!Get.isRegistered<PostEditingService>()) {
      Get.put(PostEditingService());
    }
    if (!Get.isRegistered<MediaEnhancementService>()) {
      Get.put(MediaEnhancementService());
    }
  }

  void _showSystemDiagnosticsMenu() {
    _ensureDiagnosticsServices();
    UserAnalyticsService.instance.trackFeatureUsage('diagnostics_menu_open');

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Wrap(
            children: [
              const ListTile(
                title: Text(
                  "Sistem ve Tanı Menüsü",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading:
                    const Icon(CupertinoIcons.antenna_radiowaves_left_right),
                title: const Text("Veri Tüketimi"),
                onTap: () {
                  Get.back();
                  _showDataUsageDialog();
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.chart_bar),
                title: const Text("Uygulama Sağlık Paneli"),
                onTap: () {
                  Get.back();
                  Get.to(() => const AppHealthDashboard());
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.play_rectangle),
                title: const Text("Video Cache Detayı"),
                onTap: () {
                  Get.back();
                  _showVideoCacheDetails();
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.bolt_horizontal_circle),
                title: const Text("Hızlı Aksiyonlar"),
                onTap: () {
                  Get.back();
                  _showQuickActions();
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.exclamationmark_bubble),
                title: const Text("Son Hata Özeti"),
                onTap: () {
                  Get.back();
                  _showLastErrorSummary();
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.exclamationmark_triangle),
                title: const Text("Hata Raporu"),
                onTap: () {
                  Get.back();
                  Get.to(() => const ErrorReportWidget());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVideoCacheDetails() {
    final hasCache = Get.isRegistered<SegmentCacheManager>();
    final hasPrefetch = Get.isRegistered<PrefetchScheduler>();
    final cache = hasCache ? Get.find<SegmentCacheManager>() : null;
    final prefetch = hasPrefetch ? Get.find<PrefetchScheduler>() : null;

    final metrics = cache?.metrics.toJson() ?? {};
    final hitRate = (metrics['cacheHitRate'] ?? '0.0%').toString();

    Get.dialog(
      AlertDialog(
        title: const Text("Video Cache Detayı"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Kayıtlı Video: ${cache?.entryCount ?? 0}"),
            Text("Kayıtlı Segment: ${cache?.totalSegmentCount ?? 0}"),
            Text(
              "Disk Kullanımı: ${cache == null ? 'Bilinmiyor' : CacheMetrics.formatBytes(cache.totalSizeBytes)}",
            ),
            const SizedBox(height: 8),
            const Text("Cache Trafiği",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Hit Oranı: $hitRate"),
            Text("Hit: ${metrics['cacheHits'] ?? 0}"),
            Text("Miss: ${metrics['cacheMisses'] ?? 0}"),
            Text("Cache Servis: ${metrics['bytesServedFromCache'] ?? '0B'}"),
            Text("Ağdan İndirilen: ${metrics['bytesDownloaded'] ?? '0B'}"),
            const SizedBox(height: 8),
            const Text("Prefetch",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Kuyruk: ${prefetch?.queueSize ?? 0}"),
            Text("Aktif İndirme: ${prefetch?.activeDownloads ?? 0}"),
            Text(
                "Durum: ${(prefetch?.isPaused ?? true) ? 'Duraklatılmış' : 'Aktif'}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Kapat"),
          ),
        ],
      ),
    );
  }

  void _showQuickActions() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Wrap(
            children: [
              const ListTile(
                title: Text(
                  "Hızlı Aksiyonlar",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.arrow_counterclockwise),
                title: const Text("Veri Sayaçlarını Sıfırla"),
                onTap: () async {
                  Get.back();
                  await Get.find<NetworkAwarenessService>().resetDataUsage();
                  AppSnackbar("Tamam", "Veri sayaçları sıfırlandı");
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.pause_circle),
                title: const Text("Prefetch Duraklat"),
                onTap: () {
                  Get.back();
                  if (Get.isRegistered<PrefetchScheduler>()) {
                    Get.find<PrefetchScheduler>().pause();
                    AppSnackbar("Tamam", "Prefetch duraklatıldı");
                  } else {
                    AppSnackbar("Bilgi", "Prefetch servisi hazır değil");
                  }
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.play_circle),
                title: const Text("Prefetch Devam Et"),
                onTap: () {
                  Get.back();
                  if (Get.isRegistered<PrefetchScheduler>()) {
                    Get.find<PrefetchScheduler>().resume();
                    AppSnackbar("Tamam", "Prefetch devam ediyor");
                  } else {
                    AppSnackbar("Bilgi", "Prefetch servisi hazır değil");
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLastErrorSummary() {
    final errorService = Get.find<ErrorHandlingService>();
    final last = errorService.getLastErrorSummary();

    Get.dialog(
      AlertDialog(
        title: const Text("Son Hata Özeti"),
        content: last == null
            ? const Text("Kayıtlı hata bulunmuyor.")
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Kod: ${last['code']}"),
                  Text("Kategori: ${last['category']}"),
                  Text("Seviye: ${last['severity']}"),
                  Text("Tekrar Denenebilir: ${last['retryable']}"),
                  Text("Mesaj: ${last['userFriendlyMessage']}"),
                  Text("Zaman: ${last['timestamp']}"),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Kapat"),
          ),
        ],
      ),
    );
  }
}

class _AdminPushMenuTile extends StatelessWidget {
  const _AdminPushMenuTile({required this.buildRow});

  static const Set<String> _adminUserIds = {
    "jp4ZnrD0CpX7VYkDNTGHeZvgwYA2",
    "hiv3UzAABlRWJaePerm3mtPEolI3",
  };
  static const Set<String> _adminNicknames = {
    "osmannafiz",
    "turqapp",
  };

  final Widget Function(String, IconData, VoidCallback, {bool isNew}) buildRow;

  Future<bool> _canShowAdminPushMenu() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    final currentNickname =
        CurrentUserService.instance.nickname.trim().toLowerCase();
    final isKnownAdmin = _adminUserIds.contains(currentUser.uid) ||
        _adminNicknames.contains(currentNickname);
    if (!isKnownAdmin) return false;

    final token = await currentUser.getIdTokenResult(true);
    final isAdmin = token.claims?["admin"] == true;
    if (!isAdmin && !_adminNicknames.contains(currentNickname)) return false;

    final adminCfg =
        await FirebaseFirestore.instance.doc("adminConfig/admin").get();
    final data = adminCfg.data() ?? <String, dynamic>{};
    return data["pushSend"] == true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canShowAdminPushMenu(),
      builder: (context, snapshot) {
        if (snapshot.data != true) {
          return const SizedBox.shrink();
        }
        return buildRow(
          "Yönetim / Push Gönder",
          CupertinoIcons.paperplane,
          () => Get.to(() => const AdminPushView()),
        );
      },
    );
  }
}
