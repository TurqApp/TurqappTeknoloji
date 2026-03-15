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
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
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

part 'post_creator_controller_upload_support.dart';
part 'post_creator_controller_flow_part.dart';
part 'post_creator_controller_source_part.dart';
part 'post_creator_controller_publish_part.dart';

class PreparedPostModel {
  final String text;
  final List<Uint8List> images;
  final List<String> reusedImageUrls;
  final double reusedImageAspectRatio;
  final File? video;
  final String reusedVideoUrl;
  final String reusedVideoThumbnail;
  final double reusedVideoAspectRatio;
  final String videoLookPreset;
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
    required this.videoLookPreset,
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
  static const int _maxScheduledWindowDays = 90;
  static int _lastModerationSnackbarAtMs = 0;
  final PostRepository _postRepository = PostRepository.ensure();
  RxList<PostCreatorModel> postList =
      <PostCreatorModel>[PostCreatorModel(index: 0, text: "")].obs;
  final RxBool isKeyboardOpen = false.obs;
  final RxBool isPublishing = false.obs;
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
  String _sharedSourceFingerprint = "";
  bool _isSharedAsPost = false;
  String _sharedOriginalUserID = "";
  String _sharedOriginalPostID = "";
  String _sharedSourcePostID = "";
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

  String _resolvePostLocationCity() =>
      _PostCreatorControllerUploadSupportX(this)._resolvePostLocationCity();

  Future<String?> _ensureStorageUploadAuthReady() =>
      _PostCreatorControllerUploadSupportX(this)
          ._ensureStorageUploadAuthReady();

  Future<void> _preparePostShellForStorageUpload({
    required String docID,
    required String uid,
    required int nowMs,
  }) =>
      _PostCreatorControllerUploadSupportX(this)
          ._preparePostShellForStorageUpload(
        docID: docID,
        uid: uid,
        nowMs: nowMs,
      );

  Future<TaskSnapshot> _putFileWithAuthRetry({
    required Reference ref,
    required File file,
    required SettableMetadata metadata,
  }) =>
      _PostCreatorControllerUploadSupportX(this)._putFileWithAuthRetry(
        ref: ref,
        file: file,
        metadata: metadata,
      );

  NavBarController? _maybeNavBarController() =>
      _PostCreatorControllerUploadSupportX(this)._maybeNavBarController();

  DateTime get maxIzBirakDate =>
      DateTime.now().add(const Duration(days: _maxScheduledWindowDays));

  DateTime? _normalizedIzBirakDateTime() {
    final picked = izBirakDateTime.value;
    if (publishMode.value != 1 || picked == null) return null;
    final now = DateTime.now();
    if (picked.isBefore(now)) return now;
    final max = maxIzBirakDate;
    if (picked.isAfter(max)) return max;
    return picked;
  }

  Future<void> _hydrateQuotedSourceIfNeeded() async {
    if (!_isSharedAsPost || !_isQuotedPost) return;

    final sourcePostId = _sharedSourcePostID.trim().isNotEmpty
        ? _sharedSourcePostID.trim()
        : _sharedOriginalPostID.trim();

    Map<String, dynamic> sourcePost = const <String, dynamic>{};
    if (sourcePostId.isNotEmpty) {
      sourcePost = await _postRepository.fetchPostRawById(
            sourcePostId,
            preferCache: true,
          ) ??
          const <String, dynamic>{};
    }

    final resolvedText = _quotedOriginalText.trim().isNotEmpty
        ? _quotedOriginalText.trim()
        : (sourcePost['metin'] ?? '').toString().trim();
    if (resolvedText.isNotEmpty) {
      _quotedOriginalText = resolvedText;
    }

    final sourceUserId = _quotedSourceUserID.trim().isNotEmpty
        ? _quotedSourceUserID.trim()
        : (sourcePost['userID'] ?? sourcePost['userId'] ?? '')
            .toString()
            .trim();
    if (sourceUserId.isNotEmpty) {
      _quotedSourceUserID = sourceUserId;
    }

    if (sourceUserId.isEmpty) return;

    final userRaw = await UserRepository.ensure().getUserRaw(
          sourceUserId,
          preferCache: true,
          cacheOnly: false,
        ) ??
        const <String, dynamic>{};

    final resolvedDisplayName = _quotedSourceDisplayName.trim().isNotEmpty
        ? _quotedSourceDisplayName.trim()
        : [
            (userRaw['displayName'] ?? '').toString().trim(),
            [
              (userRaw['firstName'] ?? '').toString().trim(),
              (userRaw['lastName'] ?? '').toString().trim(),
            ].where((e) => e.isNotEmpty).join(' ').trim(),
            (userRaw['nickname'] ?? '').toString().trim(),
            (userRaw['username'] ?? '').toString().trim(),
          ].firstWhere((e) => e.isNotEmpty, orElse: () => '');
    if (resolvedDisplayName.isNotEmpty) {
      _quotedSourceDisplayName = resolvedDisplayName;
    }

    final resolvedUsername = _quotedSourceUsername.trim().isNotEmpty
        ? _quotedSourceUsername.trim()
        : [
            (userRaw['username'] ?? '').toString().trim(),
            (userRaw['nickname'] ?? '').toString().trim(),
          ].firstWhere((e) => e.isNotEmpty, orElse: () => '');
    if (resolvedUsername.isNotEmpty) {
      _quotedSourceUsername = resolvedUsername;
    }

    final resolvedAvatar = _quotedSourceAvatarUrl.trim().isNotEmpty
        ? _quotedSourceAvatarUrl.trim()
        : [
            (userRaw['avatarUrl'] ?? '').toString().trim(),
            (userRaw['profileImage'] ?? '').toString().trim(),
            (userRaw['photoUrl'] ?? '').toString().trim(),
            (userRaw['imageUrl'] ?? '').toString().trim(),
          ].firstWhere((e) => e.isNotEmpty, orElse: () => '');
    if (resolvedAvatar.isNotEmpty) {
      _quotedSourceAvatarUrl = resolvedAvatar;
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
}
