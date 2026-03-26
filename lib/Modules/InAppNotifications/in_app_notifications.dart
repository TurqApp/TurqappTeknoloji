import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Models/notification_model.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_content.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_post_types.dart';
import 'package:turqappv2/Modules/RecommendedUserList/recommended_user_list_controller.dart';

import 'in_app_notifications_controller.dart';
import 'notification_actions_sheet_content.dart';

part 'in_app_notifications_shell_part.dart';
part 'in_app_notifications_shell_content_part.dart';
part 'in_app_notifications_list_part.dart';

class InAppNotifications extends StatefulWidget {
  const InAppNotifications({super.key});

  @override
  State<InAppNotifications> createState() => _InAppNotificationsState();
}

class _InAppNotificationsState extends State<InAppNotifications> {
  late final InAppNotificationsController controller;
  late final RecommendedUserListController recommendedController;
  late final String _controllerTag;
  late final String _pageLineBarTag;
  bool _ownsRecommendedController = false;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'in_app_notifications_${identityHashCode(this)}';
    _pageLineBarTag = '${kNotificationsPageLineBarTag}_$_controllerTag';
    controller = InAppNotificationsController.ensure();
    final existingRecommended = maybeFindRecommendedUserListController();
    if (existingRecommended != null) {
      recommendedController = existingRecommended;
    } else {
      recommendedController = ensureRecommendedUserListController();
      _ownsRecommendedController = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.markInboxSeen();
    });
  }

  @override
  void dispose() {
    if (_ownsRecommendedController &&
        identical(
            maybeFindRecommendedUserListController(), recommendedController)) {
      Get.delete<RecommendedUserListController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
