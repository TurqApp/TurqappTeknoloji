part of 'my_past_test_results_preview_controller.dart';

extension MyPastTestResultsPreviewControllerUiPart
    on MyPastTestResultsPreviewController {
  Color determineChoiceColor(int index, String choice) {
    if (choice == soruList[index].dogruCevap && yanitlar[index] == '') {
      return Colors.white;
    } else if (choice == soruList[index].dogruCevap) {
      return Colors.green;
    } else if (choice == yanitlar[index]) {
      return Colors.red;
    } else {
      return Colors.white;
    }
  }

  Color determineChoiceTextColor(int index, String choice) {
    if (choice == soruList[index].dogruCevap && yanitlar[index] == '') {
      return Colors.black;
    } else if (choice == soruList[index].dogruCevap) {
      return Colors.white;
    } else if (choice == yanitlar[index]) {
      return Colors.white;
    } else {
      return Colors.black;
    }
  }
}
