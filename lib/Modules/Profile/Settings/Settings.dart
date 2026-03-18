import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Core/Repositories/admin_approval_repository.dart';
import 'package:turqappv2/Core/Repositories/admin_task_assignment_repository.dart';
import 'package:turqappv2/Core/Repositories/verified_account_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
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
import 'package:turqappv2/Modules/Profile/Settings/admin_approvals_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/admin_task_assignments_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/my_admin_approval_results_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_home_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/account_center_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/badge_admin_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/moderation_settings_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/notification_settings_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/pasaj_settings_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/reports_admin_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/story_music_admin_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/support_admin_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/support_contact_view.dart';
import 'package:turqappv2/Modules/SignIn/sign_in.dart';
import 'package:turqappv2/Services/account_center_service.dart';
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
import 'package:turqappv2/Services/offline_mode_service.dart';
import 'package:turqappv2/Services/user_analytics_service.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/admin_task_catalog.dart';

class SettingsView extends StatelessWidget {
  SettingsView({super.key});
  final controller = Get.put(SettingsController());
  final scholarshipsController = Get.put(ScholarshipsController());
  final UserRepository _userRepository = UserRepository.ensure();
  final VerifiedAccountRepository _verifiedAccountRepository =
      VerifiedAccountRepository.ensure();
  final AdminTaskAssignmentRepository _adminTaskAssignmentRepository =
      AdminTaskAssignmentRepository.ensure();
  final AdminApprovalRepository _adminApprovalRepository =
      AdminApprovalRepository.ensure();

  // 🎯 Using CurrentUserService for optimized user data
  final userService = CurrentUserService.instance;

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
                      FutureBuilder<VerifiedAccountApplicationState?>(
                        future:
                            _verifiedAccountRepository.fetchApplicationState(
                          FirebaseAuth.instance.currentUser?.uid ?? '',
                        ),
                        builder: (context, snapshot) {
                          final application = snapshot.data;
                          final hasPendingApplication =
                              application?.isPending == true;
                          final canRenew =
                              application?.canSubmitRenewal == true;
                          final hasBadge =
                              (userService.currentUser?.rozet ?? "").isNotEmpty;
                          if (hasPendingApplication) {
                            return buildRow(
                              "Rozet Başvurum",
                              CupertinoIcons.doc_text_search,
                              () {
                                Get.to(() => BecomeVerifiedAccount());
                              },
                            );
                          }
                          if (canRenew) {
                            return buildRow(
                              "Rozeti Yenile",
                              CupertinoIcons.arrow_clockwise_circle,
                              () {
                                Get.to(() => BecomeVerifiedAccount());
                              },
                            );
                          }
                          if (!hasBadge) {
                            return buildRow(
                              "Onaylı Hesap Ol",
                              CupertinoIcons.checkmark_seal,
                              () {
                                Get.to(() => BecomeVerifiedAccount());
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
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
                      buildRow(
                        "Hesap Merkezi",
                        CupertinoIcons.person_2_square_stack,
                        () {
                          Get.to(() => AccountCenterView());
                        },
                      ),
                      buildRow("Kariyer Profili", CupertinoIcons.paperclip, () {
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
                      buildRow("Pasaj", CupertinoIcons.nosign, () {
                        Get.to(() => PasajSettingsView());
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
                        Get.to(() => const SupportContactView());
                      }),
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: _adminTaskAssignmentRepository.watchAssignment(
                          FirebaseAuth.instance.currentUser?.uid ?? '',
                        ),
                        builder: (context, taskSnap) {
                          final data = taskSnap.data?.data();
                          final taskIds = normalizeAdminTaskIds(
                            data?['taskIds'] is List
                                ? data!['taskIds'] as List
                                : const [],
                          );
                          if (taskIds.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            children: [
                              buildSectionTitle("Görevlerim"),
                              ..._buildAssignedTaskRows(taskIds),
                              StreamBuilder<
                                  QuerySnapshot<Map<String, dynamic>>>(
                                stream:
                                    _adminApprovalRepository.watchOwnApprovals(
                                  FirebaseAuth.instance.currentUser?.uid ?? '',
                                ),
                                builder: (context, approvalsSnap) {
                                  final docs =
                                      approvalsSnap.data?.docs ?? const [];
                                  if (docs.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return buildRow(
                                    "Onay Sonuçlarım",
                                    CupertinoIcons.checkmark_alt_circle,
                                    () => Get.to(
                                      () => const MyAdminApprovalResultsView(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      FutureBuilder<bool>(
                        future: AdminAccessService.isPrimaryAdmin(),
                        builder: (context, adminSnap) {
                          if (adminSnap.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }
                          if (adminSnap.data != true) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            children: [
                              buildSectionTitle("Sistem ve Tanı"),
                              buildRow(
                                "Yönetim / Reklam Merkezi",
                                CupertinoIcons.volume_up,
                                () => Get.to(() => const AdsCenterHomeView()),
                              ),
                              buildRow(
                                "Yönetim / Moderasyon",
                                CupertinoIcons.flag_fill,
                                () => Get.to(
                                    () => const ModerationSettingsView()),
                              ),
                              buildRow(
                                "Yönetim / Reports",
                                CupertinoIcons.exclamationmark_bubble_fill,
                                () => Get.to(() => const ReportsAdminView()),
                              ),
                              buildRow(
                                "Yönetim / Rozet Yönetimi",
                                CupertinoIcons.checkmark_seal_fill,
                                () => Get.to(() => const BadgeAdminView()),
                              ),
                              buildRow(
                                "Yönetim / Admin Görevleri",
                                CupertinoIcons.checkmark_rectangle_fill,
                                () => Get.to(
                                    () => const AdminTaskAssignmentsView()),
                              ),
                              buildRow(
                                "Yönetim / Admin Onayları",
                                CupertinoIcons.checkmark_alt_circle_fill,
                                () => Get.to(() => const AdminApprovalsView()),
                              ),
                              buildRow(
                                "Yönetim / Hikaye Müzikleri",
                                CupertinoIcons.music_note_list,
                                () => Get.to(() => const StoryMusicAdminView()),
                              ),
                              buildRow(
                                "Yönetim / Kullanıcı Destek",
                                CupertinoIcons.chat_bubble_2_fill,
                                () => Get.to(() => const SupportAdminView()),
                              ),
                              buildRow(
                                "Sistem ve Tanı Menüsü",
                                CupertinoIcons.antenna_radiowaves_left_right,
                                () {
                                  _showSystemDiagnosticsMenu();
                                },
                              ),
                              _AdminPushMenuTile(buildRow: buildRow),
                            ],
                          );
                        },
                      ),
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
                              await _userRepository.updateUserFields(
                                currentUser,
                                {"token": ""},
                              );
                              await AccountCenterService.ensure()
                                  .markSessionState(
                                uid: currentUser,
                                isSessionValid: false,
                              );
                            }

                            try {
                              await CurrentUserService.instance.logout();
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
            text == "Pasaj"
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
            else if (text == "Hesap Gizliliği")
              // 🎯 Using CurrentUserService reactive
              Obx(() {
                return TurqAppToggle(
                  isOn: userService.currentUserRx.value?.isPrivate ?? false,
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

  List<Widget> _buildAssignedTaskRows(List<String> taskIds) {
    final rows = <Widget>[];
    final seen = <String>{};
    for (final taskId in taskIds) {
      if (!seen.add(taskId)) continue;
      final task = adminTaskCatalogById[taskId];
      if (task == null) continue;
      rows.add(
        buildRow(task.title, task.icon, () => _openAssignedTask(taskId)),
      );
    }
    return rows;
  }

  void _openAssignedTask(String taskId) {
    switch (taskId) {
      case 'moderation':
      case 'user_bans':
        Get.to(() => const ModerationSettingsView());
        return;
      case 'reports':
        Get.to(() => const ReportsAdminView());
        return;
      case 'badges':
        Get.to(() => const BadgeAdminView());
        return;
      case 'approvals':
        Get.to(() => const AdminApprovalsView());
        return;
      case 'admin_push':
        Get.to(() => const AdminPushView());
        return;
      case 'ads_center':
        Get.to(() => const AdsCenterHomeView());
        return;
      case 'story_music':
        Get.to(() => const StoryMusicAdminView());
        return;
      case 'pasaj':
        Get.to(() => PasajSettingsView());
        return;
      case 'support':
        Get.to(() => const SupportAdminView());
        return;
    }
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
    final offline = Get.isRegistered<OfflineModeService>()
        ? Get.find<OfflineModeService>()
        : Get.put(OfflineModeService.instance);
    final queueStats = offline.getQueueStats();
    final queueLastSyncMs = (queueStats['lastSyncAt'] as int?) ?? 0;
    final queueLastSyncText = queueLastSyncMs <= 0
        ? 'Henüz yok'
        : DateTime.fromMillisecondsSinceEpoch(queueLastSyncMs).toString();
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
            const Text(
              "Offline Kuyruk",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("Bekleyen: ${queueStats['pending'] ?? 0}"),
            Text("Dead-letter: ${queueStats['deadLetter'] ?? 0}"),
            Text(
                "Durum: ${(queueStats['isSyncing'] ?? false) ? 'Senkronize ediliyor' : 'Boşta'}"),
            Text("İşlenen (toplam): ${queueStats['processedCount'] ?? 0}"),
            Text("Hata (toplam): ${queueStats['failedCount'] ?? 0}"),
            Text("Son Senkron: $queueLastSyncText"),
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
    if (!Get.isRegistered<OfflineModeService>()) {
      Get.put(OfflineModeService.instance);
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
                leading: const Icon(CupertinoIcons.tray_2),
                title: const Text("Offline Kuyruk Detayı"),
                onTap: () {
                  Get.back();
                  _showOfflineQueueDetails();
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
                leading: const Icon(CupertinoIcons.refresh_circled),
                title: const Text("Offline Kuyruğu Şimdi Senkronla"),
                onTap: () async {
                  Get.back();
                  await OfflineModeService.instance.processPendingNow(
                    ignoreBackoff: true,
                  );
                  AppSnackbar("Tamam", "Offline kuyruk senkron tetiklendi");
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.arrow_2_circlepath_circle),
                title: const Text("Dead-letter Yeniden Dene"),
                onTap: () async {
                  Get.back();
                  await OfflineModeService.instance.retryDeadLetter();
                  AppSnackbar("Tamam", "Dead-letter işlemleri kuyruğa alındı");
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.clear_circled),
                title: const Text("Dead-letter Temizle"),
                onTap: () async {
                  Get.back();
                  await OfflineModeService.instance.clearDeadLetter();
                  AppSnackbar("Tamam", "Dead-letter kuyruğu temizlendi");
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

  void _showOfflineQueueDetails() {
    final offline = Get.isRegistered<OfflineModeService>()
        ? Get.find<OfflineModeService>()
        : Get.put(OfflineModeService.instance);

    Get.dialog(
      AlertDialog(
        title: const Text("Offline Kuyruk Detayı"),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(() {
            final pending = offline.pendingActions.toList();
            final dead = offline.deadLetterActions.toList();
            final stats = offline.getQueueStats();

            String fmtMs(int ms) {
              if (ms <= 0) return '-';
              final dt = DateTime.fromMillisecondsSinceEpoch(ms);
              return dt.toString();
            }

            Widget buildItem(PendingAction a) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.type,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'attempt=${a.attemptCount}  next=${fmtMs(a.nextAttemptAtMs)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                      if ((a.lastError ?? '').isNotEmpty)
                        Text(
                          'error=${a.lastError}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.redAccent,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Online: ${stats['isOnline']}'),
                  Text('Sync: ${stats['isSyncing']}'),
                  Text('Pending: ${pending.length}'),
                  Text('Dead-letter: ${dead.length}'),
                  Text('Processed: ${stats['processedCount'] ?? 0}'),
                  Text('Failed: ${stats['failedCount'] ?? 0}'),
                  const SizedBox(height: 10),
                  const Text(
                    'Pending (ilk 8)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (pending.isEmpty)
                    const Text('-', style: TextStyle(color: Colors.black54)),
                  ...pending.take(8).map(buildItem),
                  const SizedBox(height: 8),
                  const Text(
                    'Dead-letter (ilk 8)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (dead.isEmpty)
                    const Text('-', style: TextStyle(color: Colors.black54)),
                  ...dead.take(8).map(buildItem),
                ],
              ),
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await OfflineModeService.instance
                  .processPendingNow(ignoreBackoff: true);
            },
            child: const Text('Şimdi Senkronla'),
          ),
          TextButton(
            onPressed: () async {
              await OfflineModeService.instance.retryDeadLetter(limit: 100);
            },
            child: const Text('Dead-letter Retry'),
          ),
          TextButton(
            onPressed: () async {
              await OfflineModeService.instance.clearDeadLetter();
            },
            child: const Text('Dead-letter Clear'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Kapat"),
          ),
        ],
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

class _AdminPushMenuTile extends StatefulWidget {
  const _AdminPushMenuTile({required this.buildRow});

  final Widget Function(String, IconData, VoidCallback, {bool isNew}) buildRow;

  @override
  State<_AdminPushMenuTile> createState() => _AdminPushMenuTileState();
}

class _AdminPushMenuTileState extends State<_AdminPushMenuTile> {
  late final Future<bool> _canShowFuture;

  Future<bool> _canShowAdminPushMenu() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    final isAdmin = await AdminAccessService.canManageSliders();
    if (!isAdmin) return false;

    final data = await ConfigRepository.ensure().getAdminConfigDoc(
          'admin',
          preferCache: true,
        ) ??
        <String, dynamic>{};
    return data["pushSend"] == true;
  }

  @override
  void initState() {
    super.initState();
    _canShowFuture = _canShowAdminPushMenu();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canShowFuture,
      builder: (context, snapshot) {
        if (snapshot.data != true) {
          return const SizedBox.shrink();
        }
        return widget.buildRow(
          "Yönetim / Push Gönder",
          CupertinoIcons.paperplane,
          () => Get.to(() => const AdminPushView()),
        );
      },
    );
  }
}
// ignore_for_file: file_names
