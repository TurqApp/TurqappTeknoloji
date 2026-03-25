part of 'hashtag_text_post.dart';

class HashtagTextVideoPostController extends GetxController {
  static HashtagTextVideoPostController ensure({
    required String text,
    String? nickname,
    required Color color,
    required void Function(bool) volume,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      HashtagTextVideoPostController(
        text: text,
        nickname: nickname,
        color: color,
        volume: volume,
      ),
      tag: tag,
      permanent: permanent,
    );
  }

  static HashtagTextVideoPostController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<HashtagTextVideoPostController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<HashtagTextVideoPostController>(tag: tag);
  }

  final String text;
  final String? nickname;
  final Color color;
  final void Function(bool) volume;

  HashtagTextVideoPostController({
    required this.text,
    this.nickname,
    required this.color,
    required this.volume,
  });

  final expanded = false.obs;
  final showExpandButton = false.obs;
  final spans = <TextSpan>[].obs;

  Color get interactiveColor => Colors.blueAccent;

  @override
  void onInit() {
    super.onInit();
    _buildSpans();
  }

  @override
  void onClose() {
    for (final span in spans) {
      span.recognizer?.dispose();
    }
    super.onClose();
  }

  void _buildSpans() {
    for (final span in spans) {
      span.recognizer?.dispose();
    }
    final List<TextSpan> result = [];
    final hashtagRegex = RegExp(r'\B#([\wğüşöçıİĞÜŞÖÇ]+)', unicode: true);
    final urlRegex = RegExp(r'((http|https):\/\/|www\.)\S+');
    final mentionRegex = RegExp(r'@[\w.]+', unicode: true);

    if (nickname != null && nickname!.isNotEmpty) {
      result.add(TextSpan(
        text: '$nickname ',
        style: TextStyle(
          color: color == Colors.black ? Colors.black : Colors.indigo,
          fontSize: 13,
          fontFamily: AppFontFamilies.mbold,
        ),
      ));
    }

    int lastEnd = 0;
    final combined = RegExp(
      '${hashtagRegex.pattern}|${urlRegex.pattern}|${mentionRegex.pattern}',
      unicode: true,
      caseSensitive: false,
    );

    for (final m in combined.allMatches(text)) {
      if (m.start > lastEnd) {
        result.add(TextSpan(
          text: text.substring(lastEnd, m.start),
          style: TextStyle(
            color: color,
            height: 1.5,
            fontSize: 13,
            fontFamily: AppFontFamilies.mregular,
          ),
        ));
      }

      final match = m.group(0)!;
      if (hashtagRegex.hasMatch(match)) {
        result.add(TextSpan(
          text: match,
          style: _interactiveStyle(),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              volume(false);
              Get.to(() => TagPosts(tag: match))?.then((_) => volume(true));
            },
        ));
      } else if (urlRegex.hasMatch(match)) {
        result.add(TextSpan(
          text: match,
          style: _interactiveStyle(),
          recognizer: TapGestureRecognizer()..onTap = () {},
        ));
      } else if (mentionRegex.hasMatch(match)) {
        result.add(TextSpan(
          text: match,
          style: _interactiveStyle(),
          recognizer: TapGestureRecognizer()..onTap = () {},
        ));
      }

      lastEnd = m.end;
    }

    if (lastEnd < text.length) {
      result.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(
          color: color,
          height: 1.5,
          fontSize: 13,
          fontFamily: AppFontFamilies.mregular,
        ),
      ));
    }

    spans.assignAll(result);
  }

  TextStyle _interactiveStyle() => TextStyle(
        color: interactiveColor,
        height: 1.5,
        fontSize: 13,
        fontFamily: AppFontFamilies.mregular,
      );

  void toggleExpand() {
    expanded.toggle();
    _buildSpans();
  }

  void checkOverflow(TextPainter tp) {
    showExpandButton.value = tp.didExceedMaxLines;
  }
}
