// lib/DebugView.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'notify_reader_controller.dart';

class NotifyReader extends StatelessWidget {
  final String docID;
  final String type;
  NotifyReader({super.key, required this.docID, required this.type});
  final controller = Get.put(NotifyReaderController());

  void _routeByType() {
    final rawType = type.trim();
    final normalized = rawType.toLowerCase();

    if (docID.trim().isEmpty) {
      Get.back();
      return;
    }

    if (normalized == "user" || normalized == "follow") {
      controller.goToProfile(docID);
      return;
    }
    if (normalized == "posts" ||
        normalized == "like" ||
        normalized == "reshared_posts" ||
        normalized == "shared_as_posts") {
      controller.goToPost(docID);
      return;
    }
    if (normalized == "comment") {
      controller.goToPostComments(docID);
      return;
    }
    if (normalized == "chat" || normalized == "message") {
      controller.goToChat(docID);
      return;
    }
    if (normalized == "market_offer" || normalized == "market_offer_status") {
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
