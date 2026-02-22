import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Models/PostsModel.dart';
import '../Controllers/PostController.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Post etkileşim butonları widget'ı
class PostInteractionWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GetBuilder<PostController>(
      id: 'post_${post.docID}',
      init: PostController(),
      builder: (controller) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // Beğeni butonu
              _buildLikeButton(controller),
              const SizedBox(width: 16),

              // Yorum butonu
              if (showCommentButton) ...[
                _buildCommentButton(controller),
                const SizedBox(width: 16),
              ],

              // Yeniden paylaşma butonu
              if (showReshareButton) ...[
                _buildReshareButton(controller),
                const SizedBox(width: 16),
              ],

              const Spacer(),

              // Kaydetme butonu
              if (showSaveButton) _buildSaveButton(controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLikeButton(PostController controller) {
    return GestureDetector(
      onTap: () => controller.handleLike(post.docID, post),
      child: FutureBuilder<bool>(
        future: controller.checkLikeStatus(post.docID),
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
                _formatCount(post.stats.likeCount),
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
      onTap: () => onCommentTap?.call(post.docID),
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
            _formatCount(post.stats.commentCount),
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
      onTap: () => controller.handleReshare(post.docID, post),
      child: FutureBuilder<bool>(
        future: controller.checkReshareStatus(post.docID),
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
                _formatCount(post.stats.retryCount),
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
      onTap: () => controller.handleSave(post.docID, post),
      child: FutureBuilder<bool>(
        future: controller.checkSaveStatus(post.docID),
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
    this.visibilityThreshold = 0.5,
  });

  @override
  State<PostViewTracker> createState() => _PostViewTrackerState();
}

class _PostViewTrackerState extends State<PostViewTracker> {
  late PostController _controller;
  bool _hasRecordedView = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(PostController());
  }

  void _recordView() {
    if (!_hasRecordedView) {
      _hasRecordedView = true;
      _controller.recordView(widget.post.docID, widget.post);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('post_view_${widget.post.docID}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction >= widget.visibilityThreshold) {
          _recordView();
        }
      },
      child: widget.child,
    );
  }
}

// VisibilityDetector import'u için
