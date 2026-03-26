import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/Ads/admob_banner_warmup_service.dart';
import 'package:turqappv2/Core/Services/global_video_adapter_pool.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_post_types.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../Models/posts_model.dart';
import 'package:turqappv2/Core/Helpers/GlobalLoader/global_loader.dart';
import 'package:turqappv2/Modules/Agenda/ClassicContent/classic_content.dart';
import 'package:turqappv2/Modules/PostCreator/post_creator.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Agenda/widgets/feed_create_fab.dart';
import 'package:turqappv2/Modules/Agenda/widgets/feed_inbox_actions_row.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import '../../Themes/app_fonts.dart';
import '../../Themes/app_colors.dart';
import '../../Core/Widgets/app_header_action_button.dart';
import '../../Core/Helpers/GlobalLoader/global_loader_controller.dart';
import '../../Core/Helpers/UnreadMessagesController/unread_messages_controller.dart';
import '../../Core/Widgets/app_icon_surface.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import '../Chat/ChatListing/chat_listing.dart';
import '../InAppNotifications/in_app_notifications.dart';
import '../InAppNotifications/in_app_notifications_controller.dart';
import '../RecommendedUserList/recommended_user_list.dart';
import '../RecommendedUserList/recommended_user_list_controller.dart';
import '../Story/StoryRow/story_row_controller.dart';
import 'AgendaContent/agenda_content.dart';

part 'agenda_view_feed_part.dart';
part 'agenda_view_header_part.dart';

class AgendaView extends StatelessWidget {
  AgendaView({super.key});
  static bool _androidVisibilityTuned = false;
  static bool _feedEntryWarmQueued = false;
  static bool _unreadListenersStarted = false;

  AgendaController get controller {
    return ensureAgendaController();
  }

  GlobalLoaderController get loader {
    return GlobalLoaderController.ensure();
  }

  // ⚠️ CRITICAL FIX: Safe lazy loading for UnreadMessagesController
  UnreadMessagesController get unreadController {
    return ensureUnreadMessagesController();
  }

  RecommendedUserListController get recommendedController {
    return ensureRecommendedUserListController();
  }

  InAppNotificationsController get notificationsController {
    return InAppNotificationsController.ensure();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.isClosed) return;
      unawaited(controller.onPrimarySurfaceVisible());
    });
    if (!_feedEntryWarmQueued) {
      _feedEntryWarmQueued = true;
      unawaited(ensureAdmobBannerWarmupService().warmForFeedEntry());
    }
    if (GetPlatform.isAndroid && !_androidVisibilityTuned) {
      // Feed'de fazla sık visibility callback'i scroll sırasında jank üretebiliyor.
      VisibilityDetectorController.instance.updateInterval =
          const Duration(milliseconds: 160);
      _androidVisibilityTuned = true;
    }

    // Feed açıldığında unread listener kesin aktif olsun (idempotent guard var)
    if (!_unreadListenersStarted) {
      _unreadListenersStarted = true;
      unreadController.startListeners();
    }
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      key: const ValueKey(IntegrationTestKeys.screenFeed),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: topInset + 7,
              color: Colors.white,
            ),
          ),
          SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: _buildRefreshableFeed(context),
                ),
              ],
            ),
          ),
          _buildCreateFab(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlobalLoader(),
          ),
        ],
      ),
    );
  }
}
