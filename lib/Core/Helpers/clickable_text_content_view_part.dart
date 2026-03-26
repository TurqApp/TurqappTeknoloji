part of 'clickable_text_content.dart';

class _ClickableTextContentState extends State<ClickableTextContent> {
  late String _controllerTag;
  late ClickableTextController controller;
  bool _ownsController = false;

  String _colorKey(Color? c) => c?.toARGB32().toRadixString(16) ?? 'n';

  String _buildControllerTag() {
    final signature = 'click_${widget.text.hashCode}_'
        '${_colorKey(widget.fontColor)}_'
        '${_colorKey(widget.urlColor)}_'
        '${_colorKey(widget.mentionColor)}_'
        '${_colorKey(widget.hashtagColor)}_'
        '${_colorKey(widget.interactiveColor)}_'
        '${widget.startWith7line ? '7' : '2'}_'
        '${widget.toggleExpandOnTextTap ? 'tap' : 'btn'}_'
        '${identityHashCode(widget.onUrlTap)}_'
        '${identityHashCode(widget.onHashtagTap)}_'
        '${identityHashCode(widget.onMentionTap)}_'
        '${identityHashCode(widget.onPlainTextTap)}';
    return '${signature}_${identityHashCode(this)}';
  }

  void _bindController() {
    _ownsController =
        maybeFindClickableTextController(tag: _controllerTag) == null;
    controller = ensureClickableTextController(
      text: widget.text,
      onUrlTap: widget.onUrlTap,
      onHashtagTap: widget.onHashtagTap,
      onMentionTap: widget.onMentionTap,
      onPlainTextTap: widget.onPlainTextTap,
      fontSize: widget.fontSize,
      fontColor: widget.fontColor,
      urlColor: widget.urlColor,
      mentionColor: widget.mentionColor,
      hashtagColor: widget.hashtagColor,
      startWith7line: widget.startWith7line,
      interactiveColor: widget.interactiveColor,
      tag: _controllerTag,
    );
  }

  void _disposeOwnedController() {
    if (_ownsController &&
        identical(
          maybeFindClickableTextController(tag: _controllerTag),
          controller,
        )) {
      Get.delete<ClickableTextController>(tag: _controllerTag);
    }
  }

  @override
  void initState() {
    super.initState();
    _controllerTag = _buildControllerTag();
    _bindController();
  }

  @override
  void didUpdateWidget(covariant ClickableTextContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextTag = _buildControllerTag();
    if (nextTag == _controllerTag) return;
    _disposeOwnedController();
    _controllerTag = nextTag;
    _bindController();
  }

  @override
  void dispose() {
    _disposeOwnedController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: widget.fontSize ?? 15,
      color: widget.fontColor ?? Colors.black,
      fontFamily: "Montserrat",
      height: 1.4,
    );
    final expandStyle = TextStyle(
      fontSize: widget.expandButtonFontSize ?? ((widget.fontSize ?? 15) - 1),
      color: widget.expandButtonColor ??
          widget.interactiveColor ??
          widget.urlColor ??
          AppColors.primaryColor,
      fontFamily: "Montserrat",
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (maybeFindClickableTextController(tag: _controllerTag) != null) {
            controller.checkIfExceeds(constraints, baseStyle);
          }
        });

        return Obx(() {
          final collapsed = !controller.expanded.value;
          final maxLines =
              collapsed ? (controller.startWith7line ? 7 : 2) : null;
          final showInlineExpand =
              collapsed && controller.showExpandButton.value;
          final showOverlay = widget.showEllipsisOverlay &&
              collapsed &&
              controller.showExpandButton.value &&
              !showInlineExpand;
          Widget textBody = showOverlay
              ? RichText(
                  key: ValueKey(controller.expanded.value),
                  text: TextSpan(
                    style: baseStyle,
                    children: controller.spans,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                )
              : RichText(
                  key: ValueKey(controller.expanded.value),
                  text: TextSpan(
                    style: baseStyle,
                    children: controller.spans,
                  ),
                  maxLines: maxLines,
                  overflow:
                      collapsed ? TextOverflow.ellipsis : TextOverflow.visible,
                );

          if (showInlineExpand) {
            textBody = Stack(
              children: [
                RichText(
                  key: ValueKey('${controller.expanded.value}_collapsed'),
                  text: TextSpan(
                    style: baseStyle,
                    children: controller.spans,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.clip,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: controller.toggleExpand,
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        'common.show_more'.tr,
                        style: expandStyle,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          if (widget.toggleExpandOnTextTap &&
              controller.showExpandButton.value) {
            textBody = GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: controller.toggleExpand,
              child: textBody,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textBody,
              if (controller.showExpandButton.value && !collapsed)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: controller.toggleExpand,
                  child: Text(
                    controller.expanded.value
                        ? 'common.show_less'.tr
                        : 'common.show_more'.tr,
                    style: expandStyle,
                  ),
                ),
            ],
          );
        });
      },
    );
  }
}
