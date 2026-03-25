part of 'create_tutoring_controller.dart';

class _CreateTutoringControllerState {
  final carouselCurrentIndex = 0.obs;
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final branchController = TextEditingController();
  final priceController = TextEditingController();
  final cityController = TextEditingController();
  final districtController = TextEditingController();
  final selectedLessonPlace = ''.obs;
  final selectedGender = ''.obs;
  final city = ''.obs;
  String town = '';
  final sehirler = <String>[].obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;
  final images = <String>[].obs;
  final isPhoneOpen = false.obs;
  final selectedBranch = ''.obs;
  final isLoading = false.obs;
  final availability = <String, List<String>>{}.obs;
}

extension CreateTutoringControllerFieldsPart on CreateTutoringController {
  RxInt get carouselCurrentIndex => _state.carouselCurrentIndex;
  GlobalKey<FormState> get formKey => _state.formKey;
  TextEditingController get titleController => _state.titleController;
  TextEditingController get descriptionController =>
      _state.descriptionController;
  TextEditingController get branchController => _state.branchController;
  TextEditingController get priceController => _state.priceController;
  TextEditingController get cityController => _state.cityController;
  TextEditingController get districtController => _state.districtController;
  RxString get selectedLessonPlace => _state.selectedLessonPlace;
  RxString get selectedGender => _state.selectedGender;
  RxString get city => _state.city;
  String get town => _state.town;
  set town(String value) => _state.town = value;
  RxList<String> get sehirler => _state.sehirler;
  RxList<CitiesModel> get sehirlerVeIlcelerData => _state.sehirlerVeIlcelerData;
  RxList<String> get images => _state.images;
  RxBool get isPhoneOpen => _state.isPhoneOpen;
  RxString get selectedBranch => _state.selectedBranch;
  RxBool get isLoading => _state.isLoading;
  RxMap<String, List<String>> get availability => _state.availability;
}
