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
part 'story_highlights_controller_runtime_part.dart';

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
  }) async {
    try {
      final uid = _ownerUid;
      if (uid.isEmpty || !_canMutateOwnedHighlights) return null;

      final docRefId = DateTime.now().microsecondsSinceEpoch.toString();

      var resolvedCoverUrl = coverUrl.trim();
      if (resolvedCoverUrl.isNotEmpty && !looksLikeImageUrl(resolvedCoverUrl)) {
        resolvedCoverUrl = '';
      }
      if (resolvedCoverUrl.isEmpty && storyIds.isNotEmpty) {
        try {
          resolvedCoverUrl = await _resolveCoverUrlFromStoryIds(
            storyIds,
            highlightId: docRefId,
          );
        } catch (e, st) {
          debugPrint('StoryHighlights create cover resolve error: $e');
          debugPrintStack(stackTrace: st);
          resolvedCoverUrl = '';
        }
      }

      final model = StoryHighlightModel(
        id: docRefId,
        userId: uid,
        title: title,
        coverUrl: resolvedCoverUrl,
        storyIds: storyIds,
        createdAt: DateTime.now(),
        order: highlights.length,
      );

      await _repository.createHighlight(uid, model);
      highlights.add(model);
      try {
        await _repository.setHighlights(
          uid,
          List<StoryHighlightModel>.from(highlights),
        );
      } catch (e, st) {
        debugPrint('StoryHighlights create cache persist error: $e');
        debugPrintStack(stackTrace: st);
      }
      return model;
    } catch (e, st) {
      debugPrint('StoryHighlights create failed: $e');
      debugPrintStack(stackTrace: st);
      return null;
    }
  }

  Future<void> addStoryToHighlight(String highlightId, String storyId) async {
    try {
      final uid = _ownerUid;
      if (uid.isEmpty || !_canMutateOwnedHighlights) return;

      await _repository.addStoryToHighlight(
        uid,
        highlightId: highlightId,
        storyId: storyId,
      );

      final idx = highlights.indexWhere((h) => h.id == highlightId);
      if (idx != -1) {
        highlights[idx].storyIds.add(storyId);
        highlights.refresh();
        await _repository.setHighlights(
          uid,
          List<StoryHighlightModel>.from(highlights),
        );
      }
    } catch (_) {}
  }

  Future<void> deleteHighlight(String highlightId) async {
    try {
      final uid = _ownerUid;
      if (uid.isEmpty || !_canMutateOwnedHighlights) return;

      await _repository.deleteHighlight(
        uid,
        highlightId: highlightId,
      );

      highlights.removeWhere((h) => h.id == highlightId);
      await _repository.setHighlights(
        uid,
        List<StoryHighlightModel>.from(highlights),
      );
    } catch (_) {}
  }

  Future<void> updateHighlight(
      String highlightId, String title, String coverUrl) async {
    try {
      final uid = _ownerUid;
      if (uid.isEmpty || !_canMutateOwnedHighlights) return;

      await _repository.updateHighlight(
        uid,
        highlightId: highlightId,
        title: title,
        coverUrl: coverUrl,
      );

      final idx = highlights.indexWhere((h) => h.id == highlightId);
      if (idx != -1) {
        highlights[idx].title = title;
        highlights[idx].coverUrl = coverUrl;
        highlights.refresh();
        await _repository.setHighlights(
          uid,
          List<StoryHighlightModel>.from(highlights),
        );
      }
    } catch (_) {}
  }
}
