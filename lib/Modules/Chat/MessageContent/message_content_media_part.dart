part of 'message_content.dart';

class _FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool enableReplyBar;
  final Future<void> Function(String text, String mediaUrl)? onSendReply;
  final String replyPreviewLabel;

  const _FullScreenVideoPlayer({
    required this.videoUrl,
    this.enableReplyBar = false,
    this.onSendReply,
    this.replyPreviewLabel = "",
  });

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocus = FocusNode();
  bool _replyOpen = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() => _initialized = true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final onSend = widget.onSendReply;
    if (onSend == null || _sending) return;
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await onSend(text, widget.videoUrl);
      _replyController.clear();
      _replyFocus.unfocus();
      if (mounted) {
        setState(() => _replyOpen = false);
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Widget _buildCollapsedReplyButton() {
    return GestureDetector(
      onTap: () {
        setState(() => _replyOpen = true);
        Future.delayed(
          const Duration(milliseconds: 70),
          () => _replyFocus.requestFocus(),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.reply_thick_solid,
              color: Colors.black,
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              'chat.reply_prompt'.tr,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontFamily: "Montserrat",
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Center(
            child: _initialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                        });
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(_controller),
                          if (!_controller.value.isPlaying)
                            const Icon(
                              CupertinoIcons.play_fill,
                              color: Colors.white,
                              size: 50,
                            ),
                        ],
                      ),
                    ),
                  )
                : const CupertinoActivityIndicator(color: Colors.white),
          ),
          if (widget.enableReplyBar)
            if (_replyOpen)
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF18A999),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'chat.you'.tr,
                              style: const TextStyle(
                                color: Color(0xFF18A999),
                                fontSize: 14,
                                fontFamily: "Montserrat",
                              ),
                            ),
                          ),
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              CupertinoIcons.videocam_fill,
                              color: Colors.black54,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 11, top: 2),
                        child: Row(
                          children: [
                            Text(
                              widget.replyPreviewLabel.isEmpty
                                  ? 'chat.video'.tr
                                  : widget.replyPreviewLabel,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                                fontFamily: "Montserrat",
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              focusNode: _replyFocus,
                              controller: _replyController,
                              textCapitalization: TextCapitalization.sentences,
                              minLines: 1,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'chat.message_hint'.tr,
                                isDense: true,
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          if (_sending)
                            const CupertinoActivityIndicator(
                              color: Colors.black,
                            )
                          else
                            IconButton(
                              onPressed: _sendReply,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 34,
                                minHeight: 34,
                              ),
                              icon: const Icon(
                                CupertinoIcons.paperplane_fill,
                                color: Colors.black,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              Positioned(
                right: 12,
                bottom: 18,
                child: _buildCollapsedReplyButton(),
              ),
        ],
      ),
    );
  }
}

class _AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final int durationMs;
  final bool isMine;

  const _AudioPlayerWidget({
    required this.audioUrl,
    required this.durationMs,
    required this.isMine,
  });

  @override
  State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    AudioFocusCoordinator.instance.registerAudioPlayer(_player);
    if (widget.durationMs > 0) {
      _duration = Duration(milliseconds: widget.durationMs);
    }
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
  }

  @override
  void dispose() {
    AudioFocusCoordinator.instance.unregisterAudioPlayer(_player);
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final bubbleWidth =
        (MediaQuery.of(context).size.width * 0.58).clamp(180.0, 220.0);
    return Container(
      width: bubbleWidth,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isMine ? Colors.blueAccent : const Color(0xFFF2F2F4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              if (_isPlaying) {
                await _player.pause();
              } else {
                await AudioFocusCoordinator.instance.requestAudioPlayerPlay(
                  _player,
                );
                await _player.play(UrlSource(widget.audioUrl));
              }
            },
            child: Icon(
              _isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
              color: widget.isMine ? Colors.white : Colors.black,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: _duration.inMilliseconds > 0
                      ? _position.inMilliseconds / _duration.inMilliseconds
                      : 0,
                  backgroundColor: widget.isMine
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation(
                    widget.isMine ? Colors.white : Colors.blueAccent,
                  ),
                  minHeight: 3,
                ),
                const SizedBox(height: 4),
                Text(
                  _isPlaying || _position.inMilliseconds > 0
                      ? _formatDuration(_position)
                      : _formatDuration(_duration),
                  style: TextStyle(
                    color: widget.isMine ? Colors.white70 : Colors.black54,
                    fontSize: 10,
                    fontFamily: "Montserrat",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
