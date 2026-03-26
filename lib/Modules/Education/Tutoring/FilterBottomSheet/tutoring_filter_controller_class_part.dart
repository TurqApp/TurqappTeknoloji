part of 'tutoring_filter_controller.dart';

class TutoringFilterController extends GetxController {
  static TutoringFilterController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(TutoringFilterController(), permanent: permanent);
  }

  static TutoringFilterController? maybeFind() {
    final isRegistered = Get.isRegistered<TutoringFilterController>();
    if (!isRegistered) return null;
    return Get.find<TutoringFilterController>();
  }

  final TutoringController tutoringController = ensureTutoringController();
  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
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
