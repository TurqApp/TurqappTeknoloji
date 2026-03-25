part of 'clickable_text_content.dart';

class ClickableTextController extends GetxController {
  static const double defaultCaptionFontSize = 13;

  static ClickableTextController ensure({
    required String text,
    void Function(String url)? onUrlTap,
    void Function(String hashtag)? onHashtagTap,
    void Function(String mention)? onMentionTap,
    void Function(String plain)? onPlainTextTap,
    double? fontSize,
    Color? fontColor,
    Color? urlColor,
    Color? mentionColor,
    Color? hashtagColor,
    bool startWith7line = false,
    Color? interactiveColor,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      ClickableTextController(
        text: text,
        onUrlTap: onUrlTap,
        onHashtagTap: onHashtagTap,
        onMentionTap: onMentionTap,
        onPlainTextTap: onPlainTextTap,
        fontSize: fontSize,
        fontColor: fontColor,
        urlColor: urlColor,
        mentionColor: mentionColor,
        hashtagColor: hashtagColor,
        startWith7line: startWith7line,
        interactiveColor: interactiveColor,
      ),
      tag: tag,
      permanent: permanent,
    );
  }

  static ClickableTextController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<ClickableTextController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<ClickableTextController>(tag: tag);
  }

  final String text;
  final void Function(String url)? onUrlTap;
  final void Function(String hashtag)? onHashtagTap;
  final void Function(String mention)? onMentionTap;
  final void Function(String plain)? onPlainTextTap;

  final double? fontSize;
  final Color? fontColor;
  final Color? urlColor;
  final Color? mentionColor;
  final Color? hashtagColor;
  final Color? interactiveColor;
  final bool startWith7line;

  var expanded = false.obs;
  var showExpandButton = false.obs;
  final spans = <TextSpan>[].obs;

  ClickableTextController({
    required this.text,
    this.onUrlTap,
    this.onHashtagTap,
    this.onMentionTap,
    this.onPlainTextTap,
    this.fontSize,
    this.fontColor,
    this.urlColor,
    this.hashtagColor,
    this.mentionColor,
    this.startWith7line = false,
    this.interactiveColor,
  });

  @override
  void onInit() {
    super.onInit();
    _handleClickableTextControllerInit(this);
  }

  @override
  void onClose() {
    _handleClickableTextControllerClose(this);
    super.onClose();
  }
}
