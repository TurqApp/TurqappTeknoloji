import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Services/education_reference_data_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Services/scholarship_firestore_path.dart';
import 'package:turqappv2/Core/Utils/turkish_sort.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/scholarship_preview_view.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_view.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';

class CreateScholarshipController extends GetxController {
  static CreateScholarshipController ensure({
    required String tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(CreateScholarshipController(),
        tag: tag, permanent: permanent);
  }

  static CreateScholarshipController? maybeFind({required String tag}) {
    final isRegistered =
        Get.isRegistered<CreateScholarshipController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<CreateScholarshipController>(tag: tag);
  }

  static const String allUniversitiesValue = 'Tüm Üniversiteler';
  static const String turkeyCountryValue = 'Türkiye';
  static const String applicationPlaceTurqAppValue = 'TurqApp';
  static const String applicationPlaceWebsiteValue = 'Web Site';
  static const String targetAudiencePopulationValue = 'Nüfusa Göre';
  static const String targetAudienceResidenceValue = 'İkamete Göre';
  static const String targetAudienceAllTurkeyValue = 'Tüm Türkiye';
  static const String repayableYesValue = 'Evet';
  static const String repayableNoValue = 'Hayır';
  static const String duplicateStatusCanReceiveValue = 'Alabilir';
  static const String duplicateStatusCannotReceiveExceptKykValue =
      'Alamaz (KYK Hariç)';
  static const String educationAudienceAllValue = 'Hepsi';
  static const String educationAudienceMiddleSchoolValue = 'Ortaokul';
  static const String educationAudienceHighSchoolValue = 'Lise';
  static const String educationAudienceUndergraduateValue = 'Lisans';
  static const String degreeAssociateValue = 'Ön Lisans';
  static const String degreeBachelorValue = 'Lisans';
  static const String degreeMasterValue = 'Yüksek Lisans';
  static const String degreePhdValue = 'Doktora';
  static const String educationAudienceAllExpandedValue =
      'Ortaokul, Lise, Lisans';
  final UserRepository _userRepository = UserRepository.ensure();
  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
  final EducationReferenceDataService _referenceDataService =
      EducationReferenceDataService.ensure();
  var isLoading = false.obs;
  var isEditing = false.obs;
  var scholarshipId = ''.obs;
  final baslik = ''.obs;
  final baslikController = TextEditingController();
  final bursVeren = ''.obs;
  final bursVerenController = TextEditingController();
  final aciklama = ''.obs;
  final aciklamaController = TextEditingController();
  final basvuruURL = ''.obs;
  final basvuruURLController = TextEditingController(text: 'https://');
  final basvuruYapilacakYer = ''.obs;
  final basvuruYapilacakYerController = TextEditingController();
  final baslangicTarihi = ''.obs;
  final bitisTarihi = ''.obs;
  final tutar = ''.obs;
  final tutarController = TextEditingController();
  final ogrenciSayisi = ''.obs;
  final ogrenciSayisiController = TextEditingController();
  final egitimKitlesi = ''.obs;
  final lisansTuru = <String>[].obs;
  final geriOdemeli = repayableNoValue.obs;
  final mukerrerDurumu = duplicateStatusCanReceiveValue.obs;
  final hedefKitle = ''.obs;
  final sehirler = <String>[].obs;
  final ilceler = <String>[].obs;
  final universiteler = <String>[].obs;
  final website = ''.obs;
  final websiteController = TextEditingController(text: 'https://');
  final currentSection = 1.obs;
  final logoPath = ''.obs;
  final customImagePath = ''.obs;
  final selectedTemplateIndex = (-1).obs;
  final formKey = GlobalKey<FormState>();
  final applicationOption = [
    applicationPlaceTurqAppValue,
    applicationPlaceWebsiteValue,
  ].obs;
  final applicationOptionValue = applicationPlaceTurqAppValue.obs;
  final basvuruKosullari = ''.obs;
  final basvuruKosullariController = TextEditingController();
  final aylar = <String>[].obs;
  final aylarController = TextEditingController();
  final aylarText = ''.obs;
  final belgeler = <String>[].obs;
  final belgelerController = TextEditingController();
  final selectedItems = <String>[].obs;
  final logo = ''.obs;
  final templateUrl = ''.obs;
  final template = ''.obs;
  final ulke = ''.obs;

  String get _currentUid {
    final serviceUid = CurrentUserService.instance.userId.trim();
    if (serviceUid.isNotEmpty) return serviceUid;
    return FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
  }

  final bursKosullari = <String>[
    "T.C. vatandaşı olmak.",
    "En az lise düzeyinde öğrenim görüyor olmak.",
    "Herhangi bir disiplin cezası almamış olmak.",
    "Ailesinin aylık toplam gelirinin belirli bir seviyenin altında olması.",
    "Başka bir kurumdan karşılıksız burs almıyor olmak.",
    "Örgün öğretim programında kayıtlı öğrenci olmak.",
    "Akademik not ortalamasının en az 2.50/4.00 olması.",
    "Adli sicil kaydının temiz olması.",
    "İlan edilen son başvuru tarihine kadar başvuru yapılmış olması.",
    "Belirtilen belgelerin eksiksiz şekilde teslim edilmiş olması.",
    "Burs başvuru formunun eksiksiz doldurulması.",
    "Burs verilen il/ilçede ikamet ediyor olmak (gerekiyorsa).",
    "Eğitim süresi boyunca düzenli olarak başarı göstereceğini taahhüt etmek.",
    "Başvuru sırasında gerçeğe aykırı beyanda bulunmamak.",
    "Bursu sağlayan kurumun düzenlediği mülakat veya değerlendirme süreçlerine katılmak.",
  ].obs;

  final gerekliBelgeler = <String>[
    "Kimlik Kart Fotoğrafı",
    "Öğrenci Belgesi (E Devlet)",
    "Transkript Belgesi",
    "Adli Sicil Kaydı (E Devlet)",
    "Aile Nüfus Kayıt Belgesi (E Devlet)",
    "YKS - AYT Sonuç Belgesi (ÖSYM)",
    "SGK Hizmet Dökümü (E Devlet Kendisi)",
    "SGK Hizmet Dökümü (E Devlet Anne Ve Baba)",
    "Tapu Tescil Belgesi (E Devlet Kendisi)",
    "Engelli Sağlık Kurulu Raporu",
  ];

  final bursVerilecekAylar = <String>[
    "Eylül",
    "Ekim",
    "Kasım",
    "Aralık",
    "Ocak",
    "Şubat",
    "Mart",
    "Nisan",
    "Mayıs",
    "Haziran",
    "Temmuz",
    "Ağustos",
  ];

  final iller = <String>[].obs;
  final ilIlceMap = <String, List<String>>{}.obs;
  final universiteMap = <String, List<String>>{}.obs;
  final tumUniversiteler = <String>[].obs;
  final higherEducationData = <dynamic>[].obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseStorage _storage = FirebaseStorage.instance;

  final GlobalKey templateKey = GlobalKey();
  String? controllerTag;

  Future<Map<String, dynamic>> _authorFieldsForCurrentUser() async {
    final uid = _currentUid;
    if (uid.isEmpty) {
      return const <String, dynamic>{
        'nickname': '',
        'displayName': '',
        'avatarUrl': '',
        'authorNickname': '',
        'authorDisplayName': '',
        'authorAvatarUrl': '',
        'rozet': '',
      };
    }
    final raw = await _userRepository.getUserRaw(
      uid,
      preferCache: true,
      cacheOnly: false,
    );
    final nickname = (raw?['nickname'] ?? '').toString().trim();
    final displayName = (raw?['displayName'] ?? '').toString().trim();
    final avatarUrl = (raw?['avatarUrl'] ?? '').toString().trim();
    final rozet = (raw?['rozet'] ?? '').toString().trim();
    return <String, dynamic>{
      'nickname': nickname,
      'displayName': displayName.isNotEmpty ? displayName : nickname,
      'avatarUrl': avatarUrl,
      'authorNickname': nickname,
      'authorDisplayName': displayName.isNotEmpty ? displayName : nickname,
      'authorAvatarUrl': avatarUrl,
      'rozet': rozet,
    };
  }

  Future<Uint8List?> _compressFileToWebp(File file, {int quality = 85}) async {
    try {
      return await FlutterImageCompress.compressWithFile(
        file.path,
        format: CompressFormat.webp,
        quality: quality,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _compressBytesToWebp(Uint8List bytes,
      {int quality = 85}) async {
    try {
      return await FlutterImageCompress.compressWithList(
        bytes,
        format: CompressFormat.webp,
        quality: quality,
      );
    } catch (_) {
      return null;
    }
  }

  String applicationPlaceDisplayLabel(String value) {
    switch (value) {
      case applicationPlaceTurqAppValue:
        return 'scholarship.application_place_turqapp'.tr;
      case 'Burs Web Site':
      case applicationPlaceWebsiteValue:
        return 'scholarship.application_place_website'.tr;
      default:
        return value;
    }
  }

  bool isWebsiteApplicationPlace(String value) =>
      value == applicationPlaceWebsiteValue || value == 'Burs Web Site';

  String get turkeyValue => turkeyCountryValue;

  @override
  void onInit() {
    super.onInit();
    // Argümanları kontrol et ve doğru şekilde işle
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
        // Model null ise hata mesajı göster
        AppSnackbar('common.error'.tr, 'scholarship.data_load_failed'.tr);
      }
    } else {
      // Yeni burs oluşturma için varsayılan değerler
      isEditing.value = false;
      final dateFormat = DateFormat('dd.MM.yyyy');
      baslangicTarihi.value = dateFormat.format(DateTime.now());
      bitisTarihi.value =
          dateFormat.format(DateTime.now().add(Duration(days: 1)));
      // Varsayılan ay seçimi yapılmasın (opsiyonel alan)
      aylar.clear();
    }

    // Diğer başlangıç ayarları
    currentSection.value = 1;
    basvuruYapilacakYer.value = isEditing.value
        ? basvuruYapilacakYer.value
        : applicationPlaceTurqAppValue;
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

  String awardMonthLabel(String value) {
    switch (value) {
      case 'Ocak':
        return 'common.month.january'.tr;
      case 'Şubat':
        return 'common.month.february'.tr;
      case 'Mart':
        return 'common.month.march'.tr;
      case 'Nisan':
        return 'common.month.april'.tr;
      case 'Mayıs':
        return 'common.month.may'.tr;
      case 'Haziran':
        return 'common.month.june'.tr;
      case 'Temmuz':
        return 'common.month.july'.tr;
      case 'Ağustos':
        return 'common.month.august'.tr;
      case 'Eylül':
        return 'common.month.september'.tr;
      case 'Ekim':
        return 'common.month.october'.tr;
      case 'Kasım':
        return 'common.month.november'.tr;
      case 'Aralık':
        return 'common.month.december'.tr;
      default:
        return value;
    }
  }

  String scholarshipRepayableLabel(String value) {
    switch (value) {
      case repayableYesValue:
        return 'common.yes'.tr;
      case repayableNoValue:
        return 'common.no'.tr;
      default:
        return value;
    }
  }

  String scholarshipDuplicateStatusLabel(String value) {
    switch (value) {
      case duplicateStatusCanReceiveValue:
        return 'scholarship.duplicate_status.can_receive'.tr;
      case duplicateStatusCannotReceiveExceptKykValue:
        return 'scholarship.duplicate_status.cannot_receive_except_kyk'.tr;
      default:
        return value;
    }
  }

  String scholarshipTargetAudienceLabel(String value) {
    switch (value) {
      case targetAudiencePopulationValue:
        return 'scholarship.target.population'.tr;
      case targetAudienceResidenceValue:
        return 'scholarship.target.residence'.tr;
      case targetAudienceAllTurkeyValue:
        return 'scholarship.target.all_turkiye'.tr;
      default:
        return value;
    }
  }

  String scholarshipEducationAudienceLabel(String value) {
    switch (value) {
      case educationAudienceAllValue:
        return 'scholarship.education.all'.tr;
      case educationAudienceMiddleSchoolValue:
        return 'scholarship.education.middle_school'.tr;
      case educationAudienceHighSchoolValue:
        return 'scholarship.education.high_school'.tr;
      case educationAudienceUndergraduateValue:
        return 'scholarship.education.undergraduate'.tr;
      case educationAudienceAllExpandedValue:
        return [
          'scholarship.education.middle_school'.tr,
          'scholarship.education.high_school'.tr,
          'scholarship.education.undergraduate'.tr,
        ].join(', ');
      default:
        return value;
    }
  }

  String scholarshipCountryLabel(String value) {
    switch (value) {
      case turkeyCountryValue:
        return 'common.country_turkey'.tr;
      default:
        return value;
    }
  }

  String scholarshipConditionLabel(String value) {
    switch (value) {
      case 'T.C. vatandaşı olmak.':
        return 'scholarship.condition.citizen'.tr;
      case 'En az lise düzeyinde öğrenim görüyor olmak.':
        return 'scholarship.condition.min_high_school'.tr;
      case 'Herhangi bir disiplin cezası almamış olmak.':
        return 'scholarship.condition.no_discipline'.tr;
      case 'Ailesinin aylık toplam gelirinin belirli bir seviyenin altında olması.':
        return 'scholarship.condition.family_income'.tr;
      case 'Başka bir kurumdan karşılıksız burs almıyor olmak.':
        return 'scholarship.condition.no_other_grant'.tr;
      case 'Örgün öğretim programında kayıtlı öğrenci olmak.':
        return 'scholarship.condition.formal_education'.tr;
      case 'Akademik not ortalamasının en az 2.50/4.00 olması.':
        return 'scholarship.condition.gpa'.tr;
      case 'Adli sicil kaydının temiz olması.':
        return 'scholarship.condition.clean_record'.tr;
      case 'İlan edilen son başvuru tarihine kadar başvuru yapılmış olması.':
        return 'scholarship.condition.apply_before_deadline'.tr;
      case 'Belirtilen belgelerin eksiksiz şekilde teslim edilmiş olması.':
        return 'scholarship.condition.documents_complete'.tr;
      case 'Burs başvuru formunun eksiksiz doldurulması.':
        return 'scholarship.condition.form_complete'.tr;
      case 'Burs verilen il/ilçede ikamet ediyor olmak (gerekiyorsa).':
        return 'scholarship.condition.residence'.tr;
      case 'Eğitim süresi boyunca düzenli olarak başarı göstereceğini taahhüt etmek.':
        return 'scholarship.condition.success_commitment'.tr;
      case 'Başvuru sırasında gerçeğe aykırı beyanda bulunmamak.':
        return 'scholarship.condition.truthful_declaration'.tr;
      case 'Bursu sağlayan kurumun düzenlediği mülakat veya değerlendirme süreçlerine katılmak.':
        return 'scholarship.condition.attend_evaluation'.tr;
      default:
        return value;
    }
  }

  String scholarshipDocumentLabel(String value) {
    switch (value) {
      case 'Kimlik Kart Fotoğrafı':
        return 'scholarship.document.id_card_photo'.tr;
      case 'Öğrenci Belgesi (E Devlet)':
        return 'scholarship.document.student_certificate'.tr;
      case 'Transkript Belgesi':
        return 'scholarship.document.transcript'.tr;
      case 'Adli Sicil Kaydı (E Devlet)':
        return 'scholarship.document.criminal_record'.tr;
      case 'Aile Nüfus Kayıt Belgesi (E Devlet)':
        return 'scholarship.document.family_registry'.tr;
      case 'YKS - AYT Sonuç Belgesi (ÖSYM)':
        return 'scholarship.document.exam_results'.tr;
      case 'SGK Hizmet Dökümü (E Devlet Kendisi)':
        return 'scholarship.document.sgk_self'.tr;
      case 'SGK Hizmet Dökümü (E Devlet Anne Ve Baba)':
        return 'scholarship.document.sgk_parents'.tr;
      case 'Tapu Tescil Belgesi (E Devlet Kendisi)':
        return 'scholarship.document.title_deed'.tr;
      case 'Engelli Sağlık Kurulu Raporu':
        return 'scholarship.document.disability_report'.tr;
      default:
        return value;
    }
  }

  String localizedConditionsText(String value) {
    return value
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map(scholarshipConditionLabel)
        .join('\n');
  }

  String localizedDocumentsText(
    Iterable<String> items, {
    String separator = '\n',
  }) {
    return items
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map(scholarshipDocumentLabel)
        .join(separator);
  }

  @override
  void onClose() {
    // Dispose controllers if needed
    // baslikController.dispose();
    // bursVerenController.dispose();
    // aciklamaController.dispose();
    // belgelerController.dispose();
    // basvuruURLController.dispose();
    // basvuruKosullariController.dispose();
    // websiteController.dispose();
    // basvuruYapilacakYerController.dispose();
    // aylarController.dispose();
    super.onClose();
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
    } catch (e) {
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
    } catch (e) {
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
    final List<String> universities = [allUniversitiesValue];

    if (lisansTuru.isEmpty) {
      if (hedefKitle.value == targetAudienceAllTurkeyValue) {
        universities.addAll(tumUniversiteler);
      } else {
        for (var il in sehirler) {
          universities.addAll(universiteMap[il] ?? []);
        }
      }
      return universities.toSet().toList()
        ..sort(
          (a, b) => a == allUniversitiesValue
              ? -1
              : b == allUniversitiesValue
                  ? 1
                  : a.compareTo(b),
        );
    }

    if (hedefKitle.value == targetAudienceAllTurkeyValue) {
      for (var uni in tumUniversiteler) {
        bool shouldAdd = false;
        for (var item in higherEducationData) {
          if (item['universite'] == uni) {
            String tip = item['tip'];
            if (lisansTuru.contains(degreeAssociateValue) &&
                tip == 'ÖN LİSANS') {
              shouldAdd = true;
            } else if ((lisansTuru.contains(degreeBachelorValue) ||
                    lisansTuru.contains(degreeMasterValue) ||
                    lisansTuru.contains(degreePhdValue)) &&
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
              if (lisansTuru.contains(degreeAssociateValue) &&
                  tip == 'ÖN LİSANS') {
                shouldAdd = true;
              } else if ((lisansTuru.contains(degreeBachelorValue) ||
                      lisansTuru.contains(degreeMasterValue) ||
                      lisansTuru.contains(degreePhdValue)) &&
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
        (a, b) => a == allUniversitiesValue
            ? -1
            : b == allUniversitiesValue
                ? 1
                : compareTurkishStrings(a, b),
      );
  }

  String universityLabel(String value) {
    return value == allUniversitiesValue
        ? 'scholarship.all_universities'.tr
        : value;
  }

  Future<String?> _uploadImage(String localPath, {bool isLogo = false}) async {
    if (localPath.isEmpty) {
      return null;
    }

    // URL ise yükleme yapma, mevcut URL'yi döndür
    if (localPath.startsWith('http')) {
      return localPath;
    }

    try {
      final file = File(localPath);
      if (!await file.exists()) {
        AppSnackbar('common.error'.tr, 'scholarship.file_missing'.tr);
        return null;
      }
      final nsfw = await OptimizedNSFWService.checkImage(file);
      if (nsfw.errorMessage != null) {
        AppSnackbar('common.error'.tr, 'tests.image_analyze_failed'.tr);
        return null;
      }
      if (nsfw.isNSFW) {
        AppSnackbar('common.error'.tr, 'tests.image_invalid'.tr);
        return null;
      }

      final webpBytes = await _compressFileToWebp(file, quality: 85);
      if (webpBytes == null || webpBytes.isEmpty) {
        AppSnackbar('common.error'.tr, 'scholarship.image_convert_failed'.tr);
        return null;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = _storage
          .ref()
          .child('scholarships/${isLogo ? 'logos' : 'images'}/$timestamp.webp');
      await ref.putData(
        webpBytes,
        SettableMetadata(
          contentType: 'image/webp',
          cacheControl: 'public, max-age=31536000, immutable',
        ),
      );
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (_) {
      AppSnackbar('common.error'.tr, 'scholarship.image_upload_failed'.tr);
      return null;
    }
  }

  Future<String?> _captureAndUploadTemplate() async {
    try {
      if (selectedTemplateIndex.value == -1) {
        return null;
      }

      RenderRepaintBoundary? boundary = templateKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        return null;
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return null;
      }

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(tempPath);

      // Dosyayı yazmadan önce varlığını kontrol edin
      if (await file.exists()) {
        await file.delete(); // Eski dosyayı sil
      }
      await file.writeAsBytes(bytes);

      // Dosyanın yazıldığını doğrulayın
      if (!await file.exists()) {
        return null;
      }
      final nsfw = await OptimizedNSFWService.checkImage(file);
      if (nsfw.errorMessage != null) {
        AppSnackbar('common.error'.tr, 'tests.image_analyze_failed'.tr);
        return null;
      }
      if (nsfw.isNSFW) {
        AppSnackbar('common.error'.tr, 'tests.image_invalid'.tr);
        return null;
      }

      final webpBytes = await _compressBytesToWebp(bytes, quality: 85);
      if (webpBytes == null || webpBytes.isEmpty) {
        AppSnackbar(
            'common.error'.tr, 'scholarship.template_convert_failed'.tr);
        return null;
      }

      final ref = _storage.ref().child(
          'scholarships/templates/${DateTime.now().millisecondsSinceEpoch}.webp');
      await ref.putData(
        webpBytes,
        SettableMetadata(
          contentType: 'image/webp',
          cacheControl: 'public, max-age=31536000, immutable',
        ),
      );
      final downloadUrl = await ref.getDownloadURL();
      templateUrl.value = downloadUrl;
      template.value =
          'template${selectedTemplateIndex.value + 1}'; // Şablon adını güncelle
      return downloadUrl;
    } catch (_) {
      AppSnackbar('common.error'.tr, 'scholarship.template_capture_failed'.tr);
      return null;
    }
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
    basvuruYapilacakYer.value = applicationPlaceTurqAppValue;
    baslangicTarihi.value = DateFormat('dd.MM.yyyy').format(DateTime.now());
    bitisTarihi.value =
        DateFormat('dd.MM.yyyy').format(DateTime.now().add(Duration(days: 1)));
    tutar.value = '';
    tutarController.text = '';
    ogrenciSayisi.value = '';
    ogrenciSayisiController.text = '';
    egitimKitlesi.value = '';
    lisansTuru.clear();
    geriOdemeli.value = repayableNoValue;
    mukerrerDurumu.value = duplicateStatusCanReceiveValue;
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
    ulke.value = ''; // Reset country

    basvuruURLController.text = 'https://';
    basvuruYapilacakYerController.text =
        applicationPlaceDisplayLabel(applicationPlaceTurqAppValue);
    websiteController.text = 'https://';
    basvuruKosullariController.text = '';
    aylarController.text = '';
    belgelerController.text = '';

    formKey.currentState?.reset();
    currentSection.value = 1;
  }

  Future<void> saveScholarship() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      if (formKey.currentState!.validate()) {
        try {
          if (selectedTemplateIndex.value != -1) {
            final templateUrlResult = await _captureAndUploadTemplate();
            if (templateUrlResult == null) {
              AppSnackbar(
                'common.error'.tr,
                'scholarship.template_capture_failed'.tr,
              );
              return;
            }
          }

          final String? customImageUrl = customImagePath.value.isNotEmpty &&
                  !customImagePath.value.startsWith('http')
              ? await _uploadImage(customImagePath.value)
              : customImagePath.value;
          final String? logoUrl =
              logoPath.value.isNotEmpty && !logoPath.value.startsWith('http')
                  ? await _uploadImage(logoPath.value, isLogo: true)
                  : logoPath.value;

          final List<String> altEgitimKitlesi = [];
          if (egitimKitlesi.value == educationAudienceMiddleSchoolValue) {
            altEgitimKitlesi.add(educationAudienceMiddleSchoolValue);
          } else if (egitimKitlesi.value == educationAudienceHighSchoolValue) {
            altEgitimKitlesi.add(educationAudienceHighSchoolValue);
          } else if (egitimKitlesi.value ==
              educationAudienceUndergraduateValue) {
            altEgitimKitlesi.addAll(lisansTuru);
          } else if (egitimKitlesi.value == educationAudienceAllValue) {
            altEgitimKitlesi.addAll([
              educationAudienceMiddleSchoolValue,
              educationAudienceHighSchoolValue,
            ]);
            altEgitimKitlesi.addAll(lisansTuru);
          }

          final String egitimKitlesiValue =
              egitimKitlesi.value == educationAudienceAllValue
                  ? educationAudienceAllExpandedValue
                  : egitimKitlesi.value;

          final scholarship = IndividualScholarshipsModel(
            aciklama: aciklama.value,
            shortDescription: '',
            altEgitimKitlesi: altEgitimKitlesi,
            aylar: aylar,
            basvurular: [],
            baslangicTarihi: baslangicTarihi.value,
            baslik: baslik.value,
            bursVeren: bursVeren.value,
            basvuruKosullari: basvuruKosullari.value,
            basvuruURL: basvuruURL.value,
            basvuruYapilacakYer: basvuruYapilacakYer.value,
            begeniler: [],
            belgeler: belgeler,
            bitisTarihi: bitisTarihi.value,
            egitimKitlesi: egitimKitlesiValue,
            geriOdemeli: geriOdemeli.value,
            goruntuleme: [],
            hedefKitle: hedefKitle.value,
            ilceler: ilceler,
            img: templateUrl.value,
            img2: customImageUrl ?? '',
            kaydedenler: [],
            kaydedilenler: [],
            liseOrtaOkulIlceler: [],
            liseOrtaOkulSehirler: [],
            logo: logoUrl ?? '',
            mukerrerDurumu: mukerrerDurumu.value,
            ogrenciSayisi: ogrenciSayisi.value,
            sehirler: sehirler,
            timeStamp: DateTime.now().millisecondsSinceEpoch,
            tutar: tutar.value,
            universiteler: universiteler,
            userID: _currentUid,
            website: website.value,
            lisansTuru: lisansTuru.join(','),
            template: template.value,
            ulke: ulke.value,
          );
          final authorFields = await _authorFieldsForCurrentUser();

          final docRef = await ScholarshipFirestorePath.collection(
            firestore: _firestore,
          ).add(<String, dynamic>{
            ...scholarship.toJson(),
            ...authorFields,
          });

          await ScholarshipFirestorePath.doc(
            docRef.id,
            firestore: _firestore,
          ).set(
              {'likesCount': 0, 'bookmarksCount': 0}, SetOptions(merge: true));

          // Refresh scholarships after successful save
          final scholarshipsController = ScholarshipsController.ensure();
          scholarshipsController.fetchScholarships();

          // After create: return to NavBarView (Education tab), then open ScholarshipsView
          try {
            // NavBar'a dön ve Education sekmesini seç
            Get.offAll(() => NavBarView());
            // Education sekmesi (varsayılan sıra: 0-Agenda,1-Explore,2-Shorts,3-Education,4-Profile)
            NavBarController.maybeFind()?.changeIndex(3);
          } catch (_) {}

          try {
            scholarshipsController.resetSearch();
          } catch (_) {}

          // Bursları Education sekmesi açıkken göster
          Get.to(() => ScholarshipsView());
          AppSnackbar('common.success'.tr, 'scholarship.published_success'.tr);

          resetForm();
        } catch (_) {
          AppSnackbar('common.error'.tr, 'scholarship.publish_failed'.tr);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateScholarship() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      if (formKey.currentState!.validate()) {
        try {
          // Şablon görüntüsünü yakala ve yükle
          if (selectedTemplateIndex.value != -1 &&
              templateKey.currentContext != null) {
            final templateUrlResult = await _captureAndUploadTemplate();
            if (templateUrlResult == null) {
              AppSnackbar(
                'common.error'.tr,
                'scholarship.template_capture_failed'.tr,
              );
              return;
            }
          }

          final String? customImageUrl = customImagePath.value.isNotEmpty &&
                  !customImagePath.value.startsWith('http')
              ? await _uploadImage(customImagePath.value)
              : customImagePath.value;
          final String? logoUrl =
              logoPath.value.isNotEmpty && !logoPath.value.startsWith('http')
                  ? await _uploadImage(logoPath.value, isLogo: true)
                  : logoPath.value;

          final List<String> altEgitimKitlesi = [];
          if (egitimKitlesi.value == educationAudienceMiddleSchoolValue) {
            altEgitimKitlesi.add(educationAudienceMiddleSchoolValue);
          } else if (egitimKitlesi.value == educationAudienceHighSchoolValue) {
            altEgitimKitlesi.add(educationAudienceHighSchoolValue);
          } else if (egitimKitlesi.value ==
              educationAudienceUndergraduateValue) {
            altEgitimKitlesi.addAll(lisansTuru);
          } else if (egitimKitlesi.value == educationAudienceAllValue) {
            altEgitimKitlesi.addAll([
              educationAudienceMiddleSchoolValue,
              educationAudienceHighSchoolValue,
            ]);
            altEgitimKitlesi.addAll(lisansTuru);
          }

          final String egitimKitlesiValue =
              egitimKitlesi.value == educationAudienceAllValue
                  ? educationAudienceAllExpandedValue
                  : egitimKitlesi.value;

          final scholarship = IndividualScholarshipsModel(
            aciklama: aciklama.value,
            shortDescription: '',
            altEgitimKitlesi: altEgitimKitlesi,
            aylar: aylar,
            basvurular: [],
            baslangicTarihi: baslangicTarihi.value,
            baslik: baslik.value,
            bursVeren: bursVeren.value,
            basvuruKosullari: basvuruKosullari.value,
            basvuruURL: basvuruURL.value,
            basvuruYapilacakYer: basvuruYapilacakYer.value,
            begeniler: [],
            belgeler: belgeler,
            bitisTarihi: bitisTarihi.value,
            egitimKitlesi: egitimKitlesiValue,
            geriOdemeli: geriOdemeli.value,
            goruntuleme: [],
            hedefKitle: hedefKitle.value,
            ilceler: ilceler,
            img: templateUrl.value,
            img2: customImageUrl ?? '',
            kaydedenler: [],
            kaydedilenler: [],
            liseOrtaOkulIlceler: [],
            liseOrtaOkulSehirler: [],
            logo: logoUrl ?? '',
            mukerrerDurumu: mukerrerDurumu.value,
            ogrenciSayisi: ogrenciSayisi.value,
            sehirler: sehirler,
            timeStamp: DateTime.now().millisecondsSinceEpoch,
            tutar: tutar.value,
            universiteler: universiteler,
            userID: _currentUid,
            website: website.value,
            lisansTuru: lisansTuru.join(','),
            template: template.value,
            ulke: ulke.value,
          );
          final authorFields = await _authorFieldsForCurrentUser();

          await ScholarshipFirestorePath.doc(
            scholarshipId.value,
            firestore: _firestore,
          ).update(<String, dynamic>{
            ...scholarship.toJson(),
            ...authorFields,
          });

          // Refresh scholarships after successful update
          final scholarshipsController = ScholarshipsController.ensure();
          scholarshipsController.fetchScholarships();

          // After update: return to NavBarView (Education tab), then open ScholarshipsView
          try {
            Get.offAll(() => NavBarView());
            NavBarController.maybeFind()?.changeIndex(3);
          } catch (_) {}

          try {
            scholarshipsController.resetSearch();
          } catch (_) {}
          Get.to(() => ScholarshipsView());
          AppSnackbar('common.success'.tr, 'scholarship.updated_success'.tr);

          resetForm();
        } catch (e) {
          AppSnackbar('common.error'.tr, 'scholarship.update_failed'.tr);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  void goToPreview() {
    if (formKey.currentState!.validate()) {
      final tag = controllerTag;
      if (tag == null || tag.isEmpty) return;
      Get.to(() => ScholarshipPreviewView(controllerTag: tag));
    }
  }
}
