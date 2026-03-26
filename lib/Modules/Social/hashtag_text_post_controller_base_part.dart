part of 'hashtag_text_post.dart';

abstract class _HashtagTextVideoPostControllerBase extends GetxController {
  _HashtagTextVideoPostControllerBase({
    required String text,
    String? nickname,
    required Color color,
    required void Function(bool) volume,
  }) : _state = _HashtagTextVideoPostControllerState(
          text: text,
          nickname: nickname,
          color: color,
          volume: volume,
        );

  final _HashtagTextVideoPostControllerState _state;

  @override
  void onInit() {
    super.onInit();
    HashtagTextVideoPostControllerRuntimePart(
            this as HashtagTextVideoPostController)
        .onInit();
  }

  @override
  void onClose() {
    HashtagTextVideoPostControllerRuntimePart(
            this as HashtagTextVideoPostController)
        .onClose();
    super.onClose();
  }
}
