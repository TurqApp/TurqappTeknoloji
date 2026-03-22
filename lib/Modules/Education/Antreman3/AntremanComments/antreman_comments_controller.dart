import 'dart:developer';
import 'dart:io';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/antreman_repository.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/Education/question_bank_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'antreman_comments_controller_data_part.dart';
part 'antreman_comments_controller_actions_part.dart';

class Comment {
  final String docID;
  final String userID;
  final String metin;
  final int timeStamp;
  final List<String> begeniler;
  final String? photoUrl;

  Comment({
    required this.docID,
    required this.userID,
    required this.metin,
    required this.timeStamp,
    required this.begeniler,
    this.photoUrl,
  });

  factory Comment.fromJson(String docID, Map<String, dynamic> json) {
    return Comment(
      docID: docID,
      userID: json['userID'] ?? '',
      metin: json['metin'] ?? '',
      timeStamp: json['timeStamp'] ?? 0,
      begeniler: List<String>.from(json['begeniler'] ?? []),
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'metin': metin,
      'timeStamp': timeStamp,
      'begeniler': begeniler,
      'photoUrl': photoUrl,
    };
  }
}

class Reply {
  final String docID;
  final String userID;
  final String metin;
  final int timeStamp;
  final List<String> begeniler;
  final String? photoUrl;

  Reply({
    required this.docID,
    required this.userID,
    required this.metin,
    required this.timeStamp,
    required this.begeniler,
    this.photoUrl,
  });

  factory Reply.fromJson(String docID, Map<String, dynamic> json) {
    return Reply(
      docID: docID,
      userID: json['userID'] ?? '',
      metin: json['metin'] ?? '',
      timeStamp: json['timeStamp'] ?? 0,
      begeniler: List<String>.from(json['begeniler'] ?? []),
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'metin': metin,
      'timeStamp': timeStamp,
      'begeniler': begeniler,
      'photoUrl': photoUrl,
    };
  }
}

class AntremanCommentsController extends GetxController {
  static AntremanCommentsController ensure({
    required QuestionBankModel question,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      AntremanCommentsController(question),
      tag: tag,
      permanent: permanent,
    );
  }

  static AntremanCommentsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<AntremanCommentsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<AntremanCommentsController>(tag: tag);
  }

  final QuestionBankModel question;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final AntremanRepository _antremanRepository = AntremanRepository.ensure();
  final String userID = CurrentUserService.instance.effectiveUserId;
  final FocusNode focusNode = FocusNode();
  final ScrollController scrollController = ScrollController();

  AntremanCommentsController(this.question);

  final RxList<Comment> comments = <Comment>[].obs;
  final RxMap<String, List<Reply>> replies = <String, List<Reply>>{}.obs;
  final RxMap<String, bool> repliesVisible = <String, bool>{}.obs;
  final RxString replyingToCommentDocID = ''.obs;
  final TextEditingController commentController = TextEditingController();
  final Map<String, Map<String, dynamic>> userInfoCache = {};
  final RxString editingCommentDocID = ''.obs;
  final RxString editingReplyDocID = ''.obs;
  final RxBool isTextFieldNotEmpty = false.obs;
  final RxBool isLoading = true.obs;
  final Rx<File?> selectedImage = Rx<File?>(null);
  final ImagePicker picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    unawaited(fetchComments());
    commentController.addListener(() {
      isTextFieldNotEmpty.value = commentController.text.isNotEmpty;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    scrollController.addListener(() {
      if (scrollController.offset <= 0 &&
          scrollController.position.userScrollDirection ==
              ScrollDirection.reverse) {
        Get.back();
      }
    });
  }

  @override
  void onClose() {
    commentController.dispose();
    focusNode.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
