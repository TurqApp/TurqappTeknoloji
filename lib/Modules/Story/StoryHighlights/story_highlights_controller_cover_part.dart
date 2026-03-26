part of 'story_highlights_controller.dart';

extension _StoryHighlightsControllerCoverPartX on StoryHighlightsController {
  Future<void> _hydrateMissingCoverUrls() async {
    if (highlights.isEmpty) return;
    final canPersist = _canMutateOwnedHighlights;
    var anyLocalUpdate = false;

    for (var i = 0; i < highlights.length; i++) {
      final item = highlights[i];
      if (item.coverUrl.trim().isNotEmpty || item.storyIds.isEmpty) {
        continue;
      }
      final cover = await _resolveCoverUrlFromStoryIds(
        item.storyIds,
        highlightId: item.id,
      );
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

  Future<String> _resolveCoverUrlFromStoryIds(
    List<String> storyIds, {
    required String highlightId,
  }) async {
    for (final storyId in storyIds) {
      final data = await _storyRepository.getStoryRaw(
        storyId,
        preferCache: true,
      );
      if (data == null) continue;
      if ((data['deleted'] ?? false) == true) continue;
      final extracted = _extractPreviewUrlFromStoryData(data);
      if (extracted.isNotEmpty) return extracted;
      if (!_canMutateOwnedHighlights) continue;
      final generated = await _generateHighlightThumbnailFromStoryData(
        data,
        highlightId: highlightId,
      );
      if (generated.isNotEmpty) return generated;
    }
    return '';
  }

  Future<String> _generateHighlightThumbnailFromStoryData(
    Map<String, dynamic> data, {
    required String highlightId,
  }) async {
    final uid = _ownerUid;
    if (uid.isEmpty || highlightId.trim().isEmpty) return '';
    final videoUrl = _extractVideoUrlFromStoryData(data);
    if (videoUrl.isEmpty) return '';
    try {
      final thumbData = await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.JPEG,
        quality: 75,
      );
      if (thumbData == null || thumbData.isEmpty) return '';
      final uploadUrl = await WebpUploadService.uploadBytesAsWebp(
        storage: FirebaseStorage.instance,
        bytes: thumbData,
        storagePathWithoutExt: 'highlights/$uid/$highlightId/cover',
      );
      return CdnUrlBuilder.toCdnUrl(uploadUrl);
    } catch (e, st) {
      debugPrint('StoryHighlights thumbnail generate failed: $e');
      debugPrintStack(stackTrace: st);
      return '';
    }
  }

  String _extractPreviewUrlFromStoryData(Map<String, dynamic> data) {
    final elements = data['elements'];
    if (elements is List) {
      final asMaps = elements
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry('$k', v)))
          .toList();

      for (final m in asMaps) {
        final type = normalizeSearchText((m['type'] ?? '').toString());
        final content = (m['content'] ?? '').toString().trim();
        if (content.isEmpty) continue;
        if ((type == 'image' || type == 'gif') && _isLikelyImageUrl(content)) {
          return content;
        }
      }

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

  String _extractVideoUrlFromStoryData(Map<String, dynamic> data) {
    final topLevelVideo =
        (data['videoUrl'] ?? data['video'] ?? '').toString().trim();
    if (_looksLikeVideoUrl(topLevelVideo)) return topLevelVideo;

    final elements = data['elements'];
    if (elements is! List) return '';
    for (final raw in elements) {
      if (raw is! Map) continue;
      final entry = raw.map((k, v) => MapEntry('$k', v));
      final content = (entry['content'] ?? '').toString().trim();
      if (_looksLikeVideoUrl(content)) return content;
    }
    return '';
  }

  bool _looksLikeVideoUrl(String url) {
    final clean = url.trim().toLowerCase();
    if (clean.isEmpty) return false;
    return clean.contains('.mp4') ||
        clean.contains('.mov') ||
        clean.contains('.m4v') ||
        clean.contains('.webm') ||
        clean.contains('video') ||
        clean.contains('videoplayback');
  }
}
