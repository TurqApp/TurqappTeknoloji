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
    unawaited(_bootstrapComments());
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

  Future<void> _bootstrapComments() async {
    await fetchComments();
  }

  @override
  void onClose() {
    commentController.dispose();
    focusNode.dispose();
    scrollController.dispose();
    super.onClose();
  }

  Future<void> pickImage() async {
    try {
      final ctx = Get.context;
      if (ctx == null) return;
      final file = await AppImagePickerService.pickSingleImage(ctx);
      if (file != null) {
        selectedImage.value = file;
      }
    } catch (e) {
      log("Fotoğraf seçilirken hata: $e");
      AppSnackbar('common.error'.tr, 'training.photo_pick_failed'.tr);
    }
  }

  Future<String?> uploadImage(File image) async {
    try {
      return await WebpUploadService.uploadFileAsWebp(
        storage: FirebaseStorage.instance,
        file: image,
        storagePathWithoutExt:
            'comments/${question.docID}/${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      log("Fotoğraf yüklenirken hata: $e");
      AppSnackbar('common.error'.tr, 'training.photo_upload_failed'.tr);
      return null;
    }
  }

  Future<void> fetchComments({bool silent = false}) async {
    if (!silent || comments.isEmpty) {
      isLoading.value = true;
    }
    try {
      final fetchedComments = await _antremanRepository.fetchComments(
        question.docID,
      );
      final fetchedReplies = <String, List<Reply>>{};
      for (final comment in fetchedComments) {
        fetchedReplies[comment.docID] = await _antremanRepository.fetchReplies(
          question.docID,
          comment.docID,
        );
        repliesVisible[comment.docID] = repliesVisible[comment.docID] ?? false;
      }
      comments.assignAll(fetchedComments);
      replies.assignAll(fetchedReplies);
    } catch (e) {
      log("Yorumlar çekilirken hata: $e");
      AppSnackbar('common.error'.tr, 'training.comments_load_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchReplies(String commentDocID) async {
    try {
      replies[commentDocID] = await _antremanRepository.fetchReplies(
        question.docID,
        commentDocID,
      );
    } catch (e) {
      log("Yanıtlar çekilirken hata: $e");
    }
  }

  Future<Map<String, dynamic>> fetchUserInfo(String userID) async {
    if (userInfoCache.containsKey(userID)) {
      return userInfoCache[userID]!;
    }
    try {
      final data = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      if (data == null) {
        userInfoCache[userID] = {
          'avatarUrl': '',
          'nickname': 'training.unknown_user'.tr,
          'displayName': 'training.unknown_user'.tr,
        };
        return userInfoCache[userID]!;
      }
      final profileImage = data.avatarUrl;
      final profileName = data.preferredName.isNotEmpty
          ? data.preferredName
          : 'training.unknown_user'.tr;
      userInfoCache[userID] = {
        'avatarUrl': profileImage,
        'nickname': profileName,
        'username': data.username,
        'displayName': profileName,
      };
      return userInfoCache[userID]!;
    } catch (e) {
      log("Kullanıcı bilgisi alınırken hata: $e");
      userInfoCache[userID] = {
        'avatarUrl': '',
        'nickname': 'training.unknown_user'.tr,
        'displayName': 'training.unknown_user'.tr,
      };
      return userInfoCache[userID]!;
    }
  }

  Future<void> addComment() async {
    if (commentController.text.isEmpty && selectedImage.value == null) {
      AppSnackbar('common.error'.tr, 'training.comment_or_photo_required'.tr);
      return;
    }

    String? photoUrl;
    if (selectedImage.value != null) {
      photoUrl = await uploadImage(selectedImage.value!);
      if (photoUrl == null) return;
    }

    final newComment = Comment(
      docID: '',
      userID: userID,
      metin: commentController.text,
      timeStamp: DateTime.now().millisecondsSinceEpoch,
      begeniler: [],
      photoUrl: photoUrl,
    );

    try {
      await _antremanRepository.addComment(
        questionId: question.docID,
        comment: newComment,
      );
      commentController.clear();
      selectedImage.value = null;
      replyingToCommentDocID.value = '';
      editingCommentDocID.value = '';
      fetchComments();
      AppSnackbar('common.success'.tr, 'training.comment_added'.tr);
    } catch (e) {
      log("Yorum eklenirken hata: $e");
      AppSnackbar('common.error'.tr, 'training.comment_add_failed'.tr);
    }
  }

  Future<void> addReply(String commentDocID) async {
    if (commentController.text.isEmpty && selectedImage.value == null) {
      AppSnackbar('common.error'.tr, 'training.reply_or_photo_required'.tr);
      return;
    }

    String? photoUrl;
    if (selectedImage.value != null) {
      photoUrl = await uploadImage(selectedImage.value!);
      if (photoUrl == null) return;
    }

    final newReply = Reply(
      docID: '',
      userID: userID,
      metin: commentController.text,
      timeStamp: DateTime.now().millisecondsSinceEpoch,
      begeniler: [],
      photoUrl: photoUrl,
    );

    try {
      await _antremanRepository.addReply(
        questionId: question.docID,
        commentDocId: commentDocID,
        reply: newReply,
      );
      commentController.clear();
      selectedImage.value = null;
      replyingToCommentDocID.value = '';
      editingReplyDocID.value = '';
      fetchReplies(commentDocID);
      AppSnackbar('common.success'.tr, 'training.reply_added'.tr);
    } catch (e) {
      log("Yanıt eklenirken hata: $e");
      AppSnackbar('common.error'.tr, 'training.reply_add_failed'.tr);
    }
  }

  Future<void> deleteComment(String commentDocID) async {
    try {
      await _antremanRepository.deleteComment(
        questionId: question.docID,
        commentDocId: commentDocID,
      );
      fetchComments();
      AppSnackbar('common.success'.tr, 'training.comment_deleted'.tr);
    } catch (e) {
      log("Yorum silinirken hata: $e");
      AppSnackbar('common.error'.tr, 'training.comment_delete_failed'.tr);
    }
  }

  Future<void> deleteReply(String commentDocID, String replyDocID) async {
    try {
      await _antremanRepository.deleteReply(
        questionId: question.docID,
        commentDocId: commentDocID,
        replyDocId: replyDocID,
      );
      fetchReplies(commentDocID);
      AppSnackbar('common.success'.tr, 'training.reply_deleted'.tr);
    } catch (e) {
      log("Yanıt silinirken hata: $e");
      AppSnackbar('common.error'.tr, 'training.reply_delete_failed'.tr);
    }
  }

  Future<void> editComment(String commentDocID, String newText) async {
    try {
      await _antremanRepository.updateCommentText(
        questionId: question.docID,
        commentDocId: commentDocID,
        text: newText,
      );
      commentController.clear();
      editingCommentDocID.value = '';
      fetchComments();
      AppSnackbar('common.success'.tr, 'training.comment_updated'.tr);
    } catch (e) {
      log("Yorum düzenlenirken hata: $e");
      AppSnackbar('common.error'.tr, 'training.comment_update_failed'.tr);
    }
  }

  Future<void> editReply(
    String commentDocID,
    String replyDocID,
    String newText,
  ) async {
    try {
      await _antremanRepository.updateReplyText(
        questionId: question.docID,
        commentDocId: commentDocID,
        replyDocId: replyDocID,
        text: newText,
      );
      commentController.clear();
      editingReplyDocID.value = '';
      fetchReplies(commentDocID);
      AppSnackbar('common.success'.tr, 'training.reply_updated'.tr);
    } catch (e) {
      log("Yanıt düzenlenirken hata: $e");
      AppSnackbar('common.error'.tr, 'training.reply_update_failed'.tr);
    }
  }

  void cancelEditing() {
    editingCommentDocID.value = '';
    editingReplyDocID.value = '';
    replyingToCommentDocID.value = '';
    commentController.clear();
    selectedImage.value = null;
  }

  Future<void> toggleLikeComment(String commentDocID, Comment comment) async {
    final isLiked = comment.begeniler.contains(userID);
    try {
      await _antremanRepository.toggleLikeComment(
        questionId: question.docID,
        commentDocId: commentDocID,
        userId: userID,
        currentlyLiked: isLiked,
      );
      final updatedComment = Comment(
        docID: comment.docID,
        userID: comment.userID,
        metin: comment.metin,
        timeStamp: comment.timeStamp,
        begeniler: isLiked
            ? (List<String>.from(comment.begeniler)..remove(userID))
            : (List<String>.from(comment.begeniler)..add(userID)),
      );
      final index = comments.indexWhere((c) => c.docID == commentDocID);
      if (index != -1) {
        comments[index] = updatedComment;
      }
    } catch (e) {
      log("Yorum beğenilirken hata: $e");
      AppSnackbar('common.error'.tr, 'training.like_failed'.tr);
    }
  }

  Future<void> toggleLikeReply(
    String commentDocID,
    String replyDocID,
    Reply reply,
  ) async {
    final isLiked = reply.begeniler.contains(userID);
    try {
      await _antremanRepository.toggleLikeReply(
        questionId: question.docID,
        commentDocId: commentDocID,
        replyDocId: replyDocID,
        userId: userID,
        currentlyLiked: isLiked,
      );
      final updatedReplies = replies[commentDocID]!.map((r) {
        if (r.docID == replyDocID) {
          return Reply(
            docID: r.docID,
            userID: r.userID,
            metin: r.metin,
            timeStamp: r.timeStamp,
            begeniler: isLiked
                ? (List<String>.from(r.begeniler)..remove(userID))
                : (List<String>.from(r.begeniler)..add(userID)),
          );
        }
        return r;
      }).toList();
      replies[commentDocID] = updatedReplies;
    } catch (e) {
      log("Yanıt beğenilirken hata: $e");
      AppSnackbar('common.error'.tr, 'training.like_failed'.tr);
    }
  }

  void startEditingComment(String docID, String text) {
    editingCommentDocID.value = docID;
    editingReplyDocID.value = '';
    replyingToCommentDocID.value = '';
    commentController.text = text;
  }

  void startEditingReply(String commentDocID, String replyDocID, String text) {
    editingCommentDocID.value = '';
    editingReplyDocID.value = replyDocID;
    replyingToCommentDocID.value = commentDocID;
    commentController.text = text;
  }

  void toggleRepliesVisibility(String commentDocID) {
    repliesVisible[commentDocID] = !(repliesVisible[commentDocID] ?? false);
  }

  String getTimeAgo(int timeStamp) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = now - timeStamp;
    final seconds = (difference / 1000).floor();
    final minutes = (seconds / 60).floor();
    final hours = (minutes / 60).floor();
    final days = (hours / 24).floor();
    final weeks = (days / 7).floor();

    if (minutes < 1) {
      return 'training.time_now'.tr;
    } else if (minutes < 60) {
      return 'training.time_min'.trParams({'count': minutes.toString()});
    } else if (hours < 24) {
      return 'training.time_hour'.trParams({'count': hours.toString()});
    } else if (days < 7) {
      return 'training.time_day'.trParams({'count': days.toString()});
    } else {
      return 'training.time_week'.trParams({'count': weeks.toString()});
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final ctx = Get.context;
      if (ctx == null) return;
      final files = await AppImagePickerService.pickImages(ctx, maxAssets: 10);
      if (files.isEmpty) return;

      // NSFW tespiti (OptimizedNSFWService)
      for (final f in files) {
        final r = await OptimizedNSFWService.checkImage(f);
        if (r.isNSFW) {
          AppSnackbar(
            'training.upload_failed_title'.tr,
            'training.upload_failed_body'.tr,
            backgroundColor: Colors.red.withValues(alpha: 0.7),
          );
          return;
        }
      }

      // Her şey temizse state'i set et
      selectedImage.value = files.first; // İlk resmi al
    } catch (e) {
      log("Galeriden fotoğraf seçilirken hata: $e");
      AppSnackbar('common.error'.tr, 'training.photo_pick_failed'.tr);
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image == null) return;

      // Seçilen dosyayı File'a dönüştür
      final file = File(image.path);

      // NSFW tespiti (OptimizedNSFWService)
      final r = await OptimizedNSFWService.checkImage(file);
      if (r.isNSFW) {
        AppSnackbar(
            'training.upload_failed_title'.tr, 'training.upload_failed_body'.tr,
            backgroundColor: Colors.red.withValues(alpha: 0.7));
        return;
      }

      // Her şey temizse state'i set et
      selectedImage.value = file;
    } catch (e) {
      log("Fotoğraf çekilirken hata: $e");
      AppSnackbar('common.error'.tr, 'training.photo_pick_failed'.tr);
    }
  }
}
