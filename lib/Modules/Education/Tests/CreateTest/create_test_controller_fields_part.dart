part of 'create_test_controller.dart';

class _CreateTestControllerState {
  final TextEditingController aciklama = TextEditingController();
  final RxList<String> selectedDers = <String>[].obs;
  final RxBool showBransh = false.obs;
  final RxBool showDiller = false.obs;
  final RxString selectedDil = ''.obs;
  final RxString testTuru = 'Lise'.obs;
  final RxBool paylasilabilir = true.obs;
  final RxBool check = false.obs;
  final Rx<File?> imageFile = Rx<File?>(null);
  final RxString foundImage = ''.obs;
  final ImagePicker picker = ImagePicker();
  final RxString appStore = ''.obs;
  final RxString googlePlay = ''.obs;
  final RxInt testID = DateTime.now().millisecondsSinceEpoch.obs;
  final RxBool showSilButon = false.obs;
  final RxBool kopyalandi = false.obs;
  final RxList<TestReadinessModel> sorularList = <TestReadinessModel>[
    TestReadinessModel(id: 0, img: "", max: 5, dogruCevap: "", docID: "0"),
  ].obs;
  final RxBool isLoading = true.obs;
}

extension CreateTestControllerFieldsPart on CreateTestController {
  TextEditingController get aciklama => _state.aciklama;
  RxList<String> get selectedDers => _state.selectedDers;
  RxBool get showBransh => _state.showBransh;
  RxBool get showDiller => _state.showDiller;
  RxString get selectedDil => _state.selectedDil;
  RxString get testTuru => _state.testTuru;
  RxBool get paylasilabilir => _state.paylasilabilir;
  RxBool get check => _state.check;
  Rx<File?> get imageFile => _state.imageFile;
  RxString get foundImage => _state.foundImage;
  ImagePicker get picker => _state.picker;
  RxString get appStore => _state.appStore;
  RxString get googlePlay => _state.googlePlay;
  RxInt get testID => _state.testID;
  RxBool get showSilButon => _state.showSilButon;
  RxBool get kopyalandi => _state.kopyalandi;
  RxList<TestReadinessModel> get sorularList => _state.sorularList;
  RxBool get isLoading => _state.isLoading;
}
