part of 'create_scholarship_controller.dart';

extension CreateScholarshipControllerFormPart on CreateScholarshipController {
  void initializeFormState() {
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null &&
        arguments.containsKey('scholarshipData') &&
        arguments['scholarshipData'] != null) {
      isEditing.value = true;
      scholarshipId.value = arguments['scholarshipId']?.toString() ?? '';
      final model =
          arguments['scholarshipData']['model'] as IndividualScholarshipsModel?;
      if (model != null) {
        _initializeFieldsForEdit(model);
      } else {
        AppSnackbar('common.error'.tr, 'scholarship.data_load_failed'.tr);
      }
    } else {
      isEditing.value = false;
      final dateFormat = DateFormat('dd.MM.yyyy');
      baslangicTarihi.value = dateFormat.format(DateTime.now());
      bitisTarihi.value =
          dateFormat.format(DateTime.now().add(Duration(days: 1)));
      aylar.clear();
    }

    currentSection.value = 1;
    basvuruYapilacakYer.value = isEditing.value
        ? basvuruYapilacakYer.value
        : CreateScholarshipController.applicationPlaceTurqAppValue;
    basvuruYapilacakYerController.text =
        applicationPlaceDisplayLabel(basvuruYapilacakYer.value);
    basvuruKosullariController.text =
        localizedConditionsText(basvuruKosullari.value);
    belgelerController.text = localizedDocumentsText(belgeler);
    updateAylarText();
    aylar.listen((_) => updateAylarText());
    loadCityDistrictData();
    loadHigherEducationData();
  }

  void _initializeFieldsForEdit(IndividualScholarshipsModel model) {
    baslik.value = model.baslik;
    baslikController.text = baslik.value;
    bursVeren.value = model.bursVeren;
    bursVerenController.text = bursVeren.value;
    aciklama.value = model.aciklama;
    aciklamaController.text = aciklama.value;
    basvuruURL.value = model.basvuruURL;
    basvuruURLController.text = basvuruURL.value;
    basvuruYapilacakYer.value = model.basvuruYapilacakYer;
    basvuruYapilacakYerController.text =
        applicationPlaceDisplayLabel(basvuruYapilacakYer.value);
    baslangicTarihi.value = model.baslangicTarihi;
    bitisTarihi.value = model.bitisTarihi;
    tutar.value = model.tutar;
    tutarController.text = tutar.value;
    ogrenciSayisi.value = model.ogrenciSayisi;
    ogrenciSayisiController.text = ogrenciSayisi.value;
    egitimKitlesi.value = model.egitimKitlesi;
    lisansTuru.assignAll(model.altEgitimKitlesi);
    geriOdemeli.value = model.geriOdemeli;
    mukerrerDurumu.value = model.mukerrerDurumu;
    hedefKitle.value = model.hedefKitle;
    sehirler.assignAll(model.sehirler);
    ilceler.assignAll(model.ilceler);
    universiteler.assignAll(model.universiteler);
    website.value = model.website;
    websiteController.text = website.value;
    logoPath.value = model.logo;
    customImagePath.value = model.img2;
    basvuruKosullari.value = model.basvuruKosullari;
    basvuruKosullariController.text =
        localizedConditionsText(basvuruKosullari.value);
    aylar.assignAll(model.aylar);
    belgeler.assignAll(model.belgeler);
    belgelerController.text = localizedDocumentsText(belgeler);
    logo.value = model.logo;
    templateUrl.value = model.img;
    template.value = model.template;
    ulke.value = model.ulke;
    if (model.template.isNotEmpty) {
      final templateNumber =
          int.tryParse(model.template.replaceAll('template', '')) ?? 0;
      selectedTemplateIndex.value = templateNumber - 1;
    }
  }

  void updateAylarText() {
    aylarText.value = aylar.isEmpty
        ? ""
        : 'scholarship.month_count_selected'
            .trParams({'count': aylar.length.toString()});
    aylarController.text = aylarText.value;
  }

  Future<void> loadCityDistrictData() async {
    try {
      final Map<String, List<String>> tempMap = {};
      final cityDistricts = await _cityDirectoryService.getCitiesAndDistricts();

      for (final item in cityDistricts) {
        final il = item.il;
        final ilce = item.ilce;
        if (!tempMap.containsKey(il)) {
          tempMap[il] = [];
        }
        tempMap[il]!.add(ilce);
      }
      iller.assignAll(await _cityDirectoryService.getSortedCities());
      ilIlceMap.assignAll(tempMap);
    } catch (_) {
      AppSnackbar('common.error'.tr, 'scholarship.city_data_failed'.tr);
    }
  }

  Future<void> loadHigherEducationData() async {
    try {
      final data = await _referenceDataService.getHigherEducationEntries();
      final Map<String, List<String>> tempMap = {};
      final Set<String> tempUniversiteler = {};

      for (final item in data) {
        final String il = item['il'];
        final String universite = item['universite'];
        tempUniversiteler.add(universite);
        if (!tempMap.containsKey(il)) {
          tempMap[il] = [];
        }
        if (!tempMap[il]!.contains(universite)) {
          tempMap[il]!.add(universite);
        }
      }

      final sortedUniversities = tempUniversiteler.toList();
      sortTurkishStrings(sortedUniversities);
      tumUniversiteler.assignAll(sortedUniversities);
      universiteMap.assignAll(tempMap);
      higherEducationData.assignAll(data);
    } catch (_) {
      AppSnackbar('common.error'.tr, 'scholarship.university_data_failed'.tr);
    }
  }

  List<String> getDistrictsForSelectedCities() {
    final List<String> districts = [];
    for (var il in sehirler) {
      districts.addAll(ilIlceMap[il] ?? []);
    }
    sortTurkishStrings(districts);
    return districts;
  }

  List<String> getUniversitiesForSelectedCities() {
    final List<String> universities = [
      CreateScholarshipController.allUniversitiesValue,
    ];

    if (lisansTuru.isEmpty) {
      if (hedefKitle.value ==
          CreateScholarshipController.targetAudienceAllTurkeyValue) {
        universities.addAll(tumUniversiteler);
      } else {
        for (var il in sehirler) {
          universities.addAll(universiteMap[il] ?? []);
        }
      }
      return universities.toSet().toList()
        ..sort(
          (a, b) => a == CreateScholarshipController.allUniversitiesValue
              ? -1
              : b == CreateScholarshipController.allUniversitiesValue
                  ? 1
                  : a.compareTo(b),
        );
    }

    if (hedefKitle.value ==
        CreateScholarshipController.targetAudienceAllTurkeyValue) {
      for (var uni in tumUniversiteler) {
        bool shouldAdd = false;
        for (var item in higherEducationData) {
          if (item['universite'] == uni) {
            String tip = item['tip'];
            if (lisansTuru.contains(
                  CreateScholarshipController.degreeAssociateValue,
                ) &&
                tip == 'ÖN LİSANS') {
              shouldAdd = true;
            } else if ((lisansTuru.contains(
                      CreateScholarshipController.degreeBachelorValue,
                    ) ||
                    lisansTuru.contains(
                      CreateScholarshipController.degreeMasterValue,
                    ) ||
                    lisansTuru.contains(
                      CreateScholarshipController.degreePhdValue,
                    )) &&
                tip == 'LİSANS') {
              shouldAdd = true;
            }
          }
        }
        if (shouldAdd && !universities.contains(uni)) {
          universities.add(uni);
        }
      }
    } else {
      for (var il in sehirler) {
        for (var uni in universiteMap[il] ?? []) {
          bool shouldAdd = false;
          for (var item in higherEducationData) {
            if (item['universite'] == uni && item['il'] == il) {
              String tip = item['tip'];
              if (lisansTuru.contains(
                    CreateScholarshipController.degreeAssociateValue,
                  ) &&
                  tip == 'ÖN LİSANS') {
                shouldAdd = true;
              } else if ((lisansTuru.contains(
                        CreateScholarshipController.degreeBachelorValue,
                      ) ||
                      lisansTuru.contains(
                        CreateScholarshipController.degreeMasterValue,
                      ) ||
                      lisansTuru.contains(
                        CreateScholarshipController.degreePhdValue,
                      )) &&
                  tip == 'LİSANS') {
                shouldAdd = true;
              }
            }
          }
          if (shouldAdd && !universities.contains(uni)) {
            universities.add(uni);
          }
        }
      }
    }

    return universities.toSet().toList()
      ..sort(
        (a, b) => a == CreateScholarshipController.allUniversitiesValue
            ? -1
            : b == CreateScholarshipController.allUniversitiesValue
                ? 1
                : compareTurkishStrings(a, b),
      );
  }

  void resetForm() {
    isEditing.value = false;
    scholarshipId.value = '';
    baslik.value = '';
    baslikController.text = '';
    bursVeren.value = '';
    bursVerenController.text = '';
    aciklama.value = '';
    aciklamaController.text = '';
    basvuruURL.value = '';
    basvuruYapilacakYer.value =
        CreateScholarshipController.applicationPlaceTurqAppValue;
    baslangicTarihi.value = DateFormat('dd.MM.yyyy').format(DateTime.now());
    bitisTarihi.value =
        DateFormat('dd.MM.yyyy').format(DateTime.now().add(Duration(days: 1)));
    tutar.value = '';
    tutarController.text = '';
    ogrenciSayisi.value = '';
    ogrenciSayisiController.text = '';
    egitimKitlesi.value = '';
    lisansTuru.clear();
    geriOdemeli.value = CreateScholarshipController.repayableNoValue;
    mukerrerDurumu.value =
        CreateScholarshipController.duplicateStatusCanReceiveValue;
    hedefKitle.value = '';
    sehirler.clear();
    ilceler.clear();
    universiteler.clear();
    website.value = '';
    logoPath.value = '';
    customImagePath.value = '';
    selectedTemplateIndex.value = -1;
    basvuruKosullari.value = '';
    aylar.clear();
    belgeler.clear();
    selectedItems.clear();
    logo.value = '';
    templateUrl.value = '';
    template.value = '';
    ulke.value = '';

    basvuruURLController.text = 'https://';
    basvuruYapilacakYerController.text = applicationPlaceDisplayLabel(
      CreateScholarshipController.applicationPlaceTurqAppValue,
    );
    websiteController.text = 'https://';
    basvuruKosullariController.text = '';
    aylarController.text = '';
    belgelerController.text = '';

    formKey.currentState?.reset();
    currentSection.value = 1;
  }

  void goToPreview() {
    if (formKey.currentState!.validate()) {
      final tag = controllerTag;
      if (tag == null || tag.isEmpty) return;
      Get.to(() => ScholarshipPreviewView(controllerTag: tag));
    }
  }
}
