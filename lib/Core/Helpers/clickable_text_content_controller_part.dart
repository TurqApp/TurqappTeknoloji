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
  }) =>
      _ensureClickableTextController(
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
        tag: tag,
        permanent: permanent,
      );

  static ClickableTextController? maybeFind({String? tag}) =>
      _maybeFindClickableTextController(tag: tag);

  static List<TextSpan> buildSpans({
    required String text,
    required TextStyle plainStyle,
    required TextStyle urlStyle,
    required TextStyle hashtagStyle,
    required TextStyle mentionStyle,
    void Function(String url)? onUrlTap,
    void Function(String hashtag)? onHashtagTap,
    void Function(String mention)? onMentionTap,
    void Function(String plain)? onPlainTextTap,
  }) =>
      _buildClickableTextControllerSpans(
        text: text,
        plainStyle: plainStyle,
        urlStyle: urlStyle,
        hashtagStyle: hashtagStyle,
        mentionStyle: mentionStyle,
        onUrlTap: onUrlTap,
        onHashtagTap: onHashtagTap,
        onMentionTap: onMentionTap,
        onPlainTextTap: onPlainTextTap,
      );

  final _ClickableTextControllerState _state;

  ClickableTextController._(_ClickableTextControllerConfig config)
      : _state = _ClickableTextControllerState(config);

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
