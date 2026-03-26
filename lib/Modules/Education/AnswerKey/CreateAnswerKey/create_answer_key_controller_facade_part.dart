part of 'create_answer_key_controller.dart';

extension CreateAnswerKeyControllerFacadePart on CreateAnswerKeyController {
  Future<void> selectDateTime(BuildContext context) =>
      _selectCreateAnswerKeyDateTime(this, context);

  void toggleSinavSureleri() {
    showSinavSureleri.value = !showSinavSureleri.value;
  }

  void selectSinavSuresi(int duration) =>
      _selectCreateAnswerKeyDuration(this, duration);

  void setSelection(int value) {
    selection.value = value;
  }

  void addSelection() {
    selections.add("");
  }

  void removeSelection(int index) =>
      _removeCreateAnswerKeySelection(this, index);

  void updateSelection(int index, String value) {
    selections[index] = value;
  }

  Future<void> saveForm(BuildContext context) => _saveCreateAnswerKeyForm(this);
}
