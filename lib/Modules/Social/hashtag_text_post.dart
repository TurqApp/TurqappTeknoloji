import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Agenda/TagPosts/tag_posts.dart';
import '../../Themes/app_fonts.dart';

part 'hashtag_text_post_controller_part.dart';
part 'hashtag_text_post_controller_lookup_part.dart';
part 'hashtag_text_post_controller_base_part.dart';
part 'hashtag_text_post_controller_class_part.dart';
part 'hashtag_text_post_controller_facade_part.dart';
part 'hashtag_text_post_controller_fields_part.dart';
part 'hashtag_text_post_controller_runtime_part.dart';
part 'hashtag_text_post_controller_support_part.dart';

class HashtagTextVideoPost extends StatelessWidget {
  final String text;
  final String? nickname;
  final Color color;
  final void Function(bool) volume;

  const HashtagTextVideoPost({
    super.key,
    required this.text,
    required this.volume,
    this.nickname,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Include color/nickname in tag to avoid reusing a controller with stale styles
    String colorKey(Color c) => c.toARGB32().toRadixString(16);
    final tag =
        'htvp_${text.hashCode}_${colorKey(color)}_${nickname?.hashCode ?? 0}';
    final ctrl = ensureHashtagTextVideoPostController(
      text: text,
      nickname: nickname,
      color: color,
      volume: volume,
      tag: tag,
    );

    final baseStyle = TextStyle(
      color: color,
      height: 1.5,
      fontSize: 13,
      fontFamily: AppFontFamilies.mregular,
    );

    return LayoutBuilder(builder: (ctx, constraints) {
      final tp = TextPainter(
        text: TextSpan(style: baseStyle, children: ctrl.spans),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: constraints.maxWidth);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (maybeFindHashtagTextVideoPostController(tag: tag) != null) {
          ctrl.checkOverflow(tp);
        }
      });

      return Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                key: ValueKey(ctrl.expanded.value),
                text: TextSpan(style: baseStyle, children: ctrl.spans),
                maxLines: ctrl.expanded.value ? null : 1,
                overflow: ctrl.expanded.value
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
              if (ctrl.showExpandButton.value)
                GestureDetector(
                  onTap: ctrl.toggleExpand,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      ctrl.expanded.value
                          ? 'common.hide'.tr
                          : 'common.show_more'.tr,
                      style: baseStyle.copyWith(
                        color: ctrl.interactiveColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ));
    });
  }
}
