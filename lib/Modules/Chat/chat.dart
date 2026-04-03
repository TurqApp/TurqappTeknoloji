import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Modules/Chat/chat_controller.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Chat/MessageContent/message_content.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:video_player/video_player.dart';

import 'LocationShareView/location_share_view_chat.dart';

part 'chat_body_part.dart';
part 'chat_media_preview_part.dart';
part 'chat_composer_part.dart';
part 'chat_input_widgets_part.dart';

const List<Color> _chatBackgroundPalette = [
  Color(0xFFEFF5FB),
  Color(0xFFE7F7F1),
  Color(0xFFFBEFE8),
  Color(0xFFF9ECF5),
  Color(0xFFF1ECFB),
  Color(0xFFE6F5F1),
];

class ChatView extends StatelessWidget {
  final String chatID;
  final String userID;
  final bool? isNewChat;
  final bool? openKeyboard;

  ChatView({
    super.key,
    required this.chatID,
    required this.userID,
    this.isNewChat,
    this.openKeyboard,
  });
  ChatController get controller => ensureChatController(
        chatID: chatID,
        userID: userID,
        tag: chatID,
      );

  void _disposeChatControllerIfAny() {
    if (maybeFindChatController(tag: chatID) != null) {
      Get.delete<ChatController>(tag: chatID, force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // İlk açılışta sadece bir kez odakla (her rebuild'de klavye zıplamasını engeller)
    if (openKeyboard == true && controller.didAutoFocusOnce == false) {
      controller.didAutoFocusOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.focus.requestFocus();
      });
    }
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _disposeChatControllerIfAny();
        }
      },
      child: Scaffold(
        key: const ValueKey(IntegrationTestKeys.screenChatConversation),
        body: SafeArea(
          bottom: false,
          child: Obx(() {
            return Stack(
              children: [
                if (controller.selection.value == 0)
                  buildChat(context)
                else if (controller.selection.value == 1)
                  buildImagePreview(),
              ],
            );
          }),
        ),
      ),
    );
  }
}
