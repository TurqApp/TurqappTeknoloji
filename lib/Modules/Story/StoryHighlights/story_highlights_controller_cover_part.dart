part of 'story_highlights_controller_library.dart';

class _GeneratedHighlightCoverResult {
  const _GeneratedHighlightCoverResult({
    required this.bytes,
    required this.frameMs,
  });

  final Uint8List bytes;
  final int frameMs;
}

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
      final generated = await _generateStandardHighlightCover(videoUrl);
      if (generated == null || generated.bytes.isEmpty) return '';
      final uploadUrl = await WebpUploadService.uploadBytesAsWebp(
        bytes: generated.bytes,
        storagePathWithoutExt: 'highlights/$uid/$highlightId/cover',
      );
      return CdnUrlBuilder.toCdnUrl(uploadUrl);
    } catch (e, st) {
      debugPrint('StoryHighlights thumbnail generate failed: $e');
      debugPrintStack(stackTrace: st);
      return '';
    }
  }

  Future<_GeneratedHighlightCoverResult?> _generateStandardHighlightCover(
    String videoUrl,
  ) async {
    const candidateTimes = <int>[0, 33, 67, 100];
    _GeneratedHighlightCoverResult? bestResult;
    double bestScore = double.negativeInfinity;

    for (final timeMs in candidateTimes) {
      final data = await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.JPEG,
        timeMs: timeMs,
        quality: 75,
      );
      if (data == null || data.isEmpty) continue;
      final score = await _thumbnailQualityScore(data);
      if (score == null) continue;
      final result = _GeneratedHighlightCoverResult(
        bytes: data,
        frameMs: timeMs,
      );
      if (score >= 0.12) return result;
      if (score > bestScore) {
        bestScore = score;
        bestResult = result;
      }
    }
    return bestResult;
  }

  Future<double?> _thumbnailQualityScore(Uint8List data) async {
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (bytes == null) return null;

    final buffer = bytes.buffer.asUint8List();
    if (buffer.length < 4) return null;
    final pixelCount = buffer.length ~/ 4;
    if (pixelCount <= 0) return null;

    double luminanceSum = 0;
    for (var i = 0; i < buffer.length; i += 4) {
      luminanceSum +=
          0.2126 * buffer[i] + 0.7152 * buffer[i + 1] + 0.0722 * buffer[i + 2];
    }
    final mean = luminanceSum / pixelCount;

    double varianceSum = 0;
    for (var i = 0; i < buffer.length; i += 4) {
      final luminance =
          0.2126 * buffer[i] + 0.7152 * buffer[i + 1] + 0.0722 * buffer[i + 2];
      final diff = luminance - mean;
      varianceSum += diff * diff;
    }
    final stdDev = math.sqrt(varianceSum / pixelCount);
    final normalizedBrightness = (mean / 255).clamp(0.0, 1.0);
    final normalizedContrast = (stdDev / 128).clamp(0.0, 1.0);
    return normalizedBrightness * 0.45 + normalizedContrast * 0.55;
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
