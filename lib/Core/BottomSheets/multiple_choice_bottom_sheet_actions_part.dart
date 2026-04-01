part of 'multiple_choice_bottom_sheet.dart';

extension MultipleChoiceBottomSheetActionsPart on MultipleChoiceBottomSheet {
  void _initializeSelectionState() {
    if (_resolvedSelectionType == 'months') {
      controller.selectedItems.assignAll(controller.aylar);
    } else if (_resolvedSelectionType == 'conditions') {
      controller.selectedItems.assignAll(
        controller.basvuruKosullari.value
            .split('\n')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty),
      );
    } else if (_resolvedSelectionType == 'documents') {
      controller.selectedItems.assignAll(controller.belgeler);
    }
  }

  void _toggleItemSelection(String item) {
    if (controller.selectedItems.contains(item)) {
      controller.selectedItems.remove(item);
    } else {
      controller.selectedItems.add(item);
    }
  }

  void _confirmSelection(BuildContext context) {
    final newItems = controller.selectedItems.join('\n');
    if (_resolvedSelectionType == 'conditions') {
      final currentText = controller.basvuruKosullari.value;
      if (currentText.isNotEmpty && newItems.isNotEmpty) {
        controller.basvuruKosullari.value = '$currentText\n$newItems';
      } else if (newItems.isNotEmpty) {
        controller.basvuruKosullari.value = newItems;
      }
      controller.basvuruKosullariController.text =
          controller.localizedConditionsText(
        controller.basvuruKosullari.value,
      );
    } else if (_resolvedSelectionType == 'documents') {
      controller.belgeler.assignAll(controller.selectedItems);
      controller.belgelerController.text = controller.localizedDocumentsText(
        controller.selectedItems,
      );
    } else if (_resolvedSelectionType == 'months') {
      controller.aylar.assignAll(controller.selectedItems);
      controller.aylarController.text = controller.selectedItems.join('\n');
    }
    Navigator.pop(context);
  }
}
