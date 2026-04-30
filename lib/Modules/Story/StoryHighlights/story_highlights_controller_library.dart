import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/story_highlights_repository.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/Utils/url_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'story_highlight_model.dart';

part 'story_highlights_controller_constants_part.dart';
part 'story_highlights_controller_cover_part.dart';
part 'story_highlights_controller_fields_part.dart';
part 'story_highlights_controller_runtime_part.dart';
part 'story_highlights_controller_actions_part.dart';
part 'story_highlights_controller_support_part.dart';

abstract class _StoryHighlightsControllerBase extends GetxController {
  _StoryHighlightsControllerBase({required String userId})
      : _state = _StoryHighlightsControllerState(userId: userId);

  final _StoryHighlightsControllerState _state;
}

class StoryHighlightsController extends _StoryHighlightsControllerBase {
  StoryHighlightsController({required super.userId});

  @override
  void onInit() {
    super.onInit();
    unawaited(_StoryHighlightsControllerRuntimeX(this)._bootstrapHighlights());
  }
}

extension StoryHighlightsControllerFacadePart on StoryHighlightsController {
  Future<void> loadHighlights({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _StoryHighlightsControllerRuntimeX(this).loadHighlights(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  Future<StoryHighlightModel?> createHighlight({
    required String title,
    required List<String> storyIds,
    String coverUrl = '',
  }) =>
      _StoryHighlightsControllerActionsX(this).createHighlight(
        title: title,
        storyIds: storyIds,
        coverUrl: coverUrl,
      );

  Future<void> addStoryToHighlight(String highlightId, String storyId) =>
      _StoryHighlightsControllerActionsX(this).addStoryToHighlight(
        highlightId,
        storyId,
      );

  Future<void> deleteHighlight(String highlightId) =>
      _StoryHighlightsControllerActionsX(this).deleteHighlight(highlightId);

  Future<void> updateHighlight(
    String highlightId,
    String title,
    String coverUrl,
  ) =>
      _StoryHighlightsControllerActionsX(this).updateHighlight(
        highlightId,
        title,
        coverUrl,
      );
}
