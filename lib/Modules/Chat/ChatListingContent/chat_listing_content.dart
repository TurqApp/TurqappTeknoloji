import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Helpers/UnreadMessagesController/unread_messages_controller.dart';
import 'package:turqappv2/Core/Repositories/conversation_repository.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Models/chat_listing_model.dart';
import 'package:turqappv2/Modules/Chat/chat_constants.dart';
import 'package:turqappv2/Modules/Chat/chat.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing_controller.dart';
import 'package:turqappv2/Modules/InAppNotifications/in_app_notifications_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chat_listing_content_controller.dart';

part 'chat_listing_content_actions_part.dart';
part 'chat_listing_content_view_part.dart';

class ChatListingContent extends StatelessWidget {
  static const Set<String> _postMessageMarkers = {
    'gönderi',
    kConversationPostMessageMarker,
    'chat.post',
    'post',
    'beitrag',
    'publication',
    'pubblicazione',
    'пост',
  };
  static const Set<String> _previewTranslationKeys = {
    'chat.unsent_message',
    'chat.video',
    'chat.audio',
    'chat.photo',
    'chat.post',
    'chat.person',
    'chat.location',
  };

  final ChatListingModel model;
  final bool isSearchResult;
  final bool isArchiveTab;
  ChatListingContent({
    super.key,
    required this.model,
    this.isSearchResult = false,
    this.isArchiveTab = false,
  });
  late final ChatListingContentController controller;
  final ConversationRepository _conversationRepository =
      ConversationRepository.ensure();
  final GlobalKey _timeAnchorKey = GlobalKey();

  String _buildSubtitle() {
    if (model.lastMessage.trim().isNotEmpty) {
      if (_previewTranslationKeys.contains(model.lastMessage.trim())) {
        return model.lastMessage.trim().tr;
      }
      if (_postMessageMarkers.contains(
        normalizeSearchText(model.lastMessage),
      )) {
        return 'chat.post'.tr;
      }
      return model.lastMessage.trim();
    }
    if (controller.lastMessage.isEmpty) return 'chat.tap_to_chat'.tr;
    final last = controller.lastMessage.last;
    if (last.metin.trim().isNotEmpty) return last.metin.trim();
    if (last.imgs.isNotEmpty) return 'chat.photo'.tr;
    return 'chat.message_label'.tr;
  }

  String _buildTimeText() {
    final ts = int.tryParse(model.timeStamp) ?? 0;
    if (ts <= 0) return "";
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return "$h:$m";
    }
    return "${dt.day}.${dt.month}.${dt.year}";
  }

  String get _uid => CurrentUserService.instance.effectiveUserId;

  @override
  Widget build(BuildContext context) => _buildTile(context);
}
