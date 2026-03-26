part of 'tutoring_filter_controller.dart';

class _TutoringFilterControllerState {
  final TutoringController tutoringController = ensureTutoringController();
  final CityDirectoryService cityDirectoryService =
      ensureCityDirectoryService();
  final RxBool isLoading = true.obs;
  final Rx<String?> selectedBranch = Rx<String?>(null);
  final Rx<String?> selectedCity = Rx<String?>(null);
  final Rx<String?> selectedDistrict = Rx<String?>(null);
  final Rx<String?> selectedGender = Rx<String?>(null);
  final Rx<List<String>?> selectedLessonPlace = Rx<List<String>?>([]);
  final Rx<String?> selectedSort = Rx<String?>(null);
  final Rx<double?> maxPrice = Rx<double?>(null);
  final Rx<double?> minPrice = Rx<double?>(null);
  final RxList<String> sehirler = <String>[].obs;
  final RxString city = ''.obs;
  final RxString town = ''.obs;
  final RxList<CitiesModel> sehirlerVeIlcelerData = <CitiesModel>[].obs;
}

extension TutoringFilterControllerFieldsPart on TutoringFilterController {
  TutoringController get tutoringController => _state.tutoringController;
  CityDirectoryService get _cityDirectoryService => _state.cityDirectoryService;
  RxBool get isLoading => _state.isLoading;
  Rx<String?> get selectedBranch => _state.selectedBranch;
  Rx<String?> get selectedCity => _state.selectedCity;
  Rx<String?> get selectedDistrict => _state.selectedDistrict;
  Rx<String?> get selectedGender => _state.selectedGender;
  Rx<List<String>?> get selectedLessonPlace => _state.selectedLessonPlace;
  Rx<String?> get selectedSort => _state.selectedSort;
  Rx<double?> get maxPrice => _state.maxPrice;
  Rx<double?> get minPrice => _state.minPrice;
  RxList<String> get sehirler => _state.sehirler;
  RxString get city => _state.city;
  RxString get town => _state.town;
  RxList<CitiesModel> get sehirlerVeIlcelerData => _state.sehirlerVeIlcelerData;
}
