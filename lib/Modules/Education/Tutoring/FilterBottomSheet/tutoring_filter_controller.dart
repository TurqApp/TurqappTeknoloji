import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Utils/turkish_sort.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class TutoringFilterController extends GetxController {
  static TutoringFilterController _ensureController({
    bool permanent = false,
  }) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(TutoringFilterController(), permanent: permanent);
  }

  static TutoringFilterController ensure({bool permanent = false}) =>
      _ensureController(permanent: permanent);

  static TutoringFilterController? maybeFind() {
    if (!Get.isRegistered<TutoringFilterController>()) return null;
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
    loadSehirler();
  }

  void showIlSec() {
    ListBottomSheet.show(
      context: Get.context!,
      items: sehirler,
      title: "common.select_city".tr,
      selectedItem: city.value,
      onSelect: (v) {
        city.value = v.toString();
        selectedCity.value = v.toString();
        town.value = "";
        selectedDistrict.value = null;
      },
    );
  }

  void showIlcelerSec() {
    final List<String> ilceListesi = sehirlerVeIlcelerData
        .where((doc) => doc.il == city.value && city.value.isNotEmpty)
        .map((doc) => doc.ilce)
        .toList();
    sortTurkishStrings(ilceListesi);

    ListBottomSheet.show(
      context: Get.context!,
      items: ilceListesi,
      title: "common.select_district".tr,
      selectedItem: town.value,
      onSelect: (v) {
        town.value = v.toString();
        selectedDistrict.value = v.toString();
      },
    );
  }

  Future<void> loadSehirler() async {
    try {
      sehirlerVeIlcelerData.value =
          await _cityDirectoryService.getCitiesAndDistricts();
      sehirler.value = await _cityDirectoryService.getSortedCities();
    } catch (_) {
      sehirler.value = []; // Hata durumunda boş liste ile devam et
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilters() {
    // Orijinal listeyi kopyala
    List<TutoringModel> filteredList = List.from(
      tutoringController.tutoringList,
    );

    // Branş filtresi
    if (selectedBranch.value != null && selectedBranch.value!.isNotEmpty) {
      filteredList = filteredList
          .where((tutoring) => tutoring.brans == selectedBranch.value)
          .toList();
    }

    // Cinsiyet filtresi
    if (selectedGender.value != null && selectedGender.value!.isNotEmpty) {
      filteredList = filteredList
          .where((tutoring) => tutoring.cinsiyet == selectedGender.value)
          .toList();
    }

    // Ders yeri filtresi
    if (selectedLessonPlace.value != null &&
        selectedLessonPlace.value!.isNotEmpty) {
      filteredList = filteredList
          .where(
            (tutoring) => selectedLessonPlace.value!.any(
              (place) => tutoring.dersYeri.contains(place),
            ),
          )
          .toList();
    }

    // Fiyat aralığı filtresi
    if (maxPrice.value != null) {
      filteredList = filteredList
          .where((tutoring) => tutoring.fiyat <= maxPrice.value!)
          .toList();
    }
    if (minPrice.value != null) {
      filteredList = filteredList
          .where((tutoring) => tutoring.fiyat >= minPrice.value!)
          .toList();
    }

    // Şehir ve ilçe filtresi (ayrı bir kontrolle)
    if (selectedCity.value != null && selectedCity.value!.isNotEmpty) {
      filteredList = filteredList
          .where((tutoring) => tutoring.sehir == selectedCity.value)
          .toList();
    }
    if (selectedDistrict.value != null && selectedDistrict.value!.isNotEmpty) {
      filteredList = filteredList
          .where((tutoring) => tutoring.ilce == selectedDistrict.value)
          .toList();
    }

    _applySort(filteredList);

    // Filtrelenmiş listeyi güncelle
    tutoringController.tutoringList.value = filteredList;
    Get.back(); // Bottom sheet'i kapat
  }

  void _applySort(List<TutoringModel> list) {
    final sort = selectedSort.value ?? '';
    if (sort == 'En Yeni') {
      list.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
      return;
    }
    if (sort == 'En Çok Görüntülenen') {
      list.sort(
        (a, b) => (b.viewCount ?? 0).compareTo(a.viewCount ?? 0),
      );
      return;
    }
    if (sort == 'Bana En Yakın') {
      final userCity =
          (CurrentUserService.instance.currentUser?.city ?? '').trim();
      list.sort((a, b) {
        final aScore = a.sehir == userCity ? 1 : 0;
        final bScore = b.sehir == userCity ? 1 : 0;
        if (aScore != bScore) {
          return bScore.compareTo(aScore);
        }
        return b.timeStamp.compareTo(a.timeStamp);
      });
    }
  }

  void clearFilters() {
    selectedBranch.value = null;
    selectedCity.value = null;
    selectedDistrict.value = null;
    selectedGender.value = null;
    selectedLessonPlace.value = [];
    selectedSort.value = null;
    maxPrice.value = null;
    minPrice.value = null;
    city.value = "";
    town.value = "";
    tutoringController.tutoringList.value = List.from(
      tutoringController.tutoringList,
    ); // Orijinal listeyi geri yükle
  }
}
