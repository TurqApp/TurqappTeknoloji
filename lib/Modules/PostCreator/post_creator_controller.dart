// PostCreatorController.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/upload_constants.dart';
import 'package:video_player/video_player.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../Agenda/agenda_controller.dart';
import '../NavBar/nav_bar_controller.dart';
import 'CreatorContent/post_creator_model.dart';
import 'CreatorContent/creator_content_controller.dart';
import '../../Core/BottomSheets/future_date_picker_bottom_sheet.dart';
import '../../Core/Services/upload_validation_service.dart';
import '../../Core/Services/error_handling_service.dart';
import '../../Core/Services/network_awareness_service.dart';
import '../../Core/Services/upload_queue_service.dart';
import '../../Core/Services/draft_service.dart';
import '../../Core/Widgets/progress_indicators.dart';
import '../../Core/Services/optimized_nsfw_service.dart';
import '../../Core/Services/webp_upload_service.dart';

class PreparedPostModel {
  final String text;
  final List<Uint8List> images;
  final List<String> reusedImageUrls;
  final double reusedImageAspectRatio;
  final File? video;
  final String reusedVideoUrl;
  final String reusedVideoThumbnail;
  final double reusedVideoAspectRatio;
  final String location;
  final String gif;
  final Uint8List? customThumbnail;
  final Map<String, dynamic> poll;

  PreparedPostModel({
    required this.text,
    required this.images,
    required this.reusedImageUrls,
    required this.reusedImageAspectRatio,
    required this.video,
    required this.reusedVideoUrl,
    required this.reusedVideoThumbnail,
    required this.reusedVideoAspectRatio,
    required this.location,
    required this.gif,
    required this.customThumbnail,
    required this.poll,
  });

  Map<String, dynamic> toMap({required String docID}) => {
        'id': docID,
        'text': text,
        'location': location,
        'gif': gif,
        'timeStamp': DateTime.now().millisecondsSinceEpoch,
      };
}

class PostCreatorController extends GetxController with WidgetsBindingObserver {
  static const int _maxVideoBytesForStorageRule = 35 * 1024 * 1024;
  RxList<PostCreatorModel> postList =
      <PostCreatorModel>[PostCreatorModel(index: 0, text: "")].obs;
  final RxBool isKeyboardOpen = false.obs;
  var selectedIndex = 0.obs;
  final agendaController = Get.find<AgendaController>();
  var comment = true.obs;
  // 0: Herkes, 1: Onaylı hesaplar, 2: Takip ettiğin hesaplar
  var commentVisibility = 0.obs;
  var paylasimSelection = 0.obs;
  // 0: Şimdi Paylaş, 1: İleri Tarihe İz Bırak
  var publishMode = 0.obs;
  Rx<DateTime?> izBirakDateTime = Rx<DateTime?>(null);

  // Services
  late final ErrorHandlingService _errorService;
  late final NetworkAwarenessService _networkService;
  late final UploadQueueService _uploadQueueService;
  late final DraftService _draftService;
  bool _sharedSourceApplied = false;
  bool _isSharedAsPost = false;
  String _sharedOriginalUserID = "";
  String _sharedOriginalPostID = "";
  bool _isQuotedPost = false;
  String _quotedOriginalText = "";
  String _quotedSourceUserID = "";
  String _quotedSourceDisplayName = "";
  String _quotedSourceUsername = "";
  String _quotedSourceAvatarUrl = "";
  bool _editSourceApplied = false;
  final RxBool isEditMode = false.obs;
  final RxString editingPostID = ''.obs;
  final RxBool isSavingEdit = false.obs;

  Timer? _autoSaveTimer;
  Timer? _queueRingTimer;

  bool get isQuotedPost => _isQuotedPost;
  String get quotedOriginalText => _quotedOriginalText;
  String get quotedSourceUserID => _quotedSourceUserID;
  String get quotedSourceDisplayName => _quotedSourceDisplayName;
  String get quotedSourceUsername => _quotedSourceUsername;
  String get quotedSourceAvatarUrl => _quotedSourceAvatarUrl;
  String get sharedOriginalUserID => _sharedOriginalUserID;
  String get sharedOriginalPostID => _sharedOriginalPostID;

  String _resolvePostLocationCity() {
    final user = CurrentUserService.instance.currentUserRx.value;
    final candidates = [
      user?.locationSehir,
      user?.city,
      user?.ikametSehir,
      user?.il,
      user?.ulke,
    ];
    for (final raw in candidates) {
      final value = (raw ?? '').trim();
      if (value.isNotEmpty) return value;
    }
    return 'Türkiye';
  }

  bool _isAuthRetryableStorageError(FirebaseException e) {
    final code = e.code.toLowerCase();
    return code == 'unauthenticated' || code == 'unauthorized';
  }

  Future<String?> _ensureStorageUploadAuthReady() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      try {
        user = await FirebaseAuth.instance.authStateChanges().firstWhere(
              (candidate) => candidate != null,
            );
      } catch (_) {
        user = FirebaseAuth.instance.currentUser;
      }
    }
    if (user == null) return null;
    try {
      await user.getIdToken(true);
    } catch (_) {
      // Best effort refresh only.
    }
    return user.uid;
  }

  Future<void> _refreshAuthTokenIfNeeded() async {
    try {
      await _ensureStorageUploadAuthReady();
    } catch (_) {
      // Best effort refresh only.
    }
  }

  Future<void> _preparePostShellForStorageUpload({
    required String docID,
    required String uid,
    required int nowMs,
  }) async {
    final ref = FirebaseFirestore.instance.collection("Posts").doc(docID);
    await ref.set({
      "userID": uid,
      "timeStamp": nowMs,
      "isUploading": true,
      "hlsStatus": "none",
    }, SetOptions(merge: true));
    await FirebaseFirestore.instance.waitForPendingWrites();

    const retryDelays = <Duration>[
      Duration(milliseconds: 250),
      Duration(milliseconds: 700),
      Duration(milliseconds: 1400),
    ];

    for (var attempt = 0; attempt <= retryDelays.length; attempt++) {
      try {
        final snap = await ref.get(const GetOptions(source: Source.server));
        final shellUserId = (snap.data()?["userID"] ?? '').toString();
        if (kDebugMode) {
          debugPrint('[UploadPreflight][PostShell] '
              'docID=$docID '
              'uid=$uid '
              'serverExists=${snap.exists} '
              'serverUserID=$shellUserId '
              'attempt=$attempt');
        }
        if (snap.exists && shellUserId == uid) {
          return;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[UploadPreflight][PostShell] '
              'docID=$docID '
              'uid=$uid '
              'serverReadFailed=$e '
              'attempt=$attempt');
        }
      }

      if (attempt < retryDelays.length) {
        await Future<void>.delayed(retryDelays[attempt]);
      }
    }
  }

  Future<TaskSnapshot> _putFileWithAuthRetry({
    required Reference ref,
    required File file,
    required SettableMetadata metadata,
  }) async {
    const retryDelays = <Duration>[
      Duration(milliseconds: 250),
      Duration(milliseconds: 700),
      Duration(milliseconds: 1400),
    ];

    FirebaseException? lastError;
    for (var attempt = 0; attempt <= retryDelays.length; attempt++) {
      try {
        return await ref.putFile(file, metadata);
      } on FirebaseException catch (e) {
        if (!_isAuthRetryableStorageError(e)) rethrow;
        lastError = e;
        if (attempt == retryDelays.length) break;
        await _refreshAuthTokenIfNeeded();
        await Future<void>.delayed(retryDelays[attempt]);
      }
    }
    throw lastError!;
  }

  NavBarController? _maybeNavBarController() {
    if (!Get.isRegistered<NavBarController>()) return null;
    return Get.find<NavBarController>();
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _startAutoSave();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveTimer?.cancel();
    _queueRingTimer?.cancel();
    _saveCurrentDraft(); // Save before closing
    super.onClose();
  }

  @override
  void didChangeMetrics() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final bottomInset = view.viewInsets.bottom;
    isKeyboardOpen.value = bottomInset > 10;
  }

  Future<void> applySharedSourceIfNeeded({
    required String videoUrl,
    required List<String> imageUrls,
    required double aspectRatio,
    required String thumbnail,
    required bool sharedAsPost,
    String? originalUserID,
    String? originalPostID,
    bool quotedPost = false,
    String? quotedOriginalText,
    String? quotedSourceUserID,
    String? quotedSourceDisplayName,
    String? quotedSourceUsername,
    String? quotedSourceAvatarUrl,
  }) async {
    final cleanUrl = videoUrl.trim();
    final cleanImages =
        imageUrls.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (!sharedAsPost) {
      _sharedSourceApplied = false;
      _isSharedAsPost = false;
      _sharedOriginalUserID = "";
      _sharedOriginalPostID = "";
      _isQuotedPost = false;
      _quotedOriginalText = "";
      _quotedSourceUserID = "";
      _quotedSourceDisplayName = "";
      _quotedSourceUsername = "";
      _quotedSourceAvatarUrl = "";
      return;
    }
    if (_sharedSourceApplied) return;
    _sharedSourceApplied = true;

    _isSharedAsPost = true;
    _sharedOriginalUserID = (originalUserID ?? '').trim();
    _sharedOriginalPostID = (originalPostID ?? '').trim();
    _isQuotedPost = quotedPost;
    _quotedOriginalText = (quotedOriginalText ?? '').trim();
    _quotedSourceUserID = (quotedSourceUserID ?? '').trim();
    _quotedSourceDisplayName = (quotedSourceDisplayName ?? '').trim();
    _quotedSourceUsername = (quotedSourceUsername ?? '').trim();
    _quotedSourceAvatarUrl = (quotedSourceAvatarUrl ?? '').trim();

    const tag = '0';
    if (!Get.isRegistered<CreatorContentController>(tag: tag)) {
      Get.put(CreatorContentController(), tag: tag);
    }
    final c = Get.find<CreatorContentController>(tag: tag);
    if (cleanUrl.isNotEmpty) {
      await c.setReusedVideoSource(
        videoUrl: cleanUrl,
        aspectRatio: aspectRatio,
        thumbnail: thumbnail,
      );
    } else {
      if (cleanImages.isNotEmpty) {
        await c.setReusedImageSources(
          cleanImages,
          aspectRatio: aspectRatio,
        );
      }
    }
  }

  Future<void> applyEditSourceIfNeeded({
    required bool editMode,
    required PostsModel? editPost,
  }) async {
    if (!editMode || editPost == null) return;
    if (_editSourceApplied && editingPostID.value == editPost.docID) return;
    _editSourceApplied = true;

    isEditMode.value = true;
    editingPostID.value = editPost.docID;

    // Edit modunda tek gönderi düzenlenir.
    postList.value = [PostCreatorModel(index: 0, text: editPost.metin)];
    selectedIndex.value = 0;

    // Yorum / yeniden paylaş görünürlüğünü mevcut posttan doldur.
    commentVisibility.value = editPost.yorumVisibility;
    comment.value = commentVisibility.value != 3;
    paylasimSelection.value = editPost.paylasimVisibility;

    const tag = '0';
    if (!Get.isRegistered<CreatorContentController>(tag: tag)) {
      Get.put(CreatorContentController(), tag: tag);
    }
    final c = Get.find<CreatorContentController>(tag: tag);
    c.textEdit.text = editPost.metin;
    c.textEdit.selection = TextSelection.fromPosition(
      TextPosition(offset: c.textEdit.text.length),
    );
  }

  Future<bool> savePostEdit() async {
    if (isSavingEdit.value) return false;
    final docID = editingPostID.value.trim();
    if (docID.isEmpty) {
      AppSnackbar('Hata', 'Düzenlenecek gönderi bulunamadı');
      return false;
    }

    const tag = '0';
    if (!Get.isRegistered<CreatorContentController>(tag: tag)) {
      AppSnackbar('Hata', 'Düzenleme içeriği bulunamadı');
      return false;
    }

    final c = Get.find<CreatorContentController>(tag: tag);
    final text = c.textEdit.text.trim();
    final now = DateTime.now().millisecondsSinceEpoch;

    final yorumVisible = commentVisibility.value.clamp(0, 3);
    final reshVisible = paylasimSelection.value.clamp(0, 2);

    final update = <String, dynamic>{
      'metin': text,
      'editTime': now,
      'yorum': yorumVisible != 3,
      'yorumMap': {'visibility': yorumVisible},
      'paylasGizliligi': reshVisible,
      'reshareMap': {'visibility': reshVisible},
    };

    try {
      isSavingEdit.value = true;
      final postsRef = FirebaseFirestore.instance.collection('Posts');
      String targetDocID = docID;

      try {
        await postsRef.doc(targetDocID).update(update);
      } on FirebaseException catch (e) {
        if (e.code != 'not-found') rethrow;

        // Eski/veri uyumsuz kayıtlar için: id alanından gerçek belgeyi bul.
        final byId =
            await postsRef.where('id', isEqualTo: docID).limit(1).get();
        if (byId.docs.isEmpty) {
          rethrow;
        }
        targetDocID = byId.docs.first.id;
        await postsRef.doc(targetDocID).update(update);
      }

      // Feed üzerinde anlık güncelle
      if (Get.isRegistered<AgendaController>()) {
        final agenda = Get.find<AgendaController>();
        final idx = agenda.agendaList
            .indexWhere((e) => e.docID == docID || e.docID == targetDocID);
        if (idx != -1) {
          final old = agenda.agendaList[idx];
          agenda.agendaList[idx] = old.copyWith(
            metin: text,
            editTime: now,
            yorum: yorumVisible != 3,
            yorumMap: {'visibility': yorumVisible},
            paylasGizliligi: reshVisible,
            reshareMap: {'visibility': reshVisible},
          );
          agenda.agendaList.refresh();
        }
      }

      try {
        if (Get.isRegistered<ProfileController>()) {
          Get.find<ProfileController>().fetchPosts(isInitial: true);
        }
      } catch (_) {}

      AppSnackbar('Başarılı', 'Gönderi güncellendi');
      return true;
    } catch (e) {
      String msg = 'Gönderi güncellenemedi';
      if (e is FirebaseException &&
          e.message != null &&
          e.message!.trim().isNotEmpty) {
        msg = e.message!.trim();
      }
      AppSnackbar('Hata', msg);
      if (kDebugMode) {
        debugPrint('savePostEdit error: $e');
      }
      return false;
    } finally {
      isSavingEdit.value = false;
    }
  }

  void uploadAllPostsInBackground() async {
    final progressController = Get.find<UploadProgressController>();
    // Comprehensive validation before upload
    final allImages = <File>[];
    final allVideos = <File>[];
    final allTexts = <String>[];
    bool hasReusedVideo = false;
    bool hasReusedImages = false;

    // Collect all content from posts
    for (final postModel in postList) {
      final tag = postModel.index.toString();
      if (!Get.isRegistered<CreatorContentController>(tag: tag)) {
        Get.put(CreatorContentController(), tag: tag);
      }
      final c = Get.find<CreatorContentController>(tag: tag);

      // Collect images
      allImages.addAll(c.selectedImages);

      // Collect videos
      if (c.selectedVideo.value != null) {
        allVideos.add(c.selectedVideo.value!);
      }
      if (c.reusedVideoUrl.value.trim().isNotEmpty) {
        hasReusedVideo = true;
      }
      if (c.reusedImageUrls.isNotEmpty) {
        hasReusedImages = true;
      }

      // Collect texts
      final text = c.textEdit.text.trim();
      if (text.isNotEmpty) {
        allTexts.add(text);
      }
    }

    // Final comprehensive validation
    final validation = await UploadValidationService.validatePost(
      images: allImages,
      videos: allVideos,
      text: (hasReusedVideo || hasReusedImages) ? 'media' : allTexts.join(' '),
    );

    if (!validation.isValid) {
      UploadValidationService.showValidationError(validation.errorMessage!);
      return;
    }

    Get.back();

    // Start progress indicator
    final totalPosts = postList.length;
    progressController.startProgress(
      total: totalPosts,
      initialStatus: 'Gönderiler hazırlanıyor...',
    );

    // NavBar profil ikonunda yükleme göstergisi
    final nav = _maybeNavBarController();
    nav?.uploadingPosts.value = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uploadedPosts = await uploadAllPosts(progressController);

      if (uploadedPosts.isNotEmpty) {
        final agendaController = Get.find<AgendaController>();
        await Future.delayed(const Duration(milliseconds: 150));
        // Sadece şu an yayınlananları (timeStamp <= now) öne ekle
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final nowPosts =
            uploadedPosts.where((e) => e.timeStamp <= nowMs).toList();
        if (nowPosts.isNotEmpty) {
          final ids = nowPosts.map((e) => e.docID).toList();
          agendaController.markHighlighted(ids);
          agendaController.addUploadedPostsAtTop(nowPosts);
        }
        if (agendaController.scrollController.hasClients) {
          agendaController.scrollController.jumpTo(0);
        }
        Get.find<ProfileController>().getLastPostAndAddToAllPosts();

        // Complete progress
        progressController.complete('Gönderiler başarıyla yayınlandı!');
      } else {
        progressController.setError('Gönderi yüklenirken hata oluştu.');
      }

      nav?.uploadingPosts.value = false;
    });
  }

  Future<void> showCommentOptions() async {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Obx(() {
          Widget optionTile({
            required String title,
            required IconData icon,
            required bool selected,
            required VoidCallback onTap,
          }) {
            return GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.white.withAlpha(1),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ),
                    if (selected)
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.checkmark,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(80),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Text(
                "Kimler yanıtlayabilir?",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: "MontserratBold",
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Bu gönderiyi kimlerin yanıtlayabileceğini seç.",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontFamily: "MontserratMedium",
                ),
              ),
              const SizedBox(height: 14),
              optionTile(
                title: "Herkes",
                icon: CupertinoIcons.globe,
                selected: commentVisibility.value == 0,
                onTap: () {
                  commentVisibility.value = 0;
                  comment.value = true;
                },
              ),
              optionTile(
                title: "Onaylı hesaplar",
                icon: CupertinoIcons.checkmark_seal,
                selected: commentVisibility.value == 1,
                onTap: () {
                  commentVisibility.value = 1;
                  comment.value = true;
                },
              ),
              optionTile(
                title: "Takip ettiğin hesaplar",
                icon: CupertinoIcons.person_2,
                selected: commentVisibility.value == 2,
                onTap: () {
                  commentVisibility.value = 2;
                  comment.value = true;
                },
              ),
              optionTile(
                title: "Yoruma kapalı",
                icon: CupertinoIcons.chat_bubble_text,
                selected: commentVisibility.value == 3,
                onTap: () {
                  commentVisibility.value = 3;
                  comment.value = false;
                },
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> showReshareSets() async {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Obx(() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
                  SizedBox(width: 12),
                  Text(
                    "Yeniden Paylaş Gizliliği",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
                ],
              ),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  paylasimSelection.value = 0;
                },
                child: Container(
                  color: Colors.white.withAlpha(1),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Herkes yeniden paylaşabilir.",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                      Container(
                        width: 25,
                        height: 25,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: paylasimSelection.value == 0
                                  ? Colors.black
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  paylasimSelection.value = 1;
                },
                child: Container(
                  color: Colors.white.withAlpha(1),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Sadece takipçilerim yeniden paylaşabilir.",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                      Container(
                        width: 25,
                        height: 25,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: paylasimSelection.value == 1
                                  ? Colors.black
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  paylasimSelection.value = 2;
                },
                child: Container(
                  color: Colors.white.withAlpha(1),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Paylaşıma kapalı.",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                      Container(
                        width: 25,
                        height: 25,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: paylasimSelection.value == 2
                                  ? Colors.black
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
            ],
          );
        }),
      ),
    );
  }

  Future<void> showPublishModePicker() async {
    // İstenen davranış: Saat ikonuna basınca doğrudan tarih/zaman seçim bottom sheet'i açılsın.
    // Kullanıcı tarih seçerse programlı paylaşım aktif olur; iptal ederse mevcut durum korunur (şimdi paylaş).
    Get.bottomSheet(
      FutureDatePickerBottomSheet(
        initialDate: DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day + 1,
        ),
        withTime: true,
        onSelected: (v) {
          publishMode.value = 1;
          izBirakDateTime.value = v;
        },
        title: "Yayın Tarihini Seç",
      ),
      isScrollControlled: true,
    );
  }

  Future<List<PostsModel>> uploadAllPosts(
      UploadProgressController progressController) async {
    final allPosts = <PreparedPostModel>[];
    final uploadedPosts = <PostsModel>[];
    final uuid = const Uuid().v4();

    for (var postModel in postList) {
      final tag = postModel.index.toString();
      if (!Get.isRegistered<CreatorContentController>(tag: tag)) continue;

      final contentController = Get.find<CreatorContentController>(tag: tag);
      final text = contentController.textEdit.text.trim();
      final images =
          contentController.croppedImages.whereType<Uint8List>().toList();
      final reusedImageUrls = contentController.reusedImageUrls.toList();
      final reusedImageAspectRatio =
          contentController.reusedImageAspectRatio.value;
      final video = contentController.selectedVideo.value;
      final reusedVideoUrl = contentController.reusedVideoUrl.value;
      final reusedVideoThumbnail = contentController.reusedVideoThumbnail.value;
      final reusedVideoAspectRatio =
          contentController.reusedVideoAspectRatio.value;
      final location = contentController.adres.value;
      final gif = contentController.gif.value;
      final customThumb = contentController.selectedThumbnail.value;
      final poll = contentController.pollData.value ?? const {};

      allPosts.add(
        PreparedPostModel(
          text: text,
          images: images,
          reusedImageUrls: reusedImageUrls,
          reusedImageAspectRatio: reusedImageAspectRatio,
          video: video,
          reusedVideoUrl: reusedVideoUrl,
          reusedVideoThumbnail: reusedVideoThumbnail,
          reusedVideoAspectRatio: reusedVideoAspectRatio,
          location: location,
          gif: gif,
          customThumbnail: customThumb,
          poll: poll,
        ),
      );
    }

    final allHashtags = <String>{};

    for (int index = 0; index < allPosts.length; index++) {
      final post = allPosts[index];
      final docID = '${uuid}_$index';
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final uid = await _ensureStorageUploadAuthReady() ??
          FirebaseAuth.instance.currentUser!.uid;

      // Storage rules require Posts/{docID}.userID to exist before media upload.
      await _preparePostShellForStorageUpload(
        docID: docID,
        uid: uid,
        nowMs: nowMs,
      );

      // Update progress
      progressController.updateProgress(
        current: index + 1,
        fileName: 'Gönderi ${index + 1}',
        statusText: 'Medya dosyaları yükleniyor...',
      );

      final imageUrls = <String>[];
      var videoUrl = "";
      var thumbnailUrl = "";
      final isReusedVideoPost =
          post.video == null && post.reusedVideoUrl.trim().isNotEmpty;
      final isReusedImagePost = post.video == null &&
          post.images.isEmpty &&
          post.reusedImageUrls.isNotEmpty;

      if (isReusedImagePost) {
        imageUrls.addAll(post.reusedImageUrls.map(CdnUrlBuilder.toCdnUrl));
      } else {
        for (int j = 0; j < post.images.length; j++) {
          if (kDebugMode) {
            final postDoc = await FirebaseFirestore.instance
                .collection("Posts")
                .doc(docID)
                .get();
            debugPrint('[UploadPreflight][PostCreator][Image] '
                'path=Posts/$docID/image_$j.webp '
                'uid=$uid '
                'postExists=${postDoc.exists} '
                'postUserID=${postDoc.data()?["userID"]}');
          }
          final url = await WebpUploadService.uploadBytesAsWebp(
            storage: FirebaseStorage.instance,
            bytes: post.images[j],
            storagePathWithoutExt: 'Posts/$docID/image_$j',
            maxWidth: 600,
            maxHeight: 600,
          );
          imageUrls.add(CdnUrlBuilder.toCdnUrl(url));
        }
      }

      if (post.gif.isNotEmpty) {
        imageUrls.add(post.gif);
      }

      if (post.video != null) {
        final nsfwVideo = await OptimizedNSFWService.checkVideo(post.video!);
        if (nsfwVideo.errorMessage != null) {
          throw Exception('NSFW video kontrolü başarısız');
        }
        if (nsfwVideo.isNSFW) {
          throw Exception('Uygunsuz video tespit edildi');
        }
        final videoSize = await post.video!.length();
        if (videoSize > _maxVideoBytesForStorageRule) {
          throw Exception('VIDEO_TOO_LARGE');
        }
        final videoRef = FirebaseStorage.instance.ref().child(
              'Posts/$docID/video.mp4',
            );
        if (kDebugMode) {
          final postDoc = await FirebaseFirestore.instance
              .collection("Posts")
              .doc(docID)
              .get();
          debugPrint('[UploadPreflight][PostCreator] '
              'path=${videoRef.fullPath} '
              'uid=$uid '
              'postExists=${postDoc.exists} '
              'postUserID=${postDoc.data()?["userID"]}');
        }
        final uploadTask = await _putFileWithAuthRetry(
          ref: videoRef,
          file: post.video!,
          metadata: SettableMetadata(
            contentType: 'video/mp4',
            cacheControl: 'public, max-age=31536000, immutable',
            customMetadata: {
              'uploaderUid': uid,
            },
          ),
        );
        videoUrl = CdnUrlBuilder.toCdnUrl(
          await uploadTask.ref.getDownloadURL(),
        );

        Uint8List? thumbnailData;
        if (post.customThumbnail != null) {
          thumbnailData = post.customThumbnail;
        } else {
          thumbnailData = await VideoThumbnail.thumbnailData(
            video: post.video!.path,
            imageFormat: ImageFormat.JPEG,
            quality: 75,
          );
        }

        if (thumbnailData != null) {
          // Determine dynamic min width based on device width (fallback to constant)
          int minW = UploadConstants.thumbnailMaxWidth;
          try {
            final ctx = Get.context;
            if (ctx != null) {
              final w = MediaQuery.of(ctx).size.width;
              if (w.isFinite) {
                minW = w
                    .clamp(200, UploadConstants.thumbnailMaxWidth.toDouble())
                    .toInt();
              }
            }
          } catch (_) {}
          // Convert thumbnail to WebP for better size
          Uint8List thumbWebp;
          try {
            thumbWebp = await FlutterImageCompress.compressWithList(
              thumbnailData,
              quality: 80,
              format: CompressFormat.webp,
              minWidth: minW,
            );
          } catch (_) {
            thumbWebp = thumbnailData; // fallback
          }
          final thumbUrl = await WebpUploadService.uploadBytesAsWebp(
            storage: FirebaseStorage.instance,
            bytes: thumbWebp,
            storagePathWithoutExt: 'Posts/$docID/thumbnail',
          );
          thumbnailUrl = CdnUrlBuilder.toCdnUrl(thumbUrl);
          if (kDebugMode) {
            debugPrint('[PostCreator] Thumbnail uploaded: '
                'orig=${(thumbnailData.length / 1e6).toStringAsFixed(2)} MB '
                'webp=${(thumbWebp.length / 1e6).toStringAsFixed(2)} MB '
                'minWidth=${UploadConstants.thumbnailMaxWidth} url=$thumbnailUrl');
          }
        }
      } else if (isReusedVideoPost) {
        videoUrl = post.reusedVideoUrl.trim();
        if (post.reusedVideoThumbnail.trim().isNotEmpty) {
          thumbnailUrl = post.reusedVideoThumbnail.trim();
        }
      }

      double aspectRatio = 1;
      if (isReusedImagePost && imageUrls.length == 1) {
        aspectRatio =
            post.reusedImageAspectRatio > 0 ? post.reusedImageAspectRatio : 0.8;
      } else if (post.images.length == 1 &&
          post.video == null &&
          !isReusedVideoPost) {
        final codec = await ui.instantiateImageCodec(post.images.first);
        final frame = await codec.getNextFrame();
        final image = frame.image;
        aspectRatio = image.width / image.height;
      } else if (post.images.isEmpty && post.video != null) {
        final controller = VideoPlayerController.file(post.video!);
        await controller.initialize();
        aspectRatio = controller.value.aspectRatio;
        await controller.dispose();
      } else if (isReusedVideoPost) {
        aspectRatio = post.reusedVideoAspectRatio > 0
            ? post.reusedVideoAspectRatio
            : 9 / 16;
      }

      // Normalize to 4 decimals
      aspectRatio = double.parse(aspectRatio.toStringAsFixed(4));
      final isImagePost = imageUrls.isNotEmpty && videoUrl.isEmpty;
      final List<Map<String, dynamic>> imgMap = [];
      for (int i = 0; i < imageUrls.length; i++) {
        double itemAspect = 1.0;
        try {
          if (isReusedImagePost && imageUrls.length == 1) {
            itemAspect = post.reusedImageAspectRatio > 0
                ? post.reusedImageAspectRatio
                : itemAspect;
          } else if (i < post.images.length) {
            final codec = await ui.instantiateImageCodec(post.images[i]);
            final frame = await codec.getNextFrame();
            final image = frame.image;
            if (image.height > 0) {
              itemAspect = image.width / image.height;
            }
          }
        } catch (_) {}
        imgMap.add({
          'url': imageUrls[i],
          'aspectRatio': double.parse(itemAspect.toStringAsFixed(4)),
        });
      }

      final RegExp tagExp = RegExp(r"#([\p{L}\p{N}_]+)", unicode: true);
      final matches = tagExp.allMatches(post.text);
      final localTags = matches
          .map((e) => e.group(1)!.trim())
          .where((e) => e.isNotEmpty)
          .toSet();

      if (index == 0) {
        allHashtags.addAll(localTags);
      }

      // Compute publish time: if scheduled, use selected time; else now
      // Update progress for database save
      progressController.updateProgress(
        current: index + 1,
        fileName: 'Gönderi ${index + 1}',
        statusText: 'Veritabanına kaydediliyor...',
      );

      final scheduledMs =
          (publishMode.value == 1 && izBirakDateTime.value != null)
              ? izBirakDateTime.value!.millisecondsSinceEpoch
              : 0;
      final baseTime = scheduledMs != 0 ? scheduledMs : nowMs;
      final locationCity = _resolvePostLocationCity();

      final pollPayload = post.poll.isNotEmpty
          ? _normalizePollForSave(post.poll, baseTime)
          : null;

      await FirebaseFirestore.instance.collection("Posts").doc(docID).set({
        "arsiv": false,
        if (!isImagePost) "aspectRatio": aspectRatio,
        "debugMode": false,
        "deletedPost": false,
        "deletedPostTime": 0,
        "flood": index == 0 ? false : true,
        "floodCount": postList.length,
        "gizlendi": false,
        "img": imageUrls,
        "imgMap": imgMap,
        "isAd": false,
        "ad": false,
        "izBirakYayinTarihi": baseTime,
        "stats": {
          "commentCount": 0,
          "likeCount": 0,
          "reportedCount": 0,
          "retryCount": 0,
          "savedCount": 0,
          "statsCount": 0
        },
        "konum": post.location,
        "locationCity": locationCity,
        "mainFlood": index == 0 ? "" : "${docID.replaceAll("_0", "")}_0",
        "metin": post.text,
        "reshareMap": {
          "visibility": paylasimSelection.value,
        },
        "scheduledAt": 0,
        "sikayetEdildi": false,
        "stabilized": false,
        "tags": index == 0 ? allHashtags.toList() : [],
        "thumbnail": thumbnailUrl,
        "timeStamp": baseTime + index,
        "userID": uid,
        "video": videoUrl,
        "hlsStatus": isReusedVideoPost ? "ready" : "none",
        "hlsMasterUrl": isReusedVideoPost ? videoUrl : "",
        "hlsUpdatedAt": isReusedVideoPost ? nowMs : 0,
        "yorumMap": {
          "visibility": commentVisibility.value,
        },
        if (pollPayload != null) "poll": pollPayload,
        // Schema: Original attribution fields must always exist
        "originalUserID": _isSharedAsPost ? _sharedOriginalUserID : "",
        "originalPostID": _isSharedAsPost ? _sharedOriginalPostID : "",
        "sharedAsPost": _isSharedAsPost,
        "quotedPost": _isSharedAsPost ? _isQuotedPost : false,
        "quotedOriginalText":
            (_isSharedAsPost && _isQuotedPost) ? _quotedOriginalText : "",
        "quotedSourceUserID":
            (_isSharedAsPost && _isQuotedPost) ? _quotedSourceUserID : "",
        "quotedSourceDisplayName":
            (_isSharedAsPost && _isQuotedPost) ? _quotedSourceDisplayName : "",
        "quotedSourceUsername":
            (_isSharedAsPost && _isQuotedPost) ? _quotedSourceUsername : "",
        "quotedSourceAvatarUrl":
            (_isSharedAsPost && _isQuotedPost) ? _quotedSourceAvatarUrl : "",
      });

      if (_isSharedAsPost &&
          _sharedOriginalUserID.isNotEmpty &&
          _sharedOriginalPostID.isNotEmpty &&
          index == 0) {
        try {
          final originalPostRef = FirebaseFirestore.instance
              .collection("Posts")
              .doc(_sharedOriginalPostID);
          await originalPostRef
              .collection("postSharers")
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .set({
            "userID": FirebaseAuth.instance.currentUser!.uid,
            "timestamp": DateTime.now().millisecondsSinceEpoch,
            "sharedPostID": docID,
            "quotedPost": _isQuotedPost,
          });
          if (_isQuotedPost) {
            await originalPostRef.update({
              "stats.retryCount": FieldValue.increment(1),
            });
          }
        } catch (_) {}
      }

      uploadedPosts.add(
        PostsModel(
          arsiv: false,
          aspectRatio: aspectRatio,
          debugMode: false,
          deletedPost: false,
          deletedPostTime: 0,
          docID: docID,
          flood: index == 0 ? false : true,
          floodCount: allPosts.length,
          gizlendi: false,
          img: imageUrls,
          isAd: false,
          ad: false,
          izBirakYayinTarihi: baseTime,
          stats: PostStats(),
          konum: post.location,
          locationCity: locationCity,
          mainFlood: index == 0 ? "" : "${docID.replaceAll("_0", "")}_0",
          metin: post.text,
          paylasGizliligi: paylasimSelection.value,
          reshareMap: {
            "visibility": paylasimSelection.value,
          },
          scheduledAt: 0,
          sikayetEdildi: false,
          stabilized: false,
          tags: index == 0 ? allHashtags.toList() : [],
          thumbnail: thumbnailUrl,
          timeStamp: baseTime + index,
          userID: FirebaseAuth.instance.currentUser!.uid,
          video: videoUrl,
          hlsStatus: isReusedVideoPost ? "ready" : "none",
          hlsMasterUrl: isReusedVideoPost ? videoUrl : "",
          hlsUpdatedAt: isReusedVideoPost ? nowMs : 0,
          yorum: comment.value,
          yorumMap: {
            "visibility": commentVisibility.value,
          },
          poll: pollPayload ?? const {},
          originalUserID: _isSharedAsPost ? _sharedOriginalUserID : "",
          originalPostID: _isSharedAsPost ? _sharedOriginalPostID : "",
          quotedPost: _isSharedAsPost ? _isQuotedPost : false,
          quotedOriginalText:
              (_isSharedAsPost && _isQuotedPost) ? _quotedOriginalText : "",
          quotedSourceUserID:
              (_isSharedAsPost && _isQuotedPost) ? _quotedSourceUserID : "",
          quotedSourceDisplayName: (_isSharedAsPost && _isQuotedPost)
              ? _quotedSourceDisplayName
              : "",
          quotedSourceUsername:
              (_isSharedAsPost && _isQuotedPost) ? _quotedSourceUsername : "",
          quotedSourceAvatarUrl:
              (_isSharedAsPost && _isQuotedPost) ? _quotedSourceAvatarUrl : "",
        ),
      );

      // Sayaç güncelle: kök post (index==0) ve hemen yayınlanıyorsa (baseTime == now)
      if (index == 0 && baseTime == nowMs) {
        try {
          final me = FirebaseAuth.instance.currentUser?.uid;
          if (me != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(me)
                .update({'counterOfPosts': FieldValue.increment(1)});
          }
        } catch (_) {}
      }
    }
    return uploadedPosts;
  }

  /// Initialize all services
  void _initializeServices() {
    try {
      _errorService = Get.put(ErrorHandlingService());
      _networkService = Get.put(NetworkAwarenessService());
      _uploadQueueService = Get.put(UploadQueueService());
      _draftService = Get.put(DraftService());
    } catch (e) {
      print('Error initializing services: $e');
    }
  }

  Map<String, dynamic> _normalizePollForSave(
      Map<String, dynamic> poll, int createdAtMs) {
    final normalized = Map<String, dynamic>.from(poll);
    final options = (normalized['options'] is List)
        ? List<Map<String, dynamic>>.from(
            (normalized['options'] as List)
                .map((o) => Map<String, dynamic>.from(o)),
          )
        : <Map<String, dynamic>>[];
    int totalVotes = 0;
    for (final opt in options) {
      final v = opt['votes'];
      final int votes = v is num ? v.toInt() : int.tryParse('$v') ?? 0;
      opt['votes'] = votes;
      totalVotes += votes;
    }
    normalized['options'] = options;
    normalized['totalVotes'] = totalVotes;
    normalized['durationHours'] =
        (normalized['durationHours'] is num) ? normalized['durationHours'] : 24;
    normalized['createdDate'] = createdAtMs;
    normalized['userVotes'] = normalized['userVotes'] is Map
        ? Map<String, dynamic>.from(normalized['userVotes'])
        : <String, dynamic>{};
    return normalized;
  }

  bool _validatePollRequirements() {
    for (final postModel in postList) {
      final tag = postModel.index.toString();
      if (!Get.isRegistered<CreatorContentController>(tag: tag)) continue;
      final controller = Get.find<CreatorContentController>(tag: tag);
      final poll = controller.pollData.value;
      if (poll == null || poll.isEmpty) continue;
      final hasCaption = controller.textEdit.text.trim().isNotEmpty;
      final hasMedia = controller.croppedImages.isNotEmpty ||
          controller.reusedImageUrls.isNotEmpty ||
          controller.selectedImages.isNotEmpty ||
          controller.selectedVideo.value != null;
      if (!hasCaption && !hasMedia) {
        AppSnackbar(
          'Anket',
          'Anket için açıklama veya görsel/video gerekli.',
        );
        return false;
      }
    }
    return true;
  }

  /// Start auto-save timer
  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(
      Duration(seconds: _draftService.autoSaveInterval),
      (_) => _saveCurrentDraft(),
    );
  }

  /// Save current draft
  Future<void> _saveCurrentDraft() async {
    if (!_draftService.autoSaveEnabled) return;

    try {
      for (final postModel in postList) {
        final tag = postModel.index.toString();
        if (!Get.isRegistered<CreatorContentController>(tag: tag)) continue;

        final controller = Get.find<CreatorContentController>(tag: tag);
        final text = controller.textEdit.text.trim();

        // Only save if there's meaningful content
        if (text.isNotEmpty ||
            controller.selectedImages.isNotEmpty ||
            controller.reusedImageUrls.isNotEmpty ||
            controller.selectedVideo.value != null ||
            controller.gif.value.isNotEmpty) {
          await _draftService.saveDraft(
            text: text,
            images: controller.selectedImages,
            video: controller.selectedVideo.value,
            location: controller.adres.value,
            gif: controller.gif.value,
            commentEnabled: comment.value,
            sharePrivacy: paylasimSelection.value,
            scheduledDate: izBirakDateTime.value,
          );
        }
      }
    } catch (e) {
      await _errorService.handleError(
        e,
        category: ErrorCategory.storage,
        severity: ErrorSeverity.low,
        userMessage: 'Taslak kaydetme başarısız',
        showToUser: false,
      );
    }
  }

  /// Enhanced upload with comprehensive error handling
  void uploadAllPostsInBackgroundWithErrorHandling() async {
    try {
      // Check network connectivity first
      if (!_networkService.isConnected) {
        await _errorService.handleError(
          'No internet connection',
          category: ErrorCategory.network,
          severity: ErrorSeverity.high,
          userMessage: 'İnternet bağlantısı bulunamadı',
          isRetryable: true,
          metadata: {'userInitiated': true},
        );
        return;
      }

      final progressController = Get.find<UploadProgressController>();

      // Comprehensive validation before upload
      final allImages = <File>[];
      final allVideos = <File>[];
      final allTexts = <String>[];
      bool hasReusedVideo = false;
      bool hasReusedImages = false;

      // Collect all content from posts
      for (final postModel in postList) {
        final tag = postModel.index.toString();
        if (!Get.isRegistered<CreatorContentController>(tag: tag)) {
          Get.put(CreatorContentController(), tag: tag);
        }
        final c = Get.find<CreatorContentController>(tag: tag);

        allImages.addAll(c.selectedImages);
        if (c.selectedVideo.value != null) {
          allVideos.add(c.selectedVideo.value!);
        }
        if (c.reusedVideoUrl.value.trim().isNotEmpty) {
          hasReusedVideo = true;
        }
        if (c.reusedImageUrls.isNotEmpty) {
          hasReusedImages = true;
        }

        final text = c.textEdit.text.trim();
        if (text.isNotEmpty) {
          allTexts.add(text);
        }
      }

      // Network-aware upload validation
      for (final image in allImages) {
        final fileSize = await image.length();
        final fileSizeMB = (fileSize / (1024 * 1024)).round();

        if (!_networkService.shouldAllowUpload(fileSizeMB: fileSizeMB)) {
          final recommendation =
              _networkService.getUploadRecommendation(fileSizeMB: fileSizeMB);
          await _errorService.handleError(
            'Upload not recommended',
            category: ErrorCategory.network,
            severity: ErrorSeverity.medium,
            userMessage: recommendation['reason'],
            metadata: {
              ...recommendation,
              'userInitiated': true,
            },
          );
          return;
        }
      }

      // Final comprehensive validation
      final validation = await UploadValidationService.validatePost(
        images: allImages,
        videos: allVideos,
        text:
            (hasReusedVideo || hasReusedImages) ? 'media' : allTexts.join(' '),
      );

      if (!validation.isValid) {
        await _errorService.handleError(
          validation.errorMessage ?? 'Validation failed',
          category: ErrorCategory.validation,
          severity: ErrorSeverity.medium,
          userMessage:
              validation.errorMessage ?? 'Gönderi doğrulaması başarısız',
        );
        return;
      }

      Get.back();

      // Start progress indicator
      final totalPosts = postList.length;
      progressController.startProgress(
        total: totalPosts,
        initialStatus: 'Gönderiler hazırlanıyor...',
      );

      // Use background upload queue for resilient uploading
      if (_networkService.isOnCellular &&
          !_networkService.settings.autoUploadOnWiFi) {
        await _addToUploadQueue(progressController);
      } else {
        await _uploadDirectly(progressController);
      }
    } catch (e, stackTrace) {
      await _errorService.handleError(
        e,
        category: ErrorCategory.upload,
        severity: ErrorSeverity.high,
        userMessage: 'Gönderi yükleme başarısız',
        stackTrace: stackTrace,
        isRetryable: true,
        metadata: {
          'postCount': postList.length,
          'publishMode': publishMode.value,
        },
      );
    }
  }

  /// Add posts to background upload queue
  Future<void> _addToUploadQueue(
      UploadProgressController progressController) async {
    try {
      _startQueueRingMonitor();
      if (!_validatePollRequirements()) return;
      for (int index = 0; index < postList.length; index++) {
        final postModel = postList[index];
        final tag = postModel.index.toString();
        if (!Get.isRegistered<CreatorContentController>(tag: tag)) continue;

        final controller = Get.find<CreatorContentController>(tag: tag);
        final uuid = const Uuid().v4();
        final docID = '${uuid}_$index';

        // Prepare post data
        final postData = {
          'id': docID,
          'text': controller.textEdit.text.trim(),
          'location': controller.adres.value,
          'gif': controller.gif.value,
          'userID': FirebaseAuth.instance.currentUser!.uid,
          'yorumMap': {
            'visibility': commentVisibility.value,
          },
          'reshareMap': {
            'visibility': paylasimSelection.value,
          },
          if (controller.pollData.value != null)
            'poll': controller.pollData.value,
          'scheduledAt':
              (publishMode.value == 1 && izBirakDateTime.value != null)
                  ? izBirakDateTime.value!.millisecondsSinceEpoch
                  : 0,
        };

        // Persist compressed images to temp files for queue (use croppedImages if available)
        final imagePaths = <String>[];
        if (controller.croppedImages.isNotEmpty) {
          final tempDir = await getTemporaryDirectory();
          for (int i = 0; i < controller.croppedImages.length; i++) {
            final data = controller.croppedImages[i];
            if (data == null) continue;
            final filePath = p.join(
              tempDir.path,
              'upload_${docID}_$i.webp',
            );
            final f = File(filePath);
            await f.writeAsBytes(data, flush: true);
            imagePaths.add(filePath);
          }
        } else {
          // Fallback to original files if no compressed data present
          imagePaths.addAll(controller.selectedImages.map((f) => f.path));
        }

        // Create queued upload
        final poll = controller.pollData.value ?? const {};
        final int scheduledAt = (postData['scheduledAt'] is num)
            ? postData['scheduledAt'] as int
            : 0;
        final pollPayload = (poll.isNotEmpty)
            ? _normalizePollForSave(
                poll,
                scheduledAt > 0
                    ? scheduledAt
                    : DateTime.now().millisecondsSinceEpoch,
              )
            : null;
        if (pollPayload != null) {
          postData['poll'] = pollPayload;
        }

        final queuedUpload = QueuedUpload(
          id: docID,
          postData: jsonEncode(postData),
          imagePaths: imagePaths,
          videoPath: controller.selectedVideo.value?.path,
          createdAt: DateTime.now(),
        );

        await _uploadQueueService.addToQueue(queuedUpload);
      }

      progressController
          .complete('Gönderiler kuyruğa eklendi! Arka planda yüklenecek.');
      AppSnackbar(
        'Yükleme Kuyruğu',
        'Gönderiler arka plan kuyruğuna eklendi',
        backgroundColor: Colors.green.withValues(alpha: 0.7),
      );
    } catch (e) {
      await _errorService.handleError(
        e,
        category: ErrorCategory.upload,
        severity: ErrorSeverity.high,
        userMessage: 'Kuyruk ekleme başarısız',
        isRetryable: true,
      );
    }
  }

  void _startQueueRingMonitor() {
    final nav = _maybeNavBarController();
    nav?.uploadingPosts.value = true;
    _queueRingTimer?.cancel();
    _queueRingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final stats = _uploadQueueService.getQueueStats();
      final pending = (stats['pending'] as int?) ?? 0;
      final processing = (stats['processing'] as bool?) ?? false;
      if (!processing && pending == 0) {
        nav?.uploadingPosts.value = false;
        timer.cancel();
      }
    });
  }

  /// Upload directly with error handling
  Future<void> _uploadDirectly(
      UploadProgressController progressController) async {
    final nav = _maybeNavBarController();
    nav?.uploadingPosts.value = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        bool hasVideo = false;
        for (final postModel in postList) {
          final tag = postModel.index.toString();
          if (!Get.isRegistered<CreatorContentController>(tag: tag)) continue;
          final controller = Get.find<CreatorContentController>(tag: tag);
          if (controller.selectedVideo.value != null) {
            hasVideo = true;
            break;
          }
        }
        if (hasVideo) {
          await _addToUploadQueue(progressController);
          return;
        }
        if (!_validatePollRequirements()) {
          nav?.uploadingPosts.value = false;
          return;
        }
        final uploadedPosts =
            await uploadAllPostsWithErrorHandling(progressController);

        if (uploadedPosts.isNotEmpty) {
          // Track data usage
          int totalUploadMB = 0;
          for (final postModel in postList) {
            final tag = postModel.index.toString();
            if (!Get.isRegistered<CreatorContentController>(tag: tag)) continue;

            final controller = Get.find<CreatorContentController>(tag: tag);
            for (final image in controller.selectedImages) {
              final size = await image.length();
              totalUploadMB += (size / (1024 * 1024)).round();
            }

            if (controller.selectedVideo.value != null) {
              final size = await controller.selectedVideo.value!.length();
              totalUploadMB += (size / (1024 * 1024)).round();
            }
          }

          await _networkService.trackDataUsage(uploadMB: totalUploadMB);

          final agendaController = Get.find<AgendaController>();
          await Future.delayed(const Duration(milliseconds: 150));

          final nowMs = DateTime.now().millisecondsSinceEpoch;
          final nowPosts =
              uploadedPosts.where((e) => e.timeStamp <= nowMs).toList();

          if (nowPosts.isNotEmpty) {
            final ids = nowPosts.map((e) => e.docID).toList();
            agendaController.markHighlighted(ids);
            agendaController.addUploadedPostsAtTop(nowPosts);
          }

          if (agendaController.scrollController.hasClients) {
            agendaController.scrollController.jumpTo(0);
          }

          Get.find<ProfileController>().getLastPostAndAddToAllPosts();
          progressController.complete('Gönderiler başarıyla yayınlandı!');
        } else {
          await _errorService.handleError(
            'No posts uploaded',
            category: ErrorCategory.upload,
            severity: ErrorSeverity.medium,
            userMessage: 'Hiçbir gönderi yüklenemedi',
          );
          progressController.setError('Gönderi yüklenirken hata oluştu.');
        }
      } catch (e, stackTrace) {
        await _errorService.handleError(
          e,
          category: ErrorCategory.upload,
          severity: ErrorSeverity.critical,
          userMessage: 'Yükleme işlemi başarısız',
          stackTrace: stackTrace,
          isRetryable: true,
        );
        progressController.setError('Kritik hata oluştu.');
      } finally {
        nav?.uploadingPosts.value = false;
      }
    });
  }

  /// Upload all posts with comprehensive error handling
  Future<List<PostsModel>> uploadAllPostsWithErrorHandling(
      UploadProgressController progressController) async {
    final allPosts = <PreparedPostModel>[];
    final uploadedPosts = <PostsModel>[];
    final uuid = const Uuid().v4();

    try {
      // Prepare all posts
      for (var postModel in postList) {
        final tag = postModel.index.toString();
        if (!Get.isRegistered<CreatorContentController>(tag: tag)) continue;

        final contentController = Get.find<CreatorContentController>(tag: tag);
        final text = contentController.textEdit.text.trim();
        final images =
            contentController.croppedImages.whereType<Uint8List>().toList();
        final reusedImageUrls = contentController.reusedImageUrls.toList();
        final reusedImageAspectRatio =
            contentController.reusedImageAspectRatio.value;
        final video = contentController.selectedVideo.value;
        final reusedVideoUrl = contentController.reusedVideoUrl.value;
        final reusedVideoThumbnail =
            contentController.reusedVideoThumbnail.value;
        final reusedVideoAspectRatio =
            contentController.reusedVideoAspectRatio.value;
        final location = contentController.adres.value;
        final gif = contentController.gif.value;
        final customThumb = contentController.selectedThumbnail.value;
        final poll = contentController.pollData.value ?? const {};

        allPosts.add(
          PreparedPostModel(
            text: text,
            images: images,
            reusedImageUrls: reusedImageUrls,
            reusedImageAspectRatio: reusedImageAspectRatio,
            video: video,
            reusedVideoUrl: reusedVideoUrl,
            reusedVideoThumbnail: reusedVideoThumbnail,
            reusedVideoAspectRatio: reusedVideoAspectRatio,
            location: location,
            gif: gif,
            customThumbnail: customThumb,
            poll: poll,
          ),
        );
      }

      final allHashtags = <String>{};

      // Upload each post with error handling
      for (int index = 0; index < allPosts.length; index++) {
        try {
          final post = allPosts[index];
          final docID = '${uuid}_$index';
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          final uid = await _ensureStorageUploadAuthReady() ??
              FirebaseAuth.instance.currentUser!.uid;
          final locationCity = _resolvePostLocationCity();

          // Storage rules require Posts/{docID}.userID to exist before media upload.
          await _preparePostShellForStorageUpload(
            docID: docID,
            uid: uid,
            nowMs: nowMs,
          );

          // Update progress
          progressController.updateProgress(
            current: index + 1,
            fileName: 'Gönderi ${index + 1}',
            statusText: 'Medya dosyaları yükleniyor...',
          );

          final imageUrls = <String>[];
          var videoUrl = "";
          var thumbnailUrl = "";
          final isReusedVideoPost =
              post.video == null && post.reusedVideoUrl.trim().isNotEmpty;
          final isReusedImagePost = post.video == null &&
              post.images.isEmpty &&
              post.reusedImageUrls.isNotEmpty;

          if (isReusedImagePost) {
            imageUrls.addAll(post.reusedImageUrls.map(CdnUrlBuilder.toCdnUrl));
          } else {
            // Upload images with retry logic
            for (int j = 0; j < post.images.length; j++) {
              try {
                if (kDebugMode) {
                  final postDoc = await FirebaseFirestore.instance
                      .collection("Posts")
                      .doc(docID)
                      .get();
                  debugPrint('[UploadPreflight][PostCreator][Image] '
                      'path=Posts/$docID/image_$j.webp '
                      'uid=$uid '
                      'postExists=${postDoc.exists} '
                      'postUserID=${postDoc.data()?["userID"]}');
                }
                final url = await WebpUploadService.uploadBytesAsWebp(
                  storage: FirebaseStorage.instance,
                  bytes: post.images[j],
                  storagePathWithoutExt: 'Posts/$docID/image_$j',
                  maxWidth: 600,
                  maxHeight: 600,
                );
                imageUrls.add(CdnUrlBuilder.toCdnUrl(url));
              } catch (e) {
                await _errorService.handleError(
                  e,
                  category: ErrorCategory.upload,
                  severity: ErrorSeverity.high,
                  userMessage: 'Resim ${j + 1} yüklenemedi',
                  metadata: {'postIndex': index, 'imageIndex': j},
                  isRetryable: true,
                );
                rethrow;
              }
            }
          }

          if (post.gif.isNotEmpty) {
            imageUrls.add(post.gif);
          }

          // Upload video with error handling
          if (post.video != null) {
            try {
              final nsfwVideo =
                  await OptimizedNSFWService.checkVideo(post.video!);
              if (nsfwVideo.errorMessage != null) {
                throw Exception('NSFW video kontrolü başarısız');
              }
              if (nsfwVideo.isNSFW) {
                throw Exception('Uygunsuz video tespit edildi');
              }
              final videoSize = await post.video!.length();
              if (videoSize > _maxVideoBytesForStorageRule) {
                throw Exception('VIDEO_TOO_LARGE');
              }
              final videoRef = FirebaseStorage.instance
                  .ref()
                  .child('Posts/$docID/video.mp4');
              if (kDebugMode) {
                final postDoc = await FirebaseFirestore.instance
                    .collection("Posts")
                    .doc(docID)
                    .get();
                debugPrint('[UploadPreflight][PostCreator] '
                    'path=${videoRef.fullPath} '
                    'uid=$uid '
                    'postExists=${postDoc.exists} '
                    'postUserID=${postDoc.data()?["userID"]}');
              }
              final uploadTask = await _putFileWithAuthRetry(
                ref: videoRef,
                file: post.video!,
                metadata: SettableMetadata(
                  contentType: 'video/mp4',
                  cacheControl: 'public, max-age=31536000, immutable',
                  customMetadata: {
                    'uploaderUid': uid,
                  },
                ),
              );
              videoUrl = CdnUrlBuilder.toCdnUrl(
                await uploadTask.ref.getDownloadURL(),
              );

              Uint8List? thumbnailData;
              if (post.customThumbnail != null) {
                thumbnailData = post.customThumbnail;
              } else {
                thumbnailData = await VideoThumbnail.thumbnailData(
                  video: post.video!.path,
                  imageFormat: ImageFormat.JPEG,
                  quality: 75,
                );
              }

              if (thumbnailData != null) {
                Uint8List thumbWebp;
                try {
                  thumbWebp = await FlutterImageCompress.compressWithList(
                    thumbnailData,
                    quality: 80,
                    format: CompressFormat.webp,
                    minWidth: UploadConstants.thumbnailMaxWidth,
                  );
                } catch (_) {
                  thumbWebp = thumbnailData;
                }
                final thumbUrl = await WebpUploadService.uploadBytesAsWebp(
                  storage: FirebaseStorage.instance,
                  bytes: thumbWebp,
                  storagePathWithoutExt: 'Posts/$docID/thumbnail',
                );
                thumbnailUrl = CdnUrlBuilder.toCdnUrl(
                  thumbUrl,
                );
                if (kDebugMode) {
                  debugPrint('[PostCreator] Thumbnail uploaded: '
                      'orig=${(thumbnailData.length / 1e6).toStringAsFixed(2)} MB '
                      'webp=${(thumbWebp.length / 1e6).toStringAsFixed(2)} MB '
                      'minWidth=${UploadConstants.thumbnailMaxWidth} url=$thumbnailUrl');
                }
              }
            } catch (e) {
              final tooLarge = e.toString().contains('VIDEO_TOO_LARGE');
              await _errorService.handleError(
                e,
                category: ErrorCategory.upload,
                severity: ErrorSeverity.high,
                userMessage: tooLarge
                    ? 'Video boyutu çok büyük (maks. 35MB)'
                    : 'Video yüklenemedi',
                metadata: {'postIndex': index},
                isRetryable: !tooLarge,
              );
              rethrow; // Re-throw to stop this post's upload
            }
          } else if (isReusedVideoPost) {
            videoUrl = post.reusedVideoUrl.trim();
            if (post.reusedVideoThumbnail.trim().isNotEmpty) {
              thumbnailUrl = post.reusedVideoThumbnail.trim();
            }
          }

          // Calculate timing
          final baseTime =
              publishMode.value == 1 && izBirakDateTime.value != null
                  ? izBirakDateTime.value!.millisecondsSinceEpoch
                  : nowMs;

          // Calculate proper aspect ratio
          double aspectRatio = 1.0;
          if (isReusedImagePost && imageUrls.length == 1) {
            aspectRatio = post.reusedImageAspectRatio > 0
                ? post.reusedImageAspectRatio
                : 0.8;
          } else if (post.images.length == 1 &&
              post.video == null &&
              !isReusedVideoPost) {
            try {
              final codec = await ui.instantiateImageCodec(post.images.first);
              final frame = await codec.getNextFrame();
              final image = frame.image;
              aspectRatio = image.width / image.height;
            } catch (e) {
              aspectRatio = 4.0 / 5.0; // Default for images
            }
          } else if (post.images.isEmpty && post.video != null) {
            try {
              final controller = VideoPlayerController.file(post.video!);
              await controller.initialize();
              aspectRatio = controller.value.aspectRatio;
              await controller.dispose();
            } catch (e) {
              aspectRatio = 16.0 / 9.0; // Default for videos
            }
          } else if (isReusedVideoPost) {
            aspectRatio = post.reusedVideoAspectRatio > 0
                ? post.reusedVideoAspectRatio
                : 9.0 / 16.0;
          } else {
            aspectRatio =
                4.0 / 5.0; // Default for multiple images or mixed content
          }

          // Normalize to 4 decimals
          aspectRatio = double.parse(aspectRatio.toStringAsFixed(4));
          final isImagePost = imageUrls.isNotEmpty && videoUrl.isEmpty;
          final List<Map<String, dynamic>> imgMap = [];
          for (int i = 0; i < imageUrls.length; i++) {
            double itemAspect = 1.0;
            try {
              if (isReusedImagePost && imageUrls.length == 1) {
                itemAspect = post.reusedImageAspectRatio > 0
                    ? post.reusedImageAspectRatio
                    : itemAspect;
              } else if (i < post.images.length) {
                final codec = await ui.instantiateImageCodec(post.images[i]);
                final frame = await codec.getNextFrame();
                final image = frame.image;
                if (image.height > 0) {
                  itemAspect = image.width / image.height;
                }
              }
            } catch (_) {}
            imgMap.add({
              'url': imageUrls[i],
              'aspectRatio': double.parse(itemAspect.toStringAsFixed(4)),
            });
          }

          // Upload to Firestore with error handling
          try {
            await FirebaseFirestore.instance
                .collection('Posts')
                .doc(docID)
                .set({
              // ... (same data structure as before)
              "arsiv": false,
              if (!isImagePost) "aspectRatio": aspectRatio,
              "debugMode": false,
              "deletedPost": false,
              "deletedPostTime": 0,
              "flood": index == 0 ? false : true,
              "floodCount": allPosts.length,
              "gizlendi": false,
              "img": imageUrls,
              "imgMap": imgMap,
              "isAd": false,
              "ad": false,
              "izBirakYayinTarihi": baseTime,
              "stats": {
                "commentCount": 0,
                "likeCount": 0,
                "reportedCount": 0,
                "retryCount": 0,
                "savedCount": 0,
                "statsCount": 0
              },
              "konum": post.location,
              "locationCity": locationCity,
              "mainFlood": index == 0 ? "" : "${docID.replaceAll("_0", "")}_0",
              "metin": post.text,
              "reshareMap": {
                "visibility": paylasimSelection.value,
              },
              "scheduledAt": 0,
              "sikayetEdildi": false,
              "stabilized": false,
              "tags": index == 0 ? allHashtags.toList() : [],
              "thumbnail": thumbnailUrl,
              "timeStamp": baseTime + index,
              "userID": FirebaseAuth.instance.currentUser!.uid,
              "video": videoUrl,
              "hlsStatus": isReusedVideoPost ? "ready" : "none",
              "hlsMasterUrl": isReusedVideoPost ? videoUrl : "",
              "hlsUpdatedAt": isReusedVideoPost ? nowMs : 0,
              "yorumMap": {
                "visibility": commentVisibility.value,
              },
              if (post.poll.isNotEmpty) "poll": post.poll,
              "originalUserID": _isSharedAsPost ? _sharedOriginalUserID : "",
              "originalPostID": _isSharedAsPost ? _sharedOriginalPostID : "",
              "sharedAsPost": _isSharedAsPost,
              "quotedPost": _isSharedAsPost ? _isQuotedPost : false,
              "quotedOriginalText":
                  (_isSharedAsPost && _isQuotedPost) ? _quotedOriginalText : "",
              "quotedSourceUserID":
                  (_isSharedAsPost && _isQuotedPost) ? _quotedSourceUserID : "",
              "quotedSourceDisplayName": (_isSharedAsPost && _isQuotedPost)
                  ? _quotedSourceDisplayName
                  : "",
              "quotedSourceUsername": (_isSharedAsPost && _isQuotedPost)
                  ? _quotedSourceUsername
                  : "",
              "quotedSourceAvatarUrl": (_isSharedAsPost && _isQuotedPost)
                  ? _quotedSourceAvatarUrl
                  : "",
            });

            if (_isSharedAsPost &&
                _sharedOriginalUserID.isNotEmpty &&
                _sharedOriginalPostID.isNotEmpty &&
                index == 0) {
              try {
                final originalPostRef = FirebaseFirestore.instance
                    .collection("Posts")
                    .doc(_sharedOriginalPostID);
                await originalPostRef
                    .collection("postSharers")
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .set({
                  "userID": FirebaseAuth.instance.currentUser!.uid,
                  "timestamp": DateTime.now().millisecondsSinceEpoch,
                  "sharedPostID": docID,
                  "quotedPost": _isQuotedPost,
                });
                if (_isQuotedPost) {
                  await originalPostRef.update({
                    "stats.retryCount": FieldValue.increment(1),
                  });
                }
              } catch (_) {}
            }

            // Create PostsModel
            uploadedPosts.add(
              PostsModel(
                arsiv: false,
                aspectRatio: aspectRatio,
                debugMode: false,
                deletedPost: false,
                deletedPostTime: 0,
                docID: docID,
                flood: index == 0 ? false : true,
                floodCount: allPosts.length,
                gizlendi: false,
                img: imageUrls,
                isAd: false,
                ad: false,
                izBirakYayinTarihi: baseTime,
                stats: PostStats(),
                konum: post.location,
                locationCity: locationCity,
                mainFlood: index == 0 ? "" : "${docID.replaceAll("_0", "")}_0",
                metin: post.text,
                originalPostID: _isSharedAsPost ? _sharedOriginalPostID : "",
                originalUserID: _isSharedAsPost ? _sharedOriginalUserID : "",
                paylasGizliligi: paylasimSelection.value,
                reshareMap: {
                  "visibility": paylasimSelection.value,
                },
                scheduledAt: 0,
                sikayetEdildi: false,
                stabilized: false,
                tags: index == 0 ? allHashtags.toList() : [],
                thumbnail: thumbnailUrl,
                timeStamp: baseTime + index,
                userID: FirebaseAuth.instance.currentUser!.uid,
                video: videoUrl,
                hlsStatus: isReusedVideoPost ? "ready" : "none",
                hlsMasterUrl: isReusedVideoPost ? videoUrl : "",
                hlsUpdatedAt: isReusedVideoPost ? nowMs : 0,
                yorum: comment.value,
                yorumMap: {
                  "visibility": commentVisibility.value,
                },
                quotedPost: _isSharedAsPost ? _isQuotedPost : false,
                quotedOriginalText: (_isSharedAsPost && _isQuotedPost)
                    ? _quotedOriginalText
                    : "",
                quotedSourceUserID: (_isSharedAsPost && _isQuotedPost)
                    ? _quotedSourceUserID
                    : "",
                quotedSourceDisplayName: (_isSharedAsPost && _isQuotedPost)
                    ? _quotedSourceDisplayName
                    : "",
                quotedSourceUsername: (_isSharedAsPost && _isQuotedPost)
                    ? _quotedSourceUsername
                    : "",
                quotedSourceAvatarUrl: (_isSharedAsPost && _isQuotedPost)
                    ? _quotedSourceAvatarUrl
                    : "",
                poll: post.poll,
              ),
            );

            // Update counter for root post
            if (index == 0 && baseTime == nowMs) {
              try {
                final me = FirebaseAuth.instance.currentUser?.uid;
                if (me != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(me)
                      .update({'counterOfPosts': FieldValue.increment(1)});
                }
              } catch (e) {
                await _errorService.handleError(
                  e,
                  category: ErrorCategory.storage,
                  severity: ErrorSeverity.low,
                  userMessage: 'Post sayacı güncellenemedi',
                  showToUser: false,
                );
              }
            }
          } catch (e) {
            await _errorService.handleError(
              e,
              category: ErrorCategory.storage,
              severity: ErrorSeverity.high,
              userMessage: 'Firestore kaydetme başarısız',
              metadata: {'postIndex': index, 'docID': docID},
              isRetryable: true,
            );
            rethrow; // Re-throw to stop this post's upload
          }
        } catch (e) {
          // Log the error for this specific post but continue with others
          await _errorService.handleError(
            e,
            category: ErrorCategory.upload,
            severity: ErrorSeverity.high,
            userMessage: 'Gönderi ${index + 1} yüklenemedi',
            metadata: {'postIndex': index},
            isRetryable: false,
          );
          // Continue with next post instead of stopping everything
          continue;
        }
      }

      return uploadedPosts;
    } catch (e, stackTrace) {
      await _errorService.handleError(
        e,
        category: ErrorCategory.upload,
        severity: ErrorSeverity.critical,
        userMessage: 'Yükleme işlemi tamamen başarısız',
        stackTrace: stackTrace,
        isRetryable: true,
      );
      return [];
    }
  }
}
