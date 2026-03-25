import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Utils/turkish_sort.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'tutoring_filter_controller_ui_part.dart';
part 'tutoring_filter_controller_actions_part.dart';

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

  final TutoringController tutoringController = TutoringController.ensure();
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
