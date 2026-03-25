part of 'hashtag_text_post.dart';

class HashtagTextVideoPostControllerRuntimePart {
  const HashtagTextVideoPostControllerRuntimePart(this.controller);

  final HashtagTextVideoPostController controller;

  void onInit() {
    controller._buildSpans();
  }

  void onClose() {
    for (final span in controller.spans) {
      span.recognizer?.dispose();
    }
  }

  void buildSpans() {
    for (final span in controller.spans) {
      span.recognizer?.dispose();
    }
    final List<TextSpan> result = [];
    final hashtagRegex = RegExp(r'\B#([\wğüşöçıİĞÜŞÖÇ]+)', unicode: true);
    final urlRegex = RegExp(r'((http|https):\/\/|www\.)\S+');
    final mentionRegex = RegExp(r'@[\w.]+', unicode: true);

    final nickname = controller.nickname;
    if (nickname != null && nickname.isNotEmpty) {
      result.add(
        TextSpan(
          text: '$nickname ',
          style: TextStyle(
            color:
                controller.color == Colors.black ? Colors.black : Colors.indigo,
            fontSize: 13,
            fontFamily: AppFontFamilies.mbold,
          ),
        ),
      );
    }

    int lastEnd = 0;
    final combined = RegExp(
      '${hashtagRegex.pattern}|${urlRegex.pattern}|${mentionRegex.pattern}',
      unicode: true,
      caseSensitive: false,
    );

    for (final m in combined.allMatches(controller.text)) {
      if (m.start > lastEnd) {
        result.add(
          TextSpan(
            text: controller.text.substring(lastEnd, m.start),
            style: TextStyle(
              color: controller.color,
              height: 1.5,
              fontSize: 13,
              fontFamily: AppFontFamilies.mregular,
            ),
          ),
        );
      }

      final match = m.group(0)!;
      if (hashtagRegex.hasMatch(match)) {
        result.add(
          TextSpan(
            text: match,
            style: interactiveStyle(),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                controller.volume(false);
                Get.to(() => TagPosts(tag: match))
                    ?.then((_) => controller.volume(true));
              },
          ),
        );
      } else if (urlRegex.hasMatch(match)) {
        result.add(
          TextSpan(
            text: match,
            style: interactiveStyle(),
            recognizer: TapGestureRecognizer()..onTap = () {},
          ),
        );
      } else if (mentionRegex.hasMatch(match)) {
        result.add(
          TextSpan(
            text: match,
            style: interactiveStyle(),
            recognizer: TapGestureRecognizer()..onTap = () {},
          ),
        );
      }

      lastEnd = m.end;
    }

    if (lastEnd < controller.text.length) {
      result.add(
        TextSpan(
          text: controller.text.substring(lastEnd),
          style: TextStyle(
            color: controller.color,
            height: 1.5,
            fontSize: 13,
            fontFamily: AppFontFamilies.mregular,
          ),
        ),
      );
    }

    controller.spans.assignAll(result);
  }

  TextStyle interactiveStyle() => TextStyle(
        color: controller.interactiveColor,
        height: 1.5,
        fontSize: 13,
        fontFamily: AppFontFamilies.mregular,
      );
}
