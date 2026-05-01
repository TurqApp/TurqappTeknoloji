import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Models/posts_model.dart';
import '../Controllers/post_controller.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Post etkileşim butonları widget'ı
class PostInteractionWidget extends StatefulWidget {
  final PostsModel post;
  final bool showCommentButton;
  final bool showSaveButton;
  final bool showReshareButton;
  final Function(String)? onCommentTap;

  const PostInteractionWidget({
    super.key,
    required this.post,
    this.showCommentButton = true,
    this.showSaveButton = true,
    this.showReshareButton = true,
    this.onCommentTap,
  });

  @override
  State<PostInteractionWidget> createState() => _PostInteractionWidgetState();
}

class _PostInteractionWidgetState extends State<PostInteractionWidget> {
  late final String _controllerTag;
  late final PostController _controller;
  bool _ownsController = false;
  Future<bool>? _likeFuture;
  Future<bool>? _reshareFuture;
  Future<bool>? _saveFuture;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'post_interaction_${widget.post.docID}_${identityHashCode(this)}';
    _ownsController = maybeFindPostController(tag: _controllerTag) == null;
    _controller = ensurePostController(tag: _controllerTag);
  }

  void _refreshStatusFutures(PostController controller) {
    _likeFuture = controller.checkLikeStatus(widget.post.docID);
    _reshareFuture = controller.checkReshareStatus(widget.post.docID);
    _saveFuture = controller.checkSaveStatus(widget.post.docID);
  }

  @override
  void didUpdateWidget(covariant PostInteractionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.docID != widget.post.docID) {
      _refreshStatusFutures(_controller);
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindPostController(tag: _controllerTag),
          _controller,
        )) {
      Get.delete<PostController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PostController>(
      tag: _controllerTag,
      id: 'post_${widget.post.docID}',
      builder: (controller) {
        _likeFuture ??= controller.checkLikeStatus(widget.post.docID);
        _reshareFuture ??= controller.checkReshareStatus(widget.post.docID);
        _saveFuture ??= controller.checkSaveStatus(widget.post.docID);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // Beğeni butonu
              _buildLikeButton(controller),
              const SizedBox(width: 16),

              // Yorum butonu
              if (widget.showCommentButton) ...[
                _buildCommentButton(controller),
                const SizedBox(width: 16),
              ],

              // Yeniden paylaşma butonu
              if (widget.showReshareButton) ...[
                _buildReshareButton(controller),
                const SizedBox(width: 16),
              ],

              const Spacer(),

              // Kaydetme butonu
              if (widget.showSaveButton) _buildSaveButton(controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLikeButton(PostController controller) {
    return GestureDetector(
      onTap: () async {
        await controller.handleLike(widget.post.docID, widget.post);
        _likeFuture = controller.checkLikeStatus(widget.post.docID);
        if (mounted) setState(() {});
      },
      child: FutureBuilder<bool>(
        future: _likeFuture,
        builder: (context, snapshot) {
          final isLiked = snapshot.data ?? false;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(width: 4),
              Text(
                _formatCount(widget.post.stats.likeCount),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommentButton(PostController controller) {
    return GestureDetector(
      onTap: () => widget.onCommentTap?.call(widget.post.docID),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            color: Colors.grey[600],
            size: 24,
          ),
          const SizedBox(width: 4),
          Text(
            _formatCount(widget.post.stats.commentCount),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReshareButton(PostController controller) {
    return GestureDetector(
      onTap: () async {
        await controller.handleReshare(widget.post.docID, widget.post);
        _reshareFuture = controller.checkReshareStatus(widget.post.docID);
        if (mounted) setState(() {});
      },
      child: FutureBuilder<bool>(
        future: _reshareFuture,
        builder: (context, snapshot) {
          final isReshared = snapshot.data ?? false;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.repeat,
                color: isReshared ? Colors.green : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(width: 4),
              Text(
                _formatCount(widget.post.stats.retryCount),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSaveButton(PostController controller) {
    return GestureDetector(
      onTap: () async {
        await controller.handleSave(widget.post.docID, widget.post);
        _saveFuture = controller.checkSaveStatus(widget.post.docID);
        if (mounted) setState(() {});
      },
      child: FutureBuilder<bool>(
        future: _saveFuture,
        builder: (context, snapshot) {
          final isSaved = snapshot.data ?? false;

          return Icon(
            isSaved ? Icons.bookmark : Icons.bookmark_border,
            color: isSaved ? Colors.blue : Colors.grey[600],
            size: 24,
          );
        },
      ),
    );
  }

  String _formatCount(num count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}

/// Post görüntüleme tracking widget'ı
class PostViewTracker extends StatefulWidget {
  final PostsModel post;
  final Widget child;
  final double visibilityThreshold;

  const PostViewTracker({
    super.key,
    required this.post,
    required this.child,
    this.visibilityThreshold = 0.01,
  });

  @override
  State<PostViewTracker> createState() => _PostViewTrackerState();
}

class _PostViewTrackerState extends State<PostViewTracker> {
  late final String _controllerTag;
  late PostController _controller;
  bool _ownsController = false;
  bool _hasRecordedView = false;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'post_view_${widget.post.docID}_${identityHashCode(this)}';
    _ownsController = maybeFindPostController(tag: _controllerTag) == null;
    _controller = ensurePostController(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindPostController(tag: _controllerTag),
          _controller,
        )) {
      Get.delete<PostController>(tag: _controllerTag);
    }
    super.dispose();
  }

  void _recordView(double visibleFraction) {
    if (!_hasRecordedView) {
      _hasRecordedView = true;
      final hasImage = widget.post.img.any((entry) => entry.trim().isNotEmpty);
      final hasText = widget.post.metin.trim().isNotEmpty;
      final contentKind = widget.post.hasPlayableVideo
          ? 'video'
          : (hasImage ? 'image' : (hasText ? 'text' : 'unknown'));
      debugPrint(
        '[PostViewTracker] status=triggered doc=${widget.post.docID} '
        'kind=$contentKind threshold=${widget.visibilityThreshold} '
        'visibleFraction=${visibleFraction.toStringAsFixed(3)}',
      );
      _controller.recordView(widget.post.docID, widget.post);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('post_view_${widget.post.docID}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction >= widget.visibilityThreshold) {
          _recordView(info.visibleFraction);
        }
      },
      child: widget.child,
    );
  }
}

// VisibilityDetector import'u için
