part of 'tutoring_filter_controller.dart';

extension TutoringFilterControllerUiPart on TutoringFilterController {
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
}
