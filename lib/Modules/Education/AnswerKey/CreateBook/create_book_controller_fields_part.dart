part of 'create_book_controller.dart';

class _CreateBookControllerState {
  _CreateBookControllerState({
    required this.onBack,
    required this.existingBook,
  }) : docID = existingBook?.docID ??
            DateTime.now().millisecondsSinceEpoch.toString();

  final Function? onBack;
  final BookletModel? existingBook;
  final String docID;
  final BookletRepository bookletRepository = BookletRepository.ensure();
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
  Function? get onBack => _state.onBack;
  BookletModel? get existingBook => _state.existingBook;
  String get docID => _state.docID;
  BookletRepository get _bookletRepository => _state.bookletRepository;
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
