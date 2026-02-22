// lib/DebugView.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'NotifyReaderController.dart';

class NotifyReader extends StatelessWidget {
  final String docID;
  final String type;
  NotifyReader({super.key, required this.docID, required this.type});
  final controller = Get.put(NotifyReaderController());

  @override
  Widget build(BuildContext context) {
    if (type == "User") {
      controller.goToProfile(docID);
    }
    if (type == "Posts") {
      controller.goToPost(docID);
    }
    if (type == "Comment") {
      controller.goToPostComments(docID);
    }
    if (type == "Chat") {
      controller.goToChat(docID);
    }
    return Scaffold(
      body: Center(child: CupertinoActivityIndicator()),
    );
  }
}
