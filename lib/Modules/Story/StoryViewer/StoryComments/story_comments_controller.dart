import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Services/giphy_picker_service.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Models/story_comment_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'story_comments_controller_runtime_part.dart';

class StoryCommentsController extends GetxController {
  static String? _activeTag;

  static StoryCommentsController ensure({
    required String nickname,
    required String storyID,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) {
      _activeTag = tag;
      return existing;
    }
    final created = Get.put(
      StoryCommentsController(
        nickname: nickname,
        storyID: storyID,
      ),
      tag: tag,
      permanent: permanent,
    );
    created.controllerTag = tag;
    _activeTag = tag;
    return created;
  }

  static StoryCommentsController? maybeFind({String? tag}) {
    final resolvedTag = (tag ?? _activeTag)?.trim();
    final isRegistered = Get.isRegistered<StoryCommentsController>(
      tag: resolvedTag?.isEmpty == true ? null : resolvedTag,
    );
    if (!isRegistered) return null;
    return Get.find<StoryCommentsController>(
      tag: resolvedTag?.isEmpty == true ? null : resolvedTag,
    );
  }

  final StoryRepository _storyRepository = StoryRepository.ensure();
  RxList<StoryCommentModel> list = <StoryCommentModel>[].obs;
  FocusNode commentFocus = FocusNode();
  TextEditingController commentTextfield = TextEditingController();
  String nickname = "";
  String storyID = "";
  String? controllerTag;
  var totalComment = 0.obs;
  final RxString selectedGifUrl = ''.obs;
  final RxString lastSuccessfulCommentText = ''.obs;
  final RxString lastSuccessfulCommentGif = ''.obs;

  StoryCommentsController({required this.nickname, required this.storyID});

  String get _currentUserId => CurrentUserService.instance.effectiveUserId;

  Future<void> getData() => _getDataImpl();

  Future<void> getLast() => _getLastImpl();

  Future<void> setComment() => _setCommentImpl();

  Future<void> pickGif(BuildContext context) => _pickGifImpl(context);

  void clearSelectedGif() => _clearSelectedGifImpl();

  @override
  void onClose() {
    _handleClose();
    super.onClose();
  }
}
