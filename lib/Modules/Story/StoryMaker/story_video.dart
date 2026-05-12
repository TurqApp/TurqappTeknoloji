import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Services/audio_focus_coordinator.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:video_player/video_player.dart';

class StoryVideo extends StatefulWidget {
  final String path;
  final bool isMuted;
  final String posterUrl;

  const StoryVideo({
    super.key,
    required this.path,
    this.isMuted = false,
    this.posterUrl = '',
  });

  @override
  _StoryVideoState createState() => _StoryVideoState();
}

class _StoryVideoState extends State<StoryVideo> {
  late VideoPlayerController _vidCtrl;
  bool _failed = false;

  bool _isRemoteUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.hasAuthority;
  }

  @override
  void initState() {
    super.initState();
    _vidCtrl = _isRemoteUrl(widget.path)
        ? VideoPlayerController.networkUrl(Uri.parse(widget.path))
        : VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        if (!mounted) return;
        AudioFocusCoordinator.instance.registerPreviewPlayer(_vidCtrl);
        _vidCtrl.setLooping(true);
        _vidCtrl.setVolume(widget.isMuted ? 0 : 1);
        if (widget.isMuted) {
          _vidCtrl.play();
        } else {
          AudioFocusCoordinator.instance
              .requestPreviewPlay(_vidCtrl)
              .then((_) => _vidCtrl.play());
        }
        setState(() {});
      }).catchError((e) {
        debugPrint('[StoryMakerVideo] initialize failed: $e');
        if (!mounted) return;
        setState(() => _failed = true);
      });
  }

  @override
  void didUpdateWidget(covariant StoryVideo old) {
    super.didUpdateWidget(old);
    // mute durumu değiştiyse volume’u güncelle
    if (old.isMuted != widget.isMuted) {
      _vidCtrl.setVolume(widget.isMuted ? 0 : 1);
      if (!widget.isMuted && _vidCtrl.value.isInitialized) {
        AudioFocusCoordinator.instance.requestPreviewPlay(_vidCtrl);
      }
    }
  }

  @override
  void dispose() {
    AudioFocusCoordinator.instance.unregisterPreviewPlayer(_vidCtrl);
    _vidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || !_vidCtrl.value.isInitialized) {
      return _buildPoster();
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _vidCtrl.value.size.width,
        height: _vidCtrl.value.size.height,
        child: VideoPlayer(_vidCtrl),
      ),
    );
  }

  Widget _buildPoster() {
    final posterUrl = widget.posterUrl.trim();
    if (posterUrl.isEmpty) return const SizedBox.expand();
    if (_isRemoteUrl(posterUrl)) {
      return CachedNetworkImage(
        imageUrl: posterUrl,
        cacheManager: TurqImageCacheManager.instance,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        errorWidget: (_, __, ___) => const SizedBox.expand(),
      );
    }
    return Image.file(
      File(posterUrl),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.expand(),
    );
  }
}
