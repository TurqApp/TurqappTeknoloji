part of 'tutoring_filter_bottom_sheet.dart';

extension TutoringFilterBottomSheetContentPart on TutoringFilterBottomSheet {
  static const _branchValues = <String>[
    'Yaz Okulu',
    'Orta Öğretim',
    'İlk Öğretim',
    'Yabancı Dil',
    'Yazılım',
    'Direksiyon',
    'Spor',
    'Sanat',
    'Müzik',
    'Tiyatro',
    'Kişisel Gelişim',
    'Mesleki',
    'Özel Eğitim',
    'Çocuk',
    'Diksiyon',
    'Fotoğrafçılık',
  ];

  static const _genderValues = <String>['Erkek', 'Kadın', 'Farketmez'];
  static const _sortValues = <String>[
    'En Yeni',
    'Bana En Yakın',
    'En Çok Görüntülenen',
  ];
  static const _lessonPlaceValues = <String>[
    'Öğrencinin Evi',
    'Öğretmenin Evi',
    'Öğrencinin veya Öğretmenin Evi',
    'Uzaktan Eğitim',
    'Ders Verme Alanı',
  ];

  Widget _buildPage(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.all(15),
        constraints: BoxConstraints(maxHeight: Get.height * 0.9),
        child: Column(
          children: [
            AppSheetHeader(title: "tutoring.filter_title".tr),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBranchSection(context),
                    16.ph,
                    _buildSingleSelectSection(
                      title: "tutoring.gender_title".tr,
                      values: _genderValues,
                      selectedValue: filterController.selectedGender,
                      labelBuilder: _genderLabel,
                    ),
                    const Divider(),
                    _buildSingleSelectSection(
                      title: "tutoring.sort_title".tr,
                      values: _sortValues,
                      selectedValue: filterController.selectedSort,
                      labelBuilder: _sortLabel,
                    ),
                    const Divider(),
                    _buildLessonPlaceSection(),
                    const Divider(),
                    _buildLocationSection(),
                    16.ph,
                    _buildBottomActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchSection(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      runAlignment: WrapAlignment.start,
      children: _branchValues.map((value) {
        return Obx(
          () => PasajSelectionChip(
            label: _branchLabel(value),
            selected: filterController.selectedBranch.value == value,
            onTap: () {
              filterController.selectedBranch.value =
                  filterController.selectedBranch.value == value ? null : value;
            },
            width: (MediaQuery.of(context).size.width - 32 - 16) / 3,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            borderRadius: BorderRadius.circular(12),
            fontSize: 14,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSingleSelectSection({
    required String title,
    required List<String> values,
    required RxnString selectedValue,
    required String Function(String value) labelBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyles.bold18Black),
        8.ph,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          children: values.map((value) {
            return Obx(
              () => GestureDetector(
                onTap: () {
                  selectedValue.value =
                      selectedValue.value == value ? null : value;
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      selectedValue.value == value
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: selectedValue.value == value
                          ? Colors.green
                          : Colors.grey,
                    ),
                    4.pw,
                    Text(
                      labelBuilder(value),
                      style: TextStyles.textFieldTitle,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLessonPlaceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("tutoring.lesson_place_title".tr, style: TextStyles.bold18Black),
        8.ph,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          children: _lessonPlaceValues.map((value) {
            return Obx(
              () => GestureDetector(
                onTap: () {
                  if (filterController.selectedLessonPlace.value!
                      .contains(value)) {
                    filterController.selectedLessonPlace.value!.remove(value);
                  } else {
                    filterController.selectedLessonPlace.value!.add(value);
                  }
                  filterController.selectedLessonPlace.refresh();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      filterController.selectedLessonPlace.value!
                              .contains(value)
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: filterController.selectedLessonPlace.value!
                              .contains(value)
                          ? Colors.green
                          : Colors.grey,
                    ),
                    4.pw,
                    Text(
                      _lessonPlaceLabel(value),
                      style: TextStyles.textFieldTitle,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("tutoring.service_location_title".tr,
            style: TextStyles.bold18Black),
        8.ph,
        Obx(
          () => Row(
            children: [
              Expanded(
                child: _buildLocationPicker(
                  text: filterController.city.value.isEmpty
                      ? "common.select_city".tr
                      : filterController.city.value,
                  onTap: filterController.showIlSec,
                ),
              ),
              if (filterController.city.value.isNotEmpty)
                const SizedBox(width: 12),
              if (filterController.city.value.isNotEmpty)
                Expanded(
                  child: _buildLocationPicker(
                    text: filterController.town.value.isEmpty
                        ? "common.select_district".tr
                        : filterController.town.value,
                    onTap: filterController.showIlcelerSec,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationPicker({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.03),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                text,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
              const Icon(CupertinoIcons.chevron_down, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: filterController.clearFilters,
            child: Container(
              alignment: Alignment.center,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Text("common.reset".tr, style: TextStyles.bold16Black),
            ),
          ),
        ),
        8.pw,
        Expanded(
          child: GestureDetector(
            onTap: filterController.applyFilters,
            child: Container(
              alignment: Alignment.center,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text("common.apply".tr, style: TextStyles.bold16White),
            ),
          ),
        ),
      ],
    );
  }
}
