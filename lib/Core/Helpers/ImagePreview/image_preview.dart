import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ImagePreview extends StatefulWidget {
  final List<String> imgs;
  final int startIndex;
  final bool enableReplyBar;
  final Future<void> Function(String text, String mediaUrl)? onSendReply;
  final String replyPreviewLabel;

  const ImagePreview({
    super.key,
    required this.imgs,
    required this.startIndex,
    this.enableReplyBar = false,
    this.onSendReply,
    this.replyPreviewLabel = "",
  });

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  late final PageController _pageController;
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocus = FocusNode();
  bool _replyOpen = false;
  bool _sending = false;
  int _currentIndex = 0;
  double _dragStartY = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    _pageController = PageController(initialPage: widget.startIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _replyController.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final onSend = widget.onSendReply;
    if (onSend == null || _sending) return;
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    final mediaUrl = widget.imgs[_currentIndex];
    setState(() => _sending = true);
    try {
      await onSend(text, mediaUrl);
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
                fontFamily: "MontserratMedium",
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
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragStart: (details) {
            _dragStartY = details.localPosition.dy;
          },
          onVerticalDragUpdate: (details) {
            final dragDistance = details.localPosition.dy - _dragStartY;
            if (dragDistance > 100) {
              Get.back();
            }
          },
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: widget.imgs.length,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                      },
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: widget.imgs[index],
                          fit: BoxFit.contain,
                        );
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: Get.back,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Icon(
                      CupertinoIcons.arrow_left,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
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
                                  style: TextStyle(
                                    color: Color(0xFF18A999),
                                    fontSize: 14,
                                    fontFamily: "MontserratSemiBold",
                                  ),
                                ),
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CachedNetworkImage(
                                    imageUrl: widget.imgs[_currentIndex],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 11, top: 2),
                            child: Row(
                              children: [
                                Text(
                                  widget.replyPreviewLabel,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                    fontFamily: "MontserratMedium",
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
                                  textCapitalization:
                                      TextCapitalization.sentences,
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
                                      minWidth: 34, minHeight: 34),
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
        ),
      ),
    );
  }
}
