import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Services/giphy_picker_service.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Models/story_comment_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'story_comments_controller_facade_part.dart';
part 'story_comments_controller_runtime_part.dart';

class StoryCommentsController extends GetxController {
  static String? _activeTag;

  static StoryCommentsController ensure({
    required String nickname,
    required String storyID,
    String? tag,
    bool permanent = false,
  }) =>
      _ensureStoryCommentsController(
        nickname: nickname,
        storyID: storyID,
        tag: tag,
        permanent: permanent,
      );

  static StoryCommentsController? maybeFind({String? tag}) =>
      _maybeFindStoryCommentsController(tag: tag);

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

  String get _currentUserId => _storyCommentsCurrentUserId();

  Future<void> getData() => _getStoryCommentsData(this);

  Future<void> getLast() => _getLastStoryComment(this);

  Future<void> setComment() => _setStoryComment(this);

  Future<void> pickGif(BuildContext context) => _pickStoryGif(this, context);

  void clearSelectedGif() => _clearStorySelectedGif(this);

  @override
  void onClose() {
    _handleStoryCommentsClose(this);
    super.onClose();
  }
}
