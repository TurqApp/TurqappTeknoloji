import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Services/giphy_picker_service.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Models/story_comment_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class StoryCommentsController extends GetxController {
  final StoryRepository _storyRepository = StoryRepository.ensure();
  RxList<StoryCommentModel> list = <StoryCommentModel>[].obs;
  FocusNode commentFocus = FocusNode();
  TextEditingController commentTextfield = TextEditingController();
  String nickname = "";
  String storyID = "";
  var totalComment = 0.obs;
  final RxString selectedGifUrl = ''.obs;

  StoryCommentsController({required this.nickname, required this.storyID});

  String get _currentUserId {
    final serviceUid = CurrentUserService.instance.userId.trim();
    if (serviceUid.isNotEmpty) return serviceUid;
    return FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
  }

  Future<void> getData() async {
    list.assignAll(await _storyRepository.fetchStoryComments(storyID));
    totalComment.value = await _storyRepository.fetchStoryCommentCount(storyID);
  }

  Future<void> getLast() async {
    final last = await _storyRepository.fetchLatestStoryComment(storyID);
    if (last != null) {
      list.insert(0, last);
    }

    totalComment.value++;
  }

  Future<void> setComment() async {
    final text = commentTextfield.text.trim();
    final gif = selectedGifUrl.value.trim();
    if (text.isEmpty && gif.isEmpty) {
      return;
    }
    try {
      await _storyRepository.addStoryComment(
        storyID,
        userId: _currentUserId,
        text: text,
        gif: gif,
      );
      commentTextfield.clear();
      selectedGifUrl.value = '';
      await getLast();
      closeKeyboard(Get.context!);
    } catch (e) {
      debugPrint("setComment error: $e");
    }
  }

  Future<void> pickGif(BuildContext context) async {
    final url = await GiphyPickerService.pickGifUrl(
      context,
      randomId: 'turqapp_story_comments',
    );
    if (url != null && url.trim().isNotEmpty) {
      selectedGifUrl.value = url.trim();
    }
  }

  void clearSelectedGif() {
    selectedGifUrl.value = '';
  }

  @override
  void onClose() {
    commentFocus.dispose();
    commentTextfield.dispose();
    super.onClose();
  }
}
