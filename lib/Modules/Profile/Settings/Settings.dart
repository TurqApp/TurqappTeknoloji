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
import 'package:turqappv2/Modules/Profile/Settings/language_settings_view.dart';
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
import 'package:turqappv2/Core/Localization/app_language_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final SettingsController controller;
  late final ScholarshipsController scholarshipsController;
  bool _ownsSettingsController = false;
  bool _ownsScholarshipsController = false;
  final UserRepository _userRepository = UserRepository.ensure();
  final VerifiedAccountRepository _verifiedAccountRepository =
      VerifiedAccountRepository.ensure();
  final AdminTaskAssignmentRepository _adminTaskAssignmentRepository =
      AdminTaskAssignmentRepository.ensure();
  final AdminApprovalRepository _adminApprovalRepository =
      AdminApprovalRepository.ensure();
  final AppLanguageService _languageService = Get.find<AppLanguageService>();

  // 🎯 Using CurrentUserService for optimized user data
  final userService = CurrentUserService.instance;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<SettingsController>()) {
      controller = Get.find<SettingsController>();
    } else {
      controller = Get.put(SettingsController());
      _ownsSettingsController = true;
    }
    if (Get.isRegistered<ScholarshipsController>()) {
      scholarshipsController = Get.find<ScholarshipsController>();
    } else {
      scholarshipsController = Get.put(ScholarshipsController());
      _ownsScholarshipsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsScholarshipsController &&
        Get.isRegistered<ScholarshipsController>() &&
        identical(Get.find<ScholarshipsController>(), scholarshipsController)) {
      Get.delete<ScholarshipsController>(force: true);
    }
    if (_ownsSettingsController &&
        Get.isRegistered<SettingsController>() &&
        identical(Get.find<SettingsController>(), controller)) {
      Get.delete<SettingsController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'settings.title'.tr),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      buildSectionTitle('settings.account'.tr),
                      buildRow('settings.edit_profile'.tr, CupertinoIcons.pencil_outline,
                          () {
                        Get.to(() => EditProfile());
                      }),
                      FutureBuilder<VerifiedAccountApplicationState?>(
                        future:
                            _verifiedAccountRepository.fetchApplicationState(
                          userService.userId,
                        ),
                        builder: (context, snapshot) {
                          final application = snapshot.data;
                          final hasPendingApplication =
                              application?.isPending == true;
                          final canRenew =
                              application?.canSubmitRenewal == true;
                          final hasBadge = userService.rozet.isNotEmpty;
                          if (hasPendingApplication) {
                            return buildRow(
                              'settings.badge_application'.tr,
                              CupertinoIcons.doc_text_search,
                              () {
                                Get.to(() => BecomeVerifiedAccount());
                              },
                            );
                          }
                          if (canRenew) {
                            return buildRow(
                              'settings.badge_renew'.tr,
                              CupertinoIcons.arrow_clockwise_circle,
                              () {
                                Get.to(() => BecomeVerifiedAccount());
                              },
                            );
                          }
                          if (!hasBadge) {
                            return buildRow(
                              'settings.become_verified'.tr,
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
                        'settings.blocked_users'.tr,
                        CupertinoIcons.exclamationmark_circle,
                        () {
                          Get.to(() => BlockedUsers());
                        },
                      ),
                      buildRow('settings.interests'.tr, CupertinoIcons.sparkles, () {
                        Get.to(() => Interests());
                      }),
                      buildRow(
                        'settings.account_center'.tr,
                        CupertinoIcons.person_2_square_stack,
                        () {
                          Get.to(() => AccountCenterView());
                        },
                      ),
                      buildRow('settings.career_profile'.tr, CupertinoIcons.paperclip, () {
                        Get.to(() => Cv());
                      }),
                      buildSectionTitle('settings.content'.tr),
                      buildRow('settings.saved_posts'.tr, CupertinoIcons.bookmark, () {
                        Get.to(() => SavedPosts());
                      }),
                      buildRow('settings.archive'.tr, CupertinoIcons.refresh_thick, () {
                        Get.to(() => Archives());
                      }),
                      buildRow('settings.liked_posts'.tr, CupertinoIcons.hand_thumbsup,
                          () {
                        Get.to(() => LikedPosts());
                      }),
                      buildSectionTitle('settings.app'.tr),
                      buildRow('settings.language'.tr, CupertinoIcons.globe, () {
                        Get.to(() => const LanguageSettingsView());
                      }, showLanguageLabel: true),
                      buildRow('settings.notifications'.tr, CupertinoIcons.bell, () {
                        Get.to(() => const NotificationSettingsView());
                      }),
                      buildRow('settings.permissions'.tr, CupertinoIcons.lock_shield, () {
                        Get.to(() => const PermissionsView());
                      }),
                      buildRow('settings.pasaj'.tr, CupertinoIcons.nosign, () {
                        Get.to(() => PasajSettingsView());
                      }, usePasajIcon: true),
                      buildSectionTitle('settings.security_support'.tr),
                      buildRow('settings.about'.tr, CupertinoIcons.info, () {
                        Get.to(
                          () => AboutProfile(
                            userID: userService.userId,
                          ),
                        );
                      }),
                      buildRow('settings.policies'.tr, CupertinoIcons.shield, () {
                        Get.to(() => Policies());
                      }),
                      buildRow('settings.contact_us'.tr, CupertinoIcons.pencil_circle, () {
                        Get.to(() => const SupportContactView());
                      }),
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: _adminTaskAssignmentRepository.watchAssignment(
                          userService.userId,
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
                              buildSectionTitle('settings.my_tasks'.tr),
                              ..._buildAssignedTaskRows(taskIds),
                              StreamBuilder<
                                  QuerySnapshot<Map<String, dynamic>>>(
                                stream:
                                    _adminApprovalRepository.watchOwnApprovals(
                                  userService.userId,
                                ),
                                builder: (context, approvalsSnap) {
                                  final docs =
                                      approvalsSnap.data?.docs ?? const [];
                                  if (docs.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return buildRow(
                                    'settings.my_approval_results'.tr,
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
                              buildSectionTitle('settings.system_diagnostics'.tr),
                              buildRow(
                                'settings.admin_ads'.tr,
                                CupertinoIcons.volume_up,
                                () => Get.to(() => const AdsCenterHomeView()),
                              ),
                              buildRow(
                                'settings.admin_moderation'.tr,
                                CupertinoIcons.flag_fill,
                                () => Get.to(
                                    () => const ModerationSettingsView()),
                              ),
                              buildRow(
                                'settings.admin_reports'.tr,
                                CupertinoIcons.exclamationmark_bubble_fill,
                                () => Get.to(() => const ReportsAdminView()),
                              ),
                              buildRow(
                                'settings.admin_badges'.tr,
                                CupertinoIcons.checkmark_seal_fill,
                                () => Get.to(() => const BadgeAdminView()),
                              ),
                              buildRow(
                                'settings.admin_tasks'.tr,
                                CupertinoIcons.checkmark_rectangle_fill,
                                () => Get.to(
                                    () => const AdminTaskAssignmentsView()),
                              ),
                              buildRow(
                                'settings.admin_approvals'.tr,
                                CupertinoIcons.checkmark_alt_circle_fill,
                                () => Get.to(() => const AdminApprovalsView()),
                              ),
                              buildRow(
                                'settings.admin_story_music'.tr,
                                CupertinoIcons.music_note_list,
                                () => Get.to(() => const StoryMusicAdminView()),
                              ),
                              buildRow(
                                'settings.admin_support'.tr,
                                CupertinoIcons.chat_bubble_2_fill,
                                () => Get.to(() => const SupportAdminView()),
                              ),
                              buildRow(
                                'settings.system_diag_menu'.tr,
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
                      buildSectionTitle('settings.session'.tr),
                      buildRow(
                          'settings.sign_out'.tr, CupertinoIcons.square_arrow_right,
                          () {
                        noYesAlert(
                          title: 'settings.sign_out_title'.tr,
                          message: 'settings.sign_out_message'.tr,
                          onYesPressed: () async {
                            final currentUser = userService.userId.trim();
                            if (currentUser.isNotEmpty) {
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
                              print("Sign out failed: $e");
                            }
                          },
                          yesText: "settings.sign_out_title".tr,
                          cancelText: "common.cancel".tr,
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
      {bool isNew = false,
      bool usePasajIcon = false,
      bool showLanguageLabel = false}) {
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
            usePasajIcon
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
            if (showLanguageLabel)
              Text(
                _languageService.currentLanguageLabel,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              )
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
        buildRow(task.titleKey.tr, task.icon, () => _openAssignedTask(taskId)),
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
        : "settings.diagnostics.unknown".tr;
    final offline = Get.isRegistered<OfflineModeService>()
        ? Get.find<OfflineModeService>()
        : Get.put(OfflineModeService.instance);
    final queueStats = offline.getQueueStats();
    final queueLastSyncMs = (queueStats['lastSyncAt'] as int?) ?? 0;
    final queueLastSyncText = queueLastSyncMs <= 0
        ? "common.no_results".tr
        : DateTime.fromMillisecondsSinceEpoch(queueLastSyncMs).toString();
    final lastSignIn =
        FirebaseAuth.instance.currentUser?.metadata.lastSignInTime;
    final loginDate = lastSignIn == null
        ? "settings.diagnostics.unknown".tr
        : "${lastSignIn.day.toString().padLeft(2, '0')}.${lastSignIn.month.toString().padLeft(2, '0')}.${lastSignIn.year}";
    final loginTime = lastSignIn == null
        ? "settings.diagnostics.unknown".tr
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
        title: Text("settings.diagnostics.data_usage".tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${'settings.diagnostics.network'.tr}: ${stats['currentNetwork']}"),
            Text("${'settings.diagnostics.connected'.tr}: ${stats['isConnected']}"),
            Text(
              "${'settings.diagnostics.monthly_total'.tr}: ${stats['monthlyUsageMB']} MB",
            ),
            Text("${'settings.diagnostics.monthly_limit'.tr}: ${stats['monthlyLimitMB']} MB"),
            Text("${'settings.diagnostics.remaining'.tr}: ${stats['remainingMB']} MB"),
            Text(
              "${'settings.diagnostics.limit_usage'.tr}: ${stats['dataUsagePercentage'].toStringAsFixed(1)}%",
            ),
            Text("${'settings.diagnostics.wifi_usage'.tr}: ${stats['wifiUsageMB']} MB"),
            Text("${'settings.diagnostics.cellular_usage'.tr}: ${stats['cellularUsageMB']} MB"),
            const SizedBox(height: 8),
            Text(
              "settings.diagnostics.time_ranges".tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "1) ${'settings.diagnostics.this_month_actual'.tr}: ${monthlyTotalMB.toStringAsFixed(1)} MB",
            ),
            Text(
              "${'settings.diagnostics.hourly_average'.tr}: ${monthlyAvgPerHour.toStringAsFixed(2)} MB/saat",
            ),
            Text(
              "2) ${'settings.diagnostics.since_login_estimated'.tr}: ${sinceLoginEstimatedTotal.toStringAsFixed(1)} MB",
            ),
            Text(
              "${'settings.diagnostics.hourly_average'.tr}: ${sinceLoginAvgPerHour.toStringAsFixed(2)} MB/saat",
            ),
            const SizedBox(height: 8),
            Text(
              "settings.diagnostics.details".tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("${'settings.diagnostics.upload'.tr}: ${usage.uploadedMB} MB"),
            Text("${'settings.diagnostics.download'.tr}: ${usage.downloadedMB} MB"),
            const SizedBox(height: 8),
            Text(
              "settings.diagnostics.cache".tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("${'settings.diagnostics.saved_media_count'.tr}: $cacheEntryCount"),
            Text("${'settings.diagnostics.occupied_space'.tr}: $cacheSizeText"),
            const SizedBox(height: 8),
            Text(
              "settings.diagnostics.offline_queue".tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("${'settings.diagnostics.pending'.tr}: ${queueStats['pending'] ?? 0}"),
            Text("${'settings.diagnostics.dead_letter'.tr}: ${queueStats['deadLetter'] ?? 0}"),
            Text(
                "${'settings.diagnostics.status'.tr}: ${(queueStats['isSyncing'] ?? false) ? 'settings.diagnostics.syncing'.tr : 'settings.diagnostics.idle'.tr}"),
            Text("${'settings.diagnostics.processed_total'.tr}: ${queueStats['processedCount'] ?? 0}"),
            Text("${'settings.diagnostics.failed_total'.tr}: ${queueStats['failedCount'] ?? 0}"),
            Text("${'settings.diagnostics.last_sync'.tr}: $queueLastSyncText"),
            const SizedBox(height: 8),
            Text("${'settings.diagnostics.login_date'.tr}: $loginDate"),
            Text("${'settings.diagnostics.login_time'.tr}: $loginTime"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("common.close".tr),
          ),
        ],
      ),
    );
  }

  void _ensureDiagnosticsServices() {
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
              ListTile(
                title: Text(
                  "settings.system_diag_menu".tr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading:
                    const Icon(CupertinoIcons.antenna_radiowaves_left_right),
                title: Text("settings.diagnostics.data_usage".tr),
                onTap: () {
                  Get.back();
                  _showDataUsageDialog();
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.chart_bar),
                title: Text("settings.diagnostics.app_health_panel".tr),
                onTap: () {
                  Get.back();
                  Get.to(() => const AppHealthDashboard());
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.play_rectangle),
                title: Text("settings.diagnostics.video_cache_detail".tr),
                onTap: () {
                  Get.back();
                  _showVideoCacheDetails();
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.bolt_horizontal_circle),
                title: Text("settings.diagnostics.quick_actions".tr),
                onTap: () {
                  Get.back();
                  _showQuickActions();
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.tray_2),
                title: Text("settings.diagnostics.offline_queue_detail".tr),
                onTap: () {
                  Get.back();
                  _showOfflineQueueDetails();
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.exclamationmark_bubble),
                title: Text("settings.diagnostics.last_error_summary".tr),
                onTap: () {
                  Get.back();
                  _showLastErrorSummary();
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.exclamationmark_triangle),
                title: Text("settings.diagnostics.error_report".tr),
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
        title: Text("settings.diagnostics.video_cache_detail".tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${'settings.diagnostics.saved_videos'.tr}: ${cache?.entryCount ?? 0}"),
            Text("${'settings.diagnostics.saved_segments'.tr}: ${cache?.totalSegmentCount ?? 0}"),
            Text(
              "${'settings.diagnostics.disk_usage'.tr}: ${cache == null ? 'settings.diagnostics.unknown'.tr : CacheMetrics.formatBytes(cache.totalSizeBytes)}",
            ),
            const SizedBox(height: 8),
            Text("settings.diagnostics.cache_traffic".tr,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("${'settings.diagnostics.hit_rate'.tr}: $hitRate"),
            Text("${'settings.diagnostics.hit'.tr}: ${metrics['cacheHits'] ?? 0}"),
            Text("${'settings.diagnostics.miss'.tr}: ${metrics['cacheMisses'] ?? 0}"),
            Text("${'settings.diagnostics.cache_served'.tr}: ${metrics['bytesServedFromCache'] ?? '0B'}"),
            Text("${'settings.diagnostics.downloaded_from_network'.tr}: ${metrics['bytesDownloaded'] ?? '0B'}"),
            const SizedBox(height: 8),
            Text("settings.diagnostics.prefetch".tr,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("${'settings.diagnostics.queue'.tr}: ${prefetch?.queueSize ?? 0}"),
            Text("${'settings.diagnostics.active_downloads'.tr}: ${prefetch?.activeDownloads ?? 0}"),
            Text(
                "${'settings.diagnostics.status'.tr}: ${(prefetch?.isPaused ?? true) ? 'settings.diagnostics.paused'.tr : 'settings.diagnostics.active'.tr}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("common.close".tr),
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
              ListTile(
                title: Text(
                  "settings.diagnostics.quick_actions".tr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.arrow_counterclockwise),
                title: Text("settings.diagnostics.reset_data_counters".tr),
                onTap: () async {
                  Get.back();
                  await Get.find<NetworkAwarenessService>().resetDataUsage();
                  AppSnackbar("common.success".tr,
                      "settings.diagnostics.data_counters_reset".tr);
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.refresh_circled),
                title: Text("settings.diagnostics.sync_offline_queue_now".tr),
                onTap: () async {
                  Get.back();
                  await OfflineModeService.instance.processPendingNow(
                    ignoreBackoff: true,
                  );
                  AppSnackbar("common.success".tr,
                      "settings.diagnostics.offline_queue_sync_triggered".tr);
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.arrow_2_circlepath_circle),
                title: Text("settings.diagnostics.retry_dead_letter".tr),
                onTap: () async {
                  Get.back();
                  await OfflineModeService.instance.retryDeadLetter();
                  AppSnackbar("common.success".tr,
                      "settings.diagnostics.dead_letter_queued".tr);
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.clear_circled),
                title: Text("settings.diagnostics.clear_dead_letter".tr),
                onTap: () async {
                  Get.back();
                  await OfflineModeService.instance.clearDeadLetter();
                  AppSnackbar("common.success".tr,
                      "settings.diagnostics.dead_letter_cleared".tr);
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.pause_circle),
                title: Text("settings.diagnostics.pause_prefetch".tr),
                onTap: () {
                  Get.back();
                  if (Get.isRegistered<PrefetchScheduler>()) {
                    Get.find<PrefetchScheduler>().pause();
                    AppSnackbar("common.success".tr,
                        "settings.diagnostics.prefetch_paused".tr);
                  } else {
                    AppSnackbar("common.info".tr,
                        "settings.diagnostics.service_not_ready".tr);
                  }
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.play_circle),
                title: Text("settings.diagnostics.resume_prefetch".tr),
                onTap: () {
                  Get.back();
                  if (Get.isRegistered<PrefetchScheduler>()) {
                    Get.find<PrefetchScheduler>().resume();
                    AppSnackbar("common.success".tr,
                        "settings.diagnostics.prefetch_resumed".tr);
                  } else {
                    AppSnackbar("common.info".tr,
                        "settings.diagnostics.service_not_ready".tr);
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
        title: Text("settings.diagnostics.offline_queue_detail".tr),
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
                  Text("${'settings.diagnostics.online'.tr}: ${stats['isOnline']}"),
                  Text("${'settings.diagnostics.sync'.tr}: ${stats['isSyncing']}"),
                  Text("${'settings.diagnostics.pending'.tr}: ${pending.length}"),
                  Text("${'settings.diagnostics.dead_letter'.tr}: ${dead.length}"),
                  Text("${'settings.diagnostics.processed'.tr}: ${stats['processedCount'] ?? 0}"),
                  Text("${'settings.diagnostics.failed'.tr}: ${stats['failedCount'] ?? 0}"),
                  const SizedBox(height: 10),
                  Text(
                    'settings.diagnostics.pending_first8'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (pending.isEmpty)
                    const Text('-', style: TextStyle(color: Colors.black54)),
                  ...pending.take(8).map(buildItem),
                  const SizedBox(height: 8),
                  Text(
                    'settings.diagnostics.dead_letter_first8'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
            child: Text('settings.diagnostics.sync_now'.tr),
          ),
          TextButton(
            onPressed: () async {
              await OfflineModeService.instance.retryDeadLetter(limit: 100);
            },
            child: Text('settings.diagnostics.dead_letter_retry'.tr),
          ),
          TextButton(
            onPressed: () async {
              await OfflineModeService.instance.clearDeadLetter();
            },
            child: Text('settings.diagnostics.dead_letter_clear'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: Text("common.close".tr),
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
        title: Text("settings.diagnostics.last_error_summary".tr),
        content: last == null
            ? Text("settings.diagnostics.no_recorded_error".tr)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${'settings.diagnostics.error_code'.tr}: ${last['code']}"),
                  Text("${'settings.diagnostics.error_category'.tr}: ${last['category']}"),
                  Text("${'settings.diagnostics.error_severity'.tr}: ${last['severity']}"),
                  Text("${'settings.diagnostics.error_retryable'.tr}: ${last['retryable']}"),
                  Text("${'settings.diagnostics.error_message'.tr}: ${last['userFriendlyMessage']}"),
                  Text("${'settings.diagnostics.error_time'.tr}: ${last['timestamp']}"),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("common.close".tr),
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
          "settings.admin_push".tr,
          CupertinoIcons.paperplane,
          () => Get.to(() => const AdminPushView()),
        );
      },
    );
  }
}
// ignore_for_file: file_names
