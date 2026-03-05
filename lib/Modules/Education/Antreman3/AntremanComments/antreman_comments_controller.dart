import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Models/Education/question_bank_model.dart';

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
  final QuestionBankModel question;
  final String userID = FirebaseAuth.instance.currentUser?.uid ?? '';
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
  final Rx<File?> selectedImage = Rx<File?>(null);
  final ImagePicker picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    fetchComments();
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
      AppSnackbar("Hata", "Fotoğraf seçilirken bir hata oluştu!");
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
      AppSnackbar("Hata", "Fotoğraf yüklenirken bir hata oluştu!");
      return null;
    }
  }

  Future<void> fetchComments() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('questionBank')
          .doc(question.docID)
          .collection('Yorumlar')
          .orderBy('timeStamp', descending: true)
          .get();

      comments.clear();
      for (var doc in snapshot.docs) {
        final comment = Comment.fromJson(doc.id, doc.data());
        comments.add(comment);
        fetchReplies(doc.id);
        repliesVisible[doc.id] = false;
      }
    } catch (e) {
      log("Yorumlar çekilirken hata: $e");
      AppSnackbar(
        "Hata",
        "Yorumlar yüklenirken bir hata oluştu. Lütfen tekrar deneyin!",
      );
    }
  }

  Future<void> fetchReplies(String commentDocID) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('questionBank')
          .doc(question.docID)
          .collection('Yorumlar')
          .doc(commentDocID)
          .collection('Yanitlar')
          .orderBy('timeStamp', descending: true)
          .get();

      final replyList = <Reply>[];
      for (var doc in snapshot.docs) {
        replyList.add(Reply.fromJson(doc.id, doc.data()));
      }
      replies[commentDocID] = replyList;
    } catch (e) {
      log("Yanıtlar çekilirken hata: $e");
    }
  }

  Future<Map<String, dynamic>> fetchUserInfo(String userID) async {
    if (userInfoCache.containsKey(userID)) {
      return userInfoCache[userID]!;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .get();
      final data = doc.data();
      log("User data for $userID: ${doc.data()}");
      if (data == null) {
        userInfoCache[userID] = {
          'pfImage': '',
          'avatarUrl': '',
          'nickname': 'Bilinmeyen Kullanıcı',
          'displayName': 'Bilinmeyen Kullanıcı',
        };
        return userInfoCache[userID]!;
      }
      final profileImage = (data['avatarUrl'] ??
              data['pfImage'] ??
              data['photoURL'] ??
              data['profileImageUrl'] ??
              '')
          .toString();
      final profileName = (data['displayName'] ??
              data['username'] ??
              data['nickname'] ??
              'Bilinmeyen Kullanıcı')
          .toString();
      userInfoCache[userID] = {
        'pfImage': profileImage,
        'avatarUrl': profileImage,
        'nickname': profileName,
        'username': (data['username'] ?? '').toString(),
        'displayName': profileName,
      };
      return userInfoCache[userID]!;
    } catch (e) {
      log("Kullanıcı bilgisi alınırken hata: $e");
      userInfoCache[userID] = {
        'pfImage': '',
        'avatarUrl': '',
        'nickname': 'Bilinmeyen Kullanıcı',
        'displayName': 'Bilinmeyen Kullanıcı',
      };
      return userInfoCache[userID]!;
    }
  }

  Future<void> addComment() async {
    if (commentController.text.isEmpty && selectedImage.value == null) {
      AppSnackbar("Hata", "Yorum veya fotoğraf eklemelisiniz!");
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
      await FirebaseFirestore.instance
          .collection('questionBank')
          .doc(question.docID)
          .collection('Yorumlar')
          .add(newComment.toJson());
      commentController.clear();
      selectedImage.value = null;
      replyingToCommentDocID.value = '';
      editingCommentDocID.value = '';
      fetchComments();
      AppSnackbar("Başarılı", "Yorumunuz eklendi!");
    } catch (e) {
      log("Yorum eklenirken hata: $e");
      AppSnackbar(
        "Hata",
        "Yorum eklenirken bir hata oluştu. Lütfen tekrar deneyin!",
      );
    }
  }

  Future<void> addReply(String commentDocID) async {
    if (commentController.text.isEmpty && selectedImage.value == null) {
      AppSnackbar("Hata", "Yanıt veya fotoğraf eklemelisiniz!");
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
      await FirebaseFirestore.instance
          .collection('questionBank')
          .doc(question.docID)
          .collection('Yorumlar')
          .doc(commentDocID)
          .collection('Yanitlar')
          .add(newReply.toJson());
      commentController.clear();
      selectedImage.value = null;
      replyingToCommentDocID.value = '';
      editingReplyDocID.value = '';
      fetchReplies(commentDocID);
      AppSnackbar("Başarılı", "Yanıtınız eklendi!");
    } catch (e) {
      log("Yanıt eklenirken hata: $e");
      AppSnackbar(
        "Hata",
        "Yanıt eklenirken bir hata oluştu. Lütfen tekrar deneyin!",
      );
    }
  }

  Future<void> deleteComment(String commentDocID) async {
    try {
      await FirebaseFirestore.instance
          .collection('questionBank')
          .doc(question.docID)
          .collection('Yorumlar')
          .doc(commentDocID)
          .delete();
      fetchComments();
      AppSnackbar("Başarılı", "Yorumunuz silindi!");
    } catch (e) {
      log("Yorum silinirken hata: $e");
      AppSnackbar(
        "Hata",
        "Yorum silinirken bir hata oluştu. Lütfen tekrar deneyin!",
      );
    }
  }

  Future<void> deleteReply(String commentDocID, String replyDocID) async {
    try {
      await FirebaseFirestore.instance
          .collection('questionBank')
          .doc(question.docID)
          .collection('Yorumlar')
          .doc(commentDocID)
          .collection('Yanitlar')
          .doc(replyDocID)
          .delete();
      fetchReplies(commentDocID);
      AppSnackbar("Başarılı", "Yanıtınız silindi!");
    } catch (e) {
      log("Yanıt silinirken hata: $e");
      AppSnackbar(
        "Hata",
        "Yanıt silinirken bir hata oluştu. Lütfen tekrar deneyin!",
      );
    }
  }

  Future<void> editComment(String commentDocID, String newText) async {
    try {
      await FirebaseFirestore.instance
          .collection('questionBank')
          .doc(question.docID)
          .collection('Yorumlar')
          .doc(commentDocID)
          .update({'metin': newText});
      commentController.clear();
      editingCommentDocID.value = '';
      fetchComments();
      AppSnackbar("Başarılı", "Yorumunuz güncellendi!");
    } catch (e) {
      log("Yorum düzenlenirken hata: $e");
      AppSnackbar(
        "Hata",
        "Yorum düzenlenirken bir hata oluştu. Lütfen tekrar deneyin!",
      );
    }
  }

  Future<void> editReply(
    String commentDocID,
    String replyDocID,
    String newText,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('questionBank')
          .doc(question.docID)
          .collection('Yorumlar')
          .doc(commentDocID)
          .collection('Yanitlar')
          .doc(replyDocID)
          .update({'metin': newText});
      commentController.clear();
      editingReplyDocID.value = '';
      fetchReplies(commentDocID);
      AppSnackbar("Başarılı", "Yanıtınız güncellendi!");
    } catch (e) {
      log("Yanıt düzenlenirken hata: $e");
      AppSnackbar(
        "Hata",
        "Yanıt düzenlenirken bir hata oluştu. Lütfen tekrar deneyin!",
      );
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
      await FirebaseFirestore.instance
          .collection('questionBank')
          .doc(question.docID)
          .collection('Yorumlar')
          .doc(commentDocID)
          .update({
        'begeniler': isLiked
            ? FieldValue.arrayRemove([userID])
            : FieldValue.arrayUnion([userID]),
      });
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
      AppSnackbar(
        "Hata",
        "Beğeni işlemi sırasında bir hata oluştu. Lütfen tekrar deneyin!",
      );
    }
  }

  Future<void> toggleLikeReply(
    String commentDocID,
    String replyDocID,
    Reply reply,
  ) async {
    final isLiked = reply.begeniler.contains(userID);
    try {
      await FirebaseFirestore.instance
          .collection('questionBank')
          .doc(question.docID)
          .collection('Yorumlar')
          .doc(commentDocID)
          .collection('Yanitlar')
          .doc(replyDocID)
          .update({
        'begeniler': isLiked
            ? FieldValue.arrayRemove([userID])
            : FieldValue.arrayUnion([userID]),
      });
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
      AppSnackbar(
        "Hata",
        "Beğeni işlemi sırasında bir hata oluştu. Lütfen tekrar deneyin!",
      );
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
      return 'az önce';
    } else if (minutes < 60) {
      return '$minutes dk önce';
    } else if (hours < 24) {
      return '$hours saat önce';
    } else if (days < 7) {
      return '$days gün önce';
    } else {
      return '$weeks hafta önce';
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
            "Yükleme Başarısız!",
            "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
            backgroundColor: Colors.red.withValues(alpha: 0.7),
          );
          return;
        }
      }

      // Her şey temizse state'i set et
      selectedImage.value = files.first; // İlk resmi al
    } catch (e) {
      log("Galeriden fotoğraf seçilirken hata: $e");
      AppSnackbar("Hata", "Fotoğraf seçilirken bir hata oluştu!");
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
        AppSnackbar("Yükleme Başarısız!",
            "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
            backgroundColor: Colors.red.withValues(alpha: 0.7));
        return;
      }

      // Her şey temizse state'i set et
      selectedImage.value = file;
    } catch (e) {
      log("Fotoğraf çekilirken hata: $e");
      AppSnackbar("Hata", "Fotoğraf çekilirken bir hata oluştu!");
    }
  }
}
