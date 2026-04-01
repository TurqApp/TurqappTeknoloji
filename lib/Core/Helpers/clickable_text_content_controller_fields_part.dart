part of 'clickable_text_content.dart';

class _ClickableTextControllerState {
  _ClickableTextControllerState(this.config);

  final _ClickableTextControllerConfig config;
  final RxBool expanded = false.obs;
  final RxBool showExpandButton = false.obs;
  final RxList<TextSpan> spans = <TextSpan>[].obs;
}

extension ClickableTextControllerFieldsPart on ClickableTextController {
  _ClickableTextControllerConfig get _config => _state.config;
  RxBool get expanded => _state.expanded;
  RxBool get showExpandButton => _state.showExpandButton;
  RxList<TextSpan> get spans => _state.spans;
}
