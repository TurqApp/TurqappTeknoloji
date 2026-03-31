import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CacheFirstNetworkImage extends StatefulWidget {
  final String imageUrl;
  final CacheManager cacheManager;
  final BoxFit fit;
  final Widget fallback;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const CacheFirstNetworkImage({
    super.key,
    required this.imageUrl,
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
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_resolveLocalFile(widget.imageUrl));
  }

  @override
  void didUpdateWidget(covariant CacheFirstNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl.trim() != widget.imageUrl.trim()) {
      unawaited(_resolveLocalFile(widget.imageUrl));
    }
  }

  Future<void> _resolveLocalFile(String url) async {
    final requestId = ++_loadSeq;
    final normalized = url.trim();
    if (normalized.isEmpty) {
      if (_resolvedFilePath.isNotEmpty && mounted) {
        setState(() {
          _resolvedFilePath = '';
        });
      }
      return;
    }

    try {
      final cached = await widget.cacheManager.getFileFromCache(normalized);
      final file = cached?.file;
      final nextPath = (file != null && file.existsSync()) ? file.path : '';
      if (!mounted || requestId != _loadSeq) return;
      if (nextPath != _resolvedFilePath) {
        setState(() {
          _resolvedFilePath = nextPath;
        });
      }
    } catch (_) {
      if (!mounted || requestId != _loadSeq) return;
      if (_resolvedFilePath.isNotEmpty) {
        setState(() {
          _resolvedFilePath = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalized = widget.imageUrl.trim();
    if (normalized.isEmpty) return widget.fallback;

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

    return CachedNetworkImage(
      imageUrl: normalized,
      cacheManager: widget.cacheManager,
      fit: widget.fit,
      memCacheWidth: widget.memCacheWidth,
      memCacheHeight: widget.memCacheHeight,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      placeholder: (_, __) => widget.fallback,
      errorWidget: (_, __, ___) => widget.fallback,
    );
  }
}
