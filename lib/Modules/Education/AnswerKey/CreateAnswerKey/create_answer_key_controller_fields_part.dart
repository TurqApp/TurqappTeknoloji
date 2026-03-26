part of 'create_answer_key_controller.dart';

class _CreateAnswerKeyControllerState {
  _CreateAnswerKeyControllerState({required this.onBack});

  final Function onBack;
  final TextEditingController nameController = TextEditingController();
  final RxList<String> selections = <String>["A"].obs;
  final RxInt selection = 5.obs;
  final Rx<DateTime> selectedDateTime = DateTime.now().obs;
  final RxInt sinavSuresiCount = 30.obs;
  final RxBool showSinavSureleri = false.obs;
  final RxInt mainSelection = 0.obs;
}

extension CreateAnswerKeyControllerFieldsPart on CreateAnswerKeyController {
  Function get onBack => _state.onBack;
  TextEditingController get nameController => _state.nameController;
  RxList<String> get selections => _state.selections;
  RxInt get selection => _state.selection;
  Rx<DateTime> get selectedDateTime => _state.selectedDateTime;
  RxInt get sinavSuresiCount => _state.sinavSuresiCount;
  RxBool get showSinavSureleri => _state.showSinavSureleri;
  RxInt get mainSelection => _state.mainSelection;
}
