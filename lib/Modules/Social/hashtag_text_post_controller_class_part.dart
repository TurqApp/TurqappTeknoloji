part of 'hashtag_text_post.dart';

class HashtagTextVideoPostController extends GetxController {
  final _HashtagTextVideoPostControllerState _state;

  HashtagTextVideoPostController({
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
}
