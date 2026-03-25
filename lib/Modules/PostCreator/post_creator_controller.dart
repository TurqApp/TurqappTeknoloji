// PostCreatorController.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/upload_constants.dart';
import 'package:turqappv2/Core/Services/post_caption_limits.dart';
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
import '../../Core/Services/user_moderation_guard.dart';
import '../../Core/Services/draft_service.dart';
import '../../Core/Widgets/progress_indicators.dart';
import '../../Core/Services/optimized_nsfw_service.dart';
import '../../Core/Services/typesense_post_service.dart';
import '../../Core/Services/webp_upload_service.dart';

part 'post_creator_controller_upload_support.dart';
part 'post_creator_controller_flow_part.dart';
part 'post_creator_controller_source_part.dart';
part 'post_creator_controller_publish_part.dart';
part 'post_creator_controller_publish_upload_part.dart';
part 'post_creator_controller_route_part.dart';
part 'post_creator_controller_ui_part.dart';
part 'post_creator_controller_models_part.dart';
part 'post_creator_controller_runtime_part.dart';

class PostCreatorController extends GetxController with WidgetsBindingObserver {
  static PostCreatorController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(PostCreatorController(), permanent: permanent);
  }

  static PostCreatorController? maybeFind() {
    final isRegistered = Get.isRegistered<PostCreatorController>();
    if (!isRegistered) return null;
    return Get.find<PostCreatorController>();
  }

  static int get _maxVideoBytesForStorageRule =>
      UploadValidationService.currentMaxVideoSizeBytes;
  static const int _maxScheduledWindowDays = 90;
  static int _lastModerationSnackbarAtMs = 0;
  final PostRepository _postRepository = PostRepository.ensure();
  RxList<PostCreatorModel> postList =
      <PostCreatorModel>[PostCreatorModel(index: 0, text: "")].obs;
  int _nextComposerItemIndex = 1;
  final RxBool isKeyboardOpen = false.obs;
  final RxBool isPublishing = false.obs;
  var selectedIndex = 0.obs;
  final agendaController = AgendaController.ensure();
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

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

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
  String _preparedRouteId = '';

  bool get isQuotedPost => _isQuotedPost;
  String get quotedOriginalText => _quotedOriginalText;
  String get quotedSourceUserID => _quotedSourceUserID;
  String get quotedSourceDisplayName => _quotedSourceDisplayName;
  String get quotedSourceUsername => _quotedSourceUsername;
  String get quotedSourceAvatarUrl => _quotedSourceAvatarUrl;
  String get sharedOriginalUserID => _sharedOriginalUserID;
  String get sharedOriginalPostID => _sharedOriginalPostID;

  DateTime get maxIzBirakDate =>
      DateTime.now().add(const Duration(days: _maxScheduledWindowDays));

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
    _saveCurrentDraft();
    super.onClose();
  }

  Future<void> prepareForRoute({
    required String routeId,
    required bool sharedAsPost,
    required bool editMode,
  }) =>
      _PostCreatorControllerRouteX(this)._prepareForRoute(
        routeId: routeId,
        sharedAsPost: sharedAsPost,
        editMode: editMode,
      );

  Future<void> resetComposerState() =>
      _PostCreatorControllerRouteX(this)._resetComposerState();

  @override
  void didChangeMetrics() {
    _PostCreatorControllerRouteX(this)._handleDidChangeMetrics();
  }

  DateTime? _normalizedIzBirakDateTime() =>
      _PostCreatorControllerRouteX(this)._normalizedIzBirakDateTime();

  Future<void> _hydrateQuotedSourceIfNeeded() =>
      _PostCreatorControllerRouteX(this)._hydrateQuotedSourceIfNeeded();

  void uploadAllPostsInBackground() =>
      _PostCreatorControllerUiX(this)._uploadAllPostsInBackground();

  Future<void> showCommentOptions() =>
      _PostCreatorControllerUiX(this)._showCommentOptions();
}
