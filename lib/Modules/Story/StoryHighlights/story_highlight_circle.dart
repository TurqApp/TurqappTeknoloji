import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Utils/url_utils.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'story_highlight_model.dart';

class StoryHighlightCircle extends StatelessWidget {
  final StoryHighlightModel highlight;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const StoryHighlightCircle({
    super.key,
    required this.highlight,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Center(
        child: SizedBox(
          width: 70,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withAlpha(50)),
                ),
                padding: const EdgeInsets.all(4),
                child:
                    ClipOval(child: _HighlightCoverImage(highlight: highlight)),
              ),
              const SizedBox(height: 4),
              Text(
                highlight.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightCoverImage extends StatefulWidget {
  const _HighlightCoverImage({required this.highlight});

  final StoryHighlightModel highlight;

  @override
  State<_HighlightCoverImage> createState() => _HighlightCoverImageState();
}

class _HighlightCoverImageState extends State<_HighlightCoverImage> {
  String _resolvedUrl = '';
  Uint8List? _thumbnailBytes;
  bool _isResolving = false;
  bool _needsResolveRetry = false;
  int _resolveGeneration = 0;

  @override
  void initState() {
    super.initState();
    final initialCover = widget.highlight.coverUrl.trim();
    _resolvedUrl = looksLikeImageUrl(initialCover) ? initialCover : '';
    if (_resolvedUrl.isEmpty) {
      _scheduleFallbackThumbnailResolution();
    }
  }

  @override
  void didUpdateWidget(covariant _HighlightCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final rawLatest = widget.highlight.coverUrl.trim();
    final latest = looksLikeImageUrl(rawLatest) ? rawLatest : '';
    final storyIdsChanged =
        !listEquals(oldWidget.highlight.storyIds, widget.highlight.storyIds);
    final coverChanged = oldWidget.highlight.coverUrl.trim() != rawLatest;

    if (coverChanged || storyIdsChanged) {
      _resolveGeneration++;
    }

    if (latest.isNotEmpty) {
      if (latest != _resolvedUrl || _thumbnailBytes != null) {
        _resolvedUrl = latest;
        _thumbnailBytes = null;
      }
      _needsResolveRetry = false;
      return;
    }

    if (!coverChanged && !storyIdsChanged) return;

    if (_resolvedUrl.isNotEmpty || _thumbnailBytes != null) {
      _resolvedUrl = '';
      _thumbnailBytes = null;
    }
    _scheduleFallbackThumbnailResolution();
  }

  void _scheduleFallbackThumbnailResolution() {
    if (_isResolving) {
      _needsResolveRetry = true;
      return;
    }
    _needsResolveRetry = false;
    _resolveFallbackThumbnail();
  }

  Future<void> _resolveFallbackThumbnail() async {
    if (_isResolving || widget.highlight.storyIds.isEmpty) return;
    final generation = _resolveGeneration;
    final storyId = widget.highlight.storyIds.first;
    _isResolving = true;
    try {
      final raw = await StoryRepository.ensure().getStoryRaw(
        storyId,
        preferCache: true,
      );
      if (!mounted || raw == null || generation != _resolveGeneration) return;
      final preview = _extractPreviewUrl(raw);
      if (!mounted || generation != _resolveGeneration) return;
      if (preview.isNotEmpty) {
        setState(() {
          _resolvedUrl = preview;
          _thumbnailBytes = null;
        });
        return;
      }
      final videoUrl = _extractVideoUrl(raw);
      if (videoUrl.isEmpty) return;
      final thumb = await _generateEarlyFrameThumbnail(videoUrl);
      if (!mounted ||
          thumb == null ||
          thumb.isEmpty ||
          generation != _resolveGeneration) {
        return;
      }
      setState(() {
        _thumbnailBytes = thumb;
      });
    } finally {
      _isResolving = false;
      if (_needsResolveRetry && mounted) {
        _needsResolveRetry = false;
        await _resolveFallbackThumbnail();
      }
    }
  }

  Future<Uint8List?> _generateEarlyFrameThumbnail(String videoUrl) async {
    const candidateTimes = <int>[0, 33, 67, 100];
    Uint8List? bestData;
    double bestScore = double.negativeInfinity;

    for (final timeMs in candidateTimes) {
      final data = await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.JPEG,
        timeMs: timeMs,
        maxWidth: 240,
        quality: 70,
      );
      if (data == null || data.isEmpty) continue;
      final score = await _thumbnailQualityScore(data);
      if (score == null) continue;
      if (score >= 0.12) return data;
      if (score > bestScore) {
        bestScore = score;
        bestData = data;
      }
    }
    return bestData;
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

  String _extractPreviewUrl(Map<String, dynamic> data) {
    final topLevelThumb = (data['thumbnail'] ??
            data['thumbnailUrl'] ??
            data['thumbUrl'] ??
            data['previewUrl'] ??
            data['coverUrl'] ??
            data['musicCoverUrl'] ??
            '')
        .toString()
        .trim();
    if (looksLikeImageUrl(topLevelThumb)) return topLevelThumb;

    final elements = data['elements'];
    if (elements is! List) return '';
    for (final raw in elements) {
      if (raw is! Map) continue;
      final entry = raw.map((key, value) => MapEntry('$key', value));
      final thumb = (entry['thumbnail'] ??
              entry['thumbnailUrl'] ??
              entry['thumbUrl'] ??
              entry['previewUrl'] ??
              entry['coverUrl'] ??
              '')
          .toString()
          .trim();
      if (looksLikeImageUrl(thumb)) return thumb;
    }
    for (final raw in elements) {
      if (raw is! Map) continue;
      final entry = raw.map((key, value) => MapEntry('$key', value));
      final content = (entry['content'] ?? '').toString().trim();
      if (looksLikeImageUrl(content)) return content;
    }
    return '';
  }

  String _extractVideoUrl(Map<String, dynamic> data) {
    final topLevelVideo =
        (data['videoUrl'] ?? data['video'] ?? '').toString().trim();
    if (_looksLikeVideoUrl(topLevelVideo)) return topLevelVideo;

    final elements = data['elements'];
    if (elements is! List) return '';
    for (final raw in elements) {
      if (raw is! Map) continue;
      final entry = raw.map((key, value) => MapEntry('$key', value));
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

  @override
  Widget build(BuildContext context) {
    if (_resolvedUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: _resolvedUrl,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, __) => _buildPlaceholder(),
        errorWidget: (_, __, ___) => _buildPlaceholder(),
      );
    }
    if (_thumbnailBytes != null && _thumbnailBytes!.isNotEmpty) {
      return Image.memory(
        _thumbnailBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.withAlpha(30),
      child: const Icon(
        CupertinoIcons.collections,
        color: Colors.grey,
        size: 20,
      ),
    );
  }
}
