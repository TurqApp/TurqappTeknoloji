import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Repositories/story_highlights_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/Utils/url_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'story_highlight_model.dart';

part 'story_highlights_controller_cover_part.dart';
part 'story_highlights_controller_facade_part.dart';
part 'story_highlights_controller_runtime_part.dart';
part 'story_highlights_controller_actions_part.dart';

class StoryHighlightsController extends GetxController {
  static StoryHighlightsController ensure({
    required String userId,
    required String tag,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(StoryHighlightsController(userId: userId), tag: tag);
  }

  static StoryHighlightsController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<StoryHighlightsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<StoryHighlightsController>(tag: tag);
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final String userId;
  StoryHighlightsController({required this.userId});
  final StoryHighlightsRepository _repository =
      StoryHighlightsRepository.ensure();
  final StoryRepository _storyRepository = StoryRepository.ensure();
  final CurrentUserService _userService = CurrentUserService.instance;
  String get _ownerUid => userId.trim();

  bool get _canMutateOwnedHighlights {
    final ownerUid = _ownerUid;
    if (ownerUid.isEmpty) return false;
    final authUid = _userService.authUserId.trim();
    if (authUid.isEmpty) return true;
    return authUid == ownerUid;
  }

  RxList<StoryHighlightModel> highlights = <StoryHighlightModel>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_StoryHighlightsControllerRuntimeX(this)._bootstrapHighlights());
  }
}
