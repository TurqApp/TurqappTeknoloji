part of 'create_book_controller.dart';

class _CreateBookControllerState {
  final baslikController = TextEditingController();
  final yayinEviController = TextEditingController();
  final basimTarihiController = TextEditingController();
  final list = <CevapAnahtariHazirlikModel>[].obs;
  final selection = 0.obs;
  final sinavTuru = ''.obs;
  final imageFile = Rxn<File>();
  final showIndicator = false.obs;
  final picker = ImagePicker();
}

extension CreateBookControllerFieldsPart on CreateBookController {
  TextEditingController get baslikController => _state.baslikController;
  TextEditingController get yayinEviController => _state.yayinEviController;
  TextEditingController get basimTarihiController =>
      _state.basimTarihiController;
  RxList<CevapAnahtariHazirlikModel> get list => _state.list;
  RxInt get selection => _state.selection;
  RxString get sinavTuru => _state.sinavTuru;
  Rxn<File> get imageFile => _state.imageFile;
  RxBool get showIndicator => _state.showIndicator;
  ImagePicker get picker => _state.picker;
}
