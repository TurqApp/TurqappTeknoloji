import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:svg_flutter/svg.dart';
import 'package:turqappv2/Core/BottomSheets/NoYesAlert.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Core/Buttons/TurqAppToggle.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipsController.dart';
import 'package:turqappv2/Modules/Profile/AboutProfile/AboutProfile.dart';
import 'package:turqappv2/Modules/Profile/Archives/Archives.dart';
import 'package:turqappv2/Modules/Profile/BecomeVerifiedAccount/BecomeVerifiedAccount.dart';
import 'package:turqappv2/Modules/Profile/BlockedUsers/BlockedUsers.dart';
import 'package:turqappv2/Modules/Profile/Cv/Cv.dart';
import 'package:turqappv2/Modules/Profile/EditProfile/EditProfile.dart';
import 'package:turqappv2/Modules/Profile/Interests/Interests.dart';
import 'package:turqappv2/Modules/Profile/LikedPosts/LikedPosts.dart';
import 'package:turqappv2/Modules/Profile/Policies/Policies.dart';
import 'package:turqappv2/Modules/Profile/SavedPosts/SavedPosts.dart';
import 'package:turqappv2/Modules/Profile/Settings/SettingsController.dart';
import 'package:turqappv2/Modules/Profile/SocialMediaLinks/SocialMediaLinks.dart';
import 'package:turqappv2/Modules/SignIn/SignIn.dart';
import 'package:turqappv2/Services/FirebaseMyStore.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Utils/EmptyPadding.dart';
import 'package:turqappv2/Core/Widgets/AppHealthDashboard.dart';
import 'package:turqappv2/Core/Widgets/ErrorReportWidget.dart';
import 'package:turqappv2/Core/Services/ErrorHandlingService.dart';
import 'package:turqappv2/Core/Services/NetworkAwarenessService.dart';
import 'package:turqappv2/Core/Services/UploadQueueService.dart';
import 'package:turqappv2/Core/Services/DraftService.dart';
import 'package:turqappv2/Core/Services/PostEditingService.dart';
import 'package:turqappv2/Core/Services/MediaEnhancementService.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_metrics.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Services/user_analytics_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends StatelessWidget {
  SettingsView({super.key});
  final controller = Get.put(SettingsController());
  final scholarshipsController = Get.put(ScholarshipsController());

  // 🎯 Using CurrentUserService for optimized user data
  final userService = CurrentUserService.instance;
  @Deprecated('Use userService instead')
  final user = Get.put(FirebaseMyStore()); // Backward compatibility
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
                      buildRow("Profili Düzenle", CupertinoIcons.pencil_outline,
                          () {
                        Get.to(() => EditProfile());
                      }),
                      // 🎯 Using CurrentUserService
                      if ((userService.currentUser?.rozet ?? "").isEmpty)
                        buildRow(
                            "Onaylı Hesap Ol", CupertinoIcons.checkmark_seal,
                            () {
                          Get.to(() => BecomeVerifiedAccount());
                        }),
                      // Hesap Gizliliği - Görünüm altına eklendi
                      buildRow("Hesap Gizliliği", CupertinoIcons.lock,
                          () async {
                        // 🎯 Using CurrentUserService.updateFields
                        final currentPrivacy =
                            userService.currentUser?.gizliHesap ?? false;
                        final newValue = !currentPrivacy;
                        try {
                          await userService
                              .updateFields({"gizliHesap": newValue});
                        } catch (e) {
                          // Hata sessizce geçilir; kullanıcı akışı bozulmasın
                        }
                      }),
                      buildRow("Kaydedilenler", CupertinoIcons.bookmark, () {
                        Get.to(() => SavedPosts());
                      }),
                      buildRow("Eğitim Ekranı", CupertinoIcons.nosign, () {
                        controller.toggleEducationScreen();
                      }),
                      buildRow("Sistem ve Tanı Menüsü",
                          CupertinoIcons.antenna_radiowaves_left_right, () {
                        _showSystemDiagnosticsMenu();
                      }),
                      buildRow("Arşiv", CupertinoIcons.refresh_thick, () {
                        Get.to(() => Archives());
                      }),
                      buildRow("Beğenilenler", CupertinoIcons.hand_thumbsup,
                          () {
                        Get.to(() => LikedPosts());
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
                      // buildRow("Burs Ayarları", CupertinoIcons.gear, () {
                      //   scholarshipsController.settings(context);
                      // }),
                      buildRow("Bağlantılar", CupertinoIcons.link, () {
                        Get.to(() => SocialMediaLinks());
                      }),
                      // buildRow("Dil", CupertinoIcons.globe, () {
                      //   Get.to(LangSelector());
                      // }),
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
                      buildRow(
                        "Oturumu Kapat",
                        CupertinoIcons.square_arrow_right,
                        () {
                          noYesAlert(
                            title: "Çıkış Yap",
                            message:
                                "Çıkış yapmak istediğinizden emin misiniz?",
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
                                // 🔥 CRITICAL: Clear CurrentUserService state & cache first
                                await CurrentUserService.instance.logout();

                                // Clear deprecated FirebaseMyStore state
                                Get.find<FirebaseMyStore>().rvesertUserData();

                                // Sign out from Firebase Auth
                                await FirebaseAuth.instance.signOut();

                                // Navigate to sign-in screen
                                await Get.offAll(() => SignIn());
                              } catch (e) {
                                print("Çıkış yapılamadı: $e");
                              }
                            },
                            yesText: "Çıkış Yap",
                            cancelText: "Vazgeç",
                          );
                        },
                      ),
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
            text == "Eğitim Ekranı"
                ? SvgPicture.asset(
                    "assets/icons/sinav.svg",
                    height: 25,
                    color: Colors.black,
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
            else if (text == "Eğitim Ekranı")
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
                leading: const Icon(CupertinoIcons.delete_simple),
                title: const Text("Cache Temizle"),
                onTap: () async {
                  Get.back();
                  if (Get.isRegistered<SegmentCacheManager>()) {
                    await Get.find<SegmentCacheManager>().clearAllCache();
                    AppSnackbar("Tamam", "Cache temizlendi");
                  } else {
                    AppSnackbar("Bilgi", "Cache servisi hazır değil");
                  }
                },
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
