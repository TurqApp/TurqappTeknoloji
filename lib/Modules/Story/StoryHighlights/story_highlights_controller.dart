import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Repositories/story_highlights_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/Utils/url_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'story_highlight_model.dart';

class StoryHighlightsController extends GetxController {
  static StoryHighlightsController _ensureController({
    required String userId,
    required String tag,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(StoryHighlightsController(userId: userId), tag: tag);
  }

  static StoryHighlightsController ensure({
    required String userId,
    required String tag,
  }) =>
      _ensureController(userId: userId, tag: tag);

  static StoryHighlightsController? maybeFind({required String tag}) {
    if (!Get.isRegistered<StoryHighlightsController>(tag: tag)) return null;
    return Get.find<StoryHighlightsController>(tag: tag);
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final String userId;
  StoryHighlightsController({required this.userId});
  final StoryHighlightsRepository _repository =
      StoryHighlightsRepository.ensure();
  final StoryRepository _storyRepository = StoryRepository.ensure();
  final CurrentUserService _userService = CurrentUserService.instance;

  RxList<StoryHighlightModel> highlights = <StoryHighlightModel>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapHighlights());
  }

  Future<void> _bootstrapHighlights() async {
    final cached = await _repository.getHighlights(
      userId,
      preferCache: true,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      highlights.assignAll(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'story:highlights:$userId',
        minInterval: _silentRefreshInterval,
      )) {
        unawaited(loadHighlights(silent: true, forceRefresh: true));
      }
      unawaited(_hydrateMissingCoverUrls());
      return;
    }
    await loadHighlights();
  }

  Future<void> loadHighlights({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    try {
      if (!silent) {
        isLoading.value = true;
      }
      highlights.value = await _repository.getHighlights(
        userId,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      SilentRefreshGate.markRefreshed('story:highlights:$userId');
      await _hydrateMissingCoverUrls();
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<StoryHighlightModel?> createHighlight({
    required String title,
    required List<String> storyIds,
    String coverUrl = '',
  }) async {
    try {
      final uid = _userService.userId.trim();
      if (uid.isEmpty) return null;

      final docRefId = DateTime.now().microsecondsSinceEpoch.toString();

      var resolvedCoverUrl = coverUrl.trim();
      if (resolvedCoverUrl.isEmpty && storyIds.isNotEmpty) {
        resolvedCoverUrl = await _resolveCoverUrlFromStoryIds(storyIds);
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
      await _repository.setHighlights(
        uid,
        List<StoryHighlightModel>.from(highlights),
      );
      return model;
    } catch (_) {
      return null;
    }
  }

  Future<void> addStoryToHighlight(String highlightId, String storyId) async {
    try {
      final uid = _userService.userId.trim();
      if (uid.isEmpty) return;

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
      final uid = _userService.userId.trim();
      if (uid.isEmpty) return;

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
      final uid = _userService.userId.trim();
      if (uid.isEmpty) return;

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

  Future<void> _hydrateMissingCoverUrls() async {
    if (highlights.isEmpty) return;
    final currentUid = _userService.userId.trim();
    final canPersist = currentUid.isNotEmpty && currentUid == userId;
    var anyLocalUpdate = false;

    for (var i = 0; i < highlights.length; i++) {
      final item = highlights[i];
      if (item.coverUrl.trim().isNotEmpty || item.storyIds.isEmpty) {
        continue;
      }
      final cover = await _resolveCoverUrlFromStoryIds(item.storyIds);
      if (cover.isEmpty) continue;

      item.coverUrl = cover;
      anyLocalUpdate = true;

      if (canPersist) {
        try {
          await _repository.updateCoverUrl(
            userId,
            highlightId: item.id,
            coverUrl: cover,
          );
        } catch (_) {}
      }
    }

    if (anyLocalUpdate) {
      highlights.refresh();
      await _repository.setHighlights(
        userId,
        List<StoryHighlightModel>.from(highlights),
      );
    }
  }

  Future<String> _resolveCoverUrlFromStoryIds(List<String> storyIds) async {
    for (final storyId in storyIds) {
      final data = await _storyRepository.getStoryRaw(
        storyId,
        preferCache: true,
      );
      if (data == null) continue;
      if ((data['deleted'] ?? false) == true) continue;
      final extracted = _extractPreviewUrlFromStoryData(data);
      if (extracted.isNotEmpty) return extracted;
    }
    return '';
  }

  String _extractPreviewUrlFromStoryData(Map<String, dynamic> data) {
    final elements = data['elements'];
    if (elements is List) {
      final asMaps = elements
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry('$k', v)))
          .toList();

      // 1) Image/GIF iceriklerini onceliklendir.
      for (final m in asMaps) {
        final type = normalizeSearchText((m['type'] ?? '').toString());
        final content = (m['content'] ?? '').toString().trim();
        if (content.isEmpty) continue;
        if ((type == 'image' || type == 'gif') && _isLikelyImageUrl(content)) {
          return content;
        }
      }

      // 2) Bilinen thumbnail alanlari.
      for (final m in asMaps) {
        final thumb = (m['thumbnail'] ??
                m['thumbnailUrl'] ??
                m['thumbUrl'] ??
                m['previewUrl'] ??
                m['coverUrl'] ??
                '')
            .toString()
            .trim();
        if (_isLikelyImageUrl(thumb)) return thumb;
      }

      // 3) Herhangi bir image URL.
      for (final m in asMaps) {
        final content = (m['content'] ?? '').toString().trim();
        if (_isLikelyImageUrl(content)) return content;
      }
    }

    final topLevelThumb = (data['thumbnail'] ??
            data['thumbnailUrl'] ??
            data['thumbUrl'] ??
            data['previewUrl'] ??
            data['coverUrl'] ??
            '')
        .toString()
        .trim();
    if (_isLikelyImageUrl(topLevelThumb)) return topLevelThumb;
    return '';
  }

  bool _isLikelyImageUrl(String url) {
    return looksLikeImageUrl(url);
  }
}
