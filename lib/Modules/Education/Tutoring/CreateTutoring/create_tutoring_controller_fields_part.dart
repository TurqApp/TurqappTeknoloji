part of 'create_tutoring_controller.dart';

class _CreateTutoringControllerState {
  final cityDirectoryService = ensureCityDirectoryService();
  final tutoringRepository = ensureTutoringRepository();
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
  double? lat;
  double? long;
}

extension CreateTutoringControllerFieldsPart on CreateTutoringController {
  CityDirectoryService get _cityDirectoryService => _state.cityDirectoryService;
  TutoringRepository get _tutoringRepository => _state.tutoringRepository;
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
  double? get _lat => _state.lat;
  set _lat(double? value) => _state.lat = value;
  double? get _long => _state.long;
  set _long(double? value) => _state.long = value;
}
