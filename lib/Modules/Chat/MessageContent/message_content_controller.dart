import 'dart:async';
import 'dart:io';
import 'package:contact_add/contact.dart';
import 'package:contact_add/contact_add.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/conversation_repository.dart';
import 'package:turqappv2/Core/Repositories/notify_lookup_repository.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/BottomSheets/show_action_sheet.dart';
import 'package:turqappv2/Core/Helpers/safe_external_link_guard.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Models/message_model.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Models/posts_model.dart';

part 'message_content_controller_data_part.dart';
part 'message_content_controller_actions_part.dart';

class MessageContentController extends GetxController {
  static MessageContentController ensure({
    required MessageModel model,
    required String mainID,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MessageContentController(model: model, mainID: mainID),
      tag: tag,
      permanent: permanent,
    );
  }

  static MessageContentController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<MessageContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MessageContentController>(tag: tag);
  }

  final MessageModel model;
  final String mainID;

  var nickname = "".obs;
  var avatarUrl = "".obs;

  var currentIndex = 0.obs;
  var showAllImages = false.obs;
  RxList<String> imageUrls = <String>[].obs;
  var postModel = Rx<PostsModel?>(null);

  MessageContentController({
    required this.model,
    required this.mainID,
  });

  var postNickname = "".obs;
  var postPfImage = "".obs;
  final ConversationRepository _conversationRepository =
      ConversationRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  @override
  void onInit() {
    super.onInit();

    // model.imgs atanır
    imageUrls.assignAll(model.imgs);

    // kullanıcı verisini al
    unawaited(_loadMessageUser());

    if (model.postID != "") {
      getPost();
    }
  }
}
