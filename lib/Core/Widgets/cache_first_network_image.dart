import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CacheFirstNetworkImage extends StatefulWidget {
  final String imageUrl;
  final List<String> candidateUrls;
  final CacheManager cacheManager;
  final BoxFit fit;
  final Widget fallback;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const CacheFirstNetworkImage({
    super.key,
    required this.imageUrl,
    this.candidateUrls = const <String>[],
    required this.cacheManager,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  State<CacheFirstNetworkImage> createState() => _CacheFirstNetworkImageState();
}

class _CacheFirstNetworkImageState extends State<CacheFirstNetworkImage> {
  String _resolvedFilePath = '';
  String _activeImageUrl = '';
  int _activeIndex = 0;
  int _loadSeq = 0;
  bool _exhaustedCandidates = false;
  bool _advanceScheduled = false;

  @override
  void initState() {
    super.initState();
    _syncCandidates();
  }

  @override
  void didUpdateWidget(covariant CacheFirstNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldUrls = <String>[
      oldWidget.imageUrl.trim(),
      ...oldWidget.candidateUrls.map((url) => url.trim()),
    ].where((url) => url.isNotEmpty).join('|');
    final nextUrls = <String>[
      widget.imageUrl.trim(),
      ...widget.candidateUrls.map((url) => url.trim()),
    ].where((url) => url.isNotEmpty).join('|');
    if (oldUrls != nextUrls) {
      _syncCandidates();
    }
  }

  List<String> _normalizedCandidates() {
    final urls = <String>[];
    for (final rawUrl in <String>[widget.imageUrl, ...widget.candidateUrls]) {
      final normalized = rawUrl.trim();
      if (normalized.isEmpty || urls.contains(normalized)) continue;
      urls.add(normalized);
    }
    return urls;
  }

  void _syncCandidates() {
    final candidates = _normalizedCandidates();
    _resolvedFilePath = '';
    _activeIndex = 0;
    _activeImageUrl = candidates.isEmpty ? '' : candidates.first;
    _exhaustedCandidates = candidates.isEmpty;
    _advanceScheduled = false;
    if (mounted) {
      setState(() {});
    }
    unawaited(_resolveLocalFile(candidates));
  }

  Future<void> _resolveLocalFile(List<String> urls) async {
    final requestId = ++_loadSeq;
    if (urls.isEmpty) {
      if (_resolvedFilePath.isNotEmpty && mounted) {
        setState(() {
          _resolvedFilePath = '';
        });
      }
      return;
    }

    try {
      String nextPath = '';
      String nextUrl = _activeImageUrl;
      for (var i = 0; i < urls.length; i++) {
        final cached = await widget.cacheManager.getFileFromCache(urls[i]);
        final file = cached?.file;
        if (file != null && file.existsSync()) {
          nextPath = file.path;
          nextUrl = urls[i];
          break;
        }
      }
      if (!mounted || requestId != _loadSeq) return;
      if (nextPath != _resolvedFilePath || nextUrl != _activeImageUrl) {
        final absoluteIndex = _normalizedCandidates().indexOf(nextUrl);
        setState(() {
          _resolvedFilePath = nextPath;
          _activeImageUrl = nextUrl;
          if (absoluteIndex >= 0) {
            _activeIndex = absoluteIndex;
          }
          _exhaustedCandidates = urls.isEmpty;
          _advanceScheduled = false;
        });
      }
    } catch (_) {
      if (!mounted || requestId != _loadSeq) return;
      if (_resolvedFilePath.isNotEmpty || _activeImageUrl.isNotEmpty) {
        setState(() {
          _resolvedFilePath = '';
          _activeImageUrl = urls.isEmpty ? '' : urls.first;
          _activeIndex = 0;
          _exhaustedCandidates = urls.isEmpty;
          _advanceScheduled = false;
        });
      }
    }
  }

  void _scheduleAdvanceCandidate() {
    if (_advanceScheduled) return;
    _advanceScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final candidates = _normalizedCandidates();
      if (_activeIndex + 1 < candidates.length) {
        setState(() {
          _activeIndex += 1;
          _activeImageUrl = candidates[_activeIndex];
          _advanceScheduled = false;
        });
        unawaited(_resolveLocalFile(candidates));
        return;
      }
      setState(() {
        _exhaustedCandidates = true;
        _advanceScheduled = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final candidates = _normalizedCandidates();
    if (candidates.isEmpty) return widget.fallback;

    if (_resolvedFilePath.isNotEmpty) {
      final file = File(_resolvedFilePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: widget.fit,
          gaplessPlayback: true,
        );
      }
    }

    if (_exhaustedCandidates) {
      return widget.fallback;
    }

    final activeUrl = _activeImageUrl.isNotEmpty ? _activeImageUrl : candidates.first;
    return Image(
      image: ResizeImage.resizeIfNeeded(
        widget.memCacheWidth,
        widget.memCacheHeight,
        CachedNetworkImageProvider(
          activeUrl,
          cacheManager: widget.cacheManager,
        ),
      ),
      fit: widget.fit,
      gaplessPlayback: true,
      frameBuilder: (_, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return const SizedBox.expand();
      },
      errorBuilder: (_, __, ___) {
        _scheduleAdvanceCandidate();
        return const SizedBox.expand();
      },
    );
  }
}
