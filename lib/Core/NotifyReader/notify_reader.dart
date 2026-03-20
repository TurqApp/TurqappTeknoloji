// lib/DebugView.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

import 'notify_reader_controller.dart';

class NotifyReader extends StatelessWidget {
  final String docID;
  final String type;
  NotifyReader({super.key, required this.docID, required this.type});
  final controller = Get.put(NotifyReaderController());
  static const _profileTypes = {'user', 'follow'};
  static const _postTypes = {
    'posts',
    'like',
    'reshared_posts',
    'shared_as_posts',
  };
  static const _chatTypes = {'chat', 'message'};
  static const _marketTypes = {'market_offer', 'market_offer_status'};

  void _routeByType() {
    final rawType = type.trim();
    final normalized = normalizeSearchText(rawType);

    if (docID.trim().isEmpty) {
      Get.back();
      return;
    }

    if (_profileTypes.contains(normalized)) {
      controller.goToProfile(docID);
      return;
    }
    if (_postTypes.contains(normalized)) {
      controller.goToPost(docID);
      return;
    }
    if (normalized == "comment") {
      controller.goToPostComments(docID);
      return;
    }
    if (_chatTypes.contains(normalized)) {
      controller.goToChat(docID);
      return;
    }
    if (_marketTypes.contains(normalized)) {
      controller.goToMarket(docID);
      return;
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    _routeByType();
    return Scaffold(
      body: Center(child: CupertinoActivityIndicator()),
    );
  }
}
