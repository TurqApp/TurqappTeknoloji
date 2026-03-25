import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Services/story_music_library_service.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_model.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:flutter/material.dart';

part 'deleted_stories_controller_data_part.dart';
part 'deleted_stories_controller_runtime_part.dart';

class DeletedStoriesController extends GetxController {
  static DeletedStoriesController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(DeletedStoriesController());
  }

  static DeletedStoriesController? maybeFind() {
    final isRegistered = Get.isRegistered<DeletedStoriesController>();
    if (!isRegistered) return null;
    return Get.find<DeletedStoriesController>();
  }

  RxList<StoryModel> list = <StoryModel>[].obs;
  RxBool isLoading = false.obs;
  // Silinme zamanı bilgisi (ms) – UI'da göstermek için
  final RxMap<String, int> deletedAtById = <String, int>{}.obs;
  final RxMap<String, String> deleteReasonById = <String, String>{}.obs;
  // UI paging
  final PageController pageController = PageController();
  final StoryRepository _storyRepository = StoryRepository.ensure();
  final CurrentUserService _userService = CurrentUserService.instance;
  String get _currentUid => _userService.effectiveUserId;

  @override
  void onInit() {
    super.onInit();
    _handleDeletedStoriesInit();
  }

  @override
  Future<void> refresh() async {
    await _handleDeletedStoriesRefresh();
  }

  void goToPage(int index) {
    _handleGoToPage(index);
  }

  @override
  void onClose() {
    _handleDeletedStoriesClose();
    super.onClose();
  }
}
