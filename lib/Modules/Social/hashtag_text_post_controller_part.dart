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
    HashtagTextVideoPostControllerRuntimePart(this).onInit();
  }

  @override
  void onClose() {
    HashtagTextVideoPostControllerRuntimePart(this).onClose();
    super.onClose();
  }

  void _buildSpans() =>
      HashtagTextVideoPostControllerRuntimePart(this).buildSpans();

  void toggleExpand() {
    expanded.toggle();
    _buildSpans();
  }

  void checkOverflow(TextPainter tp) {
    showExpandButton.value = tp.didExceedMaxLines;
  }
}
