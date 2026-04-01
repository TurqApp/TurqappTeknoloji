part of 'hashtag_text_post.dart';

class _HashtagTextVideoPostControllerState {
  _HashtagTextVideoPostControllerState({
    required this.text,
    required this.nickname,
    required this.color,
    required this.volume,
  });

  final String text;
  final String? nickname;
  final Color color;
  final void Function(bool) volume;
  final RxBool expanded = false.obs;
  final RxBool showExpandButton = false.obs;
  final RxList<TextSpan> spans = <TextSpan>[].obs;
}

extension HashtagTextVideoPostControllerFieldsPart
    on HashtagTextVideoPostController {
  String get text => _state.text;
  String? get nickname => _state.nickname;
  Color get color => _state.color;
  void Function(bool) get volume => _state.volume;
  RxBool get expanded => _state.expanded;
  RxBool get showExpandButton => _state.showExpandButton;
  RxList<TextSpan> get spans => _state.spans;
  Color get interactiveColor => Colors.blueAccent;
}
