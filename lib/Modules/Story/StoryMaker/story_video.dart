import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class StoryVideo extends StatefulWidget {
  final String path;
  final bool isMuted;

  const StoryVideo({
    super.key,
    required this.path,
    this.isMuted = false,
  });

  @override
  _StoryVideoState createState() => _StoryVideoState();
}

class _StoryVideoState extends State<StoryVideo> {
  late VideoPlayerController _vidCtrl;

  bool get _isRemotePath {
    final uri = Uri.tryParse(widget.path.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.hasAuthority;
  }

  @override
  void initState() {
    super.initState();
    _vidCtrl = _isRemotePath
        ? VideoPlayerController.networkUrl(Uri.parse(widget.path))
        : VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        _vidCtrl.setLooping(true);
        _vidCtrl.setVolume(widget.isMuted ? 0 : 1);
        _vidCtrl.play();
        setState(() {});
      });
  }

  @override
  void didUpdateWidget(covariant StoryVideo old) {
    super.didUpdateWidget(old);
    // mute durumu değiştiyse volume’u güncelle
    if (old.isMuted != widget.isMuted) {
      _vidCtrl.setVolume(widget.isMuted ? 0 : 1);
    }
  }

  @override
  void dispose() {
    _vidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_vidCtrl.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
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
}
