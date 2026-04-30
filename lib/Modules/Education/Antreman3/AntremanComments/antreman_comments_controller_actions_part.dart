part of 'antreman_comments_controller.dart';

extension AntremanCommentsControllerActionsPart on AntremanCommentsController {
  Future<void> pickImage() async {
    try {
      final ctx = Get.context;
      if (ctx == null) return;
      final file = await AppImagePickerService.pickSingleImage(ctx);
      if (file != null) {
        selectedImage.value = file;
      }
    } catch (e) {
      log('Fotograf secilirken hata: $e');
      AppSnackbar('common.error'.tr, 'training.photo_pick_failed'.tr);
    }
  }

  Future<String?> uploadImage(File image) async {
    try {
      return await WebpUploadService.uploadFileAsWebp(
        file: image,
        storagePathWithoutExt:
            'comments/${question.docID}/${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      log('Fotograf yuklenirken hata: $e');
      AppSnackbar('common.error'.tr, 'training.photo_upload_failed'.tr);
      return null;
    }
  }

  Future<void> addComment() async {
    if (commentController.text.isEmpty && selectedImage.value == null) {
      AppSnackbar('common.error'.tr, 'training.comment_or_photo_required'.tr);
      return;
    }
    if (!await TextModerationService.ensureAllowed([commentController.text])) {
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
      log('Yorum eklenirken hata: $e');
      AppSnackbar('common.error'.tr, 'training.comment_add_failed'.tr);
    }
  }

  Future<void> addReply(String commentDocID) async {
    if (commentController.text.isEmpty && selectedImage.value == null) {
      AppSnackbar('common.error'.tr, 'training.reply_or_photo_required'.tr);
      return;
    }
    if (!await TextModerationService.ensureAllowed([commentController.text])) {
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
      log('Yanit eklenirken hata: $e');
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
      log('Yorum silinirken hata: $e');
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
      log('Yanit silinirken hata: $e');
      AppSnackbar('common.error'.tr, 'training.reply_delete_failed'.tr);
    }
  }

  Future<void> editComment(String commentDocID, String newText) async {
    if (!await TextModerationService.ensureAllowed([newText])) {
      return;
    }
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
      log('Yorum duzenlenirken hata: $e');
      AppSnackbar('common.error'.tr, 'training.comment_update_failed'.tr);
    }
  }

  Future<void> editReply(
    String commentDocID,
    String replyDocID,
    String newText,
  ) async {
    if (!await TextModerationService.ensureAllowed([newText])) {
      return;
    }
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
      log('Yanit duzenlenirken hata: $e');
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
      log('Yorum begenilirken hata: $e');
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
      log('Yanit begenilirken hata: $e');
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

  Future<void> pickImageFromGallery() async {
    try {
      final ctx = Get.context;
      if (ctx == null) return;
      final files = await AppImagePickerService.pickImages(ctx, maxAssets: 10);
      if (files.isEmpty) return;

      for (final file in files) {
        final result = await OptimizedNSFWService.checkImage(file);
        if (result.isNSFW) {
          AppSnackbar(
            'training.upload_failed_title'.tr,
            'training.upload_failed_body'.tr,
            backgroundColor: Colors.red.withValues(alpha: 0.7),
          );
          return;
        }
      }

      selectedImage.value = files.first;
    } catch (e) {
      log('Galeriden fotograf secilirken hata: $e');
      AppSnackbar('common.error'.tr, 'training.photo_pick_failed'.tr);
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image == null) return;

      final file = File(image.path);
      final result = await OptimizedNSFWService.checkImage(file);
      if (result.isNSFW) {
        AppSnackbar(
          'training.upload_failed_title'.tr,
          'training.upload_failed_body'.tr,
          backgroundColor: Colors.red.withValues(alpha: 0.7),
        );
        return;
      }

      selectedImage.value = file;
    } catch (e) {
      log('Fotograf cekilirken hata: $e');
      AppSnackbar('common.error'.tr, 'training.photo_pick_failed'.tr);
    }
  }
}
