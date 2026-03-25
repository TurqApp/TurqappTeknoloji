import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
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

part 'create_scholarship_controller_form_part.dart';
part 'create_scholarship_controller_submission_part.dart';
part 'create_scholarship_controller_labels_part.dart';
part 'create_scholarship_controller_support_part.dart';

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
  final bursKosullari = List<String>.of(_defaultScholarshipConditions).obs;
  final gerekliBelgeler = List<String>.of(_defaultScholarshipRequiredDocuments);
  final bursVerilecekAylar = List<String>.of(_defaultScholarshipAwardMonths);

  final iller = <String>[].obs;
  final ilIlceMap = <String, List<String>>{}.obs;
  final universiteMap = <String, List<String>>{}.obs;
  final tumUniversiteler = <String>[].obs;
  final higherEducationData = <dynamic>[].obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseStorage _storage = FirebaseStorage.instance;

  final GlobalKey templateKey = GlobalKey();
  String? controllerTag;

  @override
  void onInit() {
    super.onInit();
    initializeFormState();
  }
}
