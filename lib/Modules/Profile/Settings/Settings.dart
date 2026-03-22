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
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
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

part 'settings_sections_part.dart';
part 'settings_diagnostics_part.dart';

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
  final AppLanguageService _languageService = AppLanguageService.ensure();

  // 🎯 Using CurrentUserService for optimized user data
  final userService = CurrentUserService.instance;

  @override
  void initState() {
    super.initState();
    final existingSettingsController = SettingsController.maybeFind();
    if (existingSettingsController != null) {
      controller = existingSettingsController;
    } else {
      controller = SettingsController.ensure();
      _ownsSettingsController = true;
    }
    final existingScholarshipsController = ScholarshipsController.maybeFind();
    if (existingScholarshipsController != null) {
      scholarshipsController = existingScholarshipsController;
    } else {
      scholarshipsController = ScholarshipsController.ensure();
      _ownsScholarshipsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsScholarshipsController &&
        identical(
          ScholarshipsController.maybeFind(),
          scholarshipsController,
        )) {
      Get.delete<ScholarshipsController>(force: true);
    }
    if (_ownsSettingsController &&
        identical(SettingsController.maybeFind(), controller)) {
      Get.delete<SettingsController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey(IntegrationTestKeys.screenSettings),
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
                      ..._buildPrimarySections(),
                      _buildAssignedTasksSection(),
                      _buildAdminSection(),
                      ..._buildSessionSection(),
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
      bool showLanguageLabel = false,
      Key? valueKey}) {
    return TextButton(
      key: valueKey,
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
    if (CurrentUserService.instance.effectiveUserId.isEmpty) return false;

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
