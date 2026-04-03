import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Widgets/search_reset_on_page_return_scope.dart';
import 'package:turqappv2/Models/chat_listing_model.dart';
import 'package:turqappv2/Modules/Chat/ChatListingContent/chat_listing_content.dart';

import 'chat_search_field.dart';
import 'chat_listing_controller.dart';

part 'chat_listing_shell_part.dart';
part 'chat_listing_shell_content_part.dart';
part 'chat_listing_content_part.dart';

class ChatListing extends StatefulWidget {
  const ChatListing({super.key});

  @override
  State<ChatListing> createState() => _ChatListingState();
}

class _ChatListingState extends State<ChatListing> {
  late final ChatListingController controller;
  final ValueNotifier<String?> _openedChatId = ValueNotifier<String?>(null);
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    final existingController = ChatListingController.maybeFind();
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = ChatListingController.ensure();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    _openedChatId.dispose();
    if (_ownsController &&
        identical(ChatListingController.maybeFind(), controller)) {
      Get.delete<ChatListingController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SearchResetOnPageReturnScope(
        onReset: () {
          controller.search.clear();
        },
        child: _buildPage(context),
      );
}
