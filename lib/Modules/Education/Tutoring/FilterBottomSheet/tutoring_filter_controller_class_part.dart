part of 'tutoring_filter_controller.dart';

class TutoringFilterController extends GetxController {
  final TutoringController tutoringController = ensureTutoringController();
  final CityDirectoryService _cityDirectoryService =
      ensureCityDirectoryService();
  final isLoading = true.obs;

  var selectedBranch = Rx<String?>(null);
  var selectedCity = Rx<String?>(null);
  var selectedDistrict = Rx<String?>(null);
  var selectedGender = Rx<String?>(null);
  var selectedLessonPlace = Rx<List<String>?>([]);
  var selectedSort = Rx<String?>(null);
  var maxPrice = Rx<double?>(null);
  var minPrice = Rx<double?>(null);
  final sehirler = <String>[].obs;
  final city = "".obs;
  final town = "".obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadTutoringFilterCities(this);
  }
}
