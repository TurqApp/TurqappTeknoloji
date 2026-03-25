import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Utils/location_text_utils.dart';
import 'package:turqappv2/Core/Utils/turkish_sort.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/Helpers/GlobalLoader/global_loader_controller.dart';
import 'package:turqappv2/Core/job_categories.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/scheduler.dart';
import '../../../Core/BottomSheets/list_bottom_sheet.dart';
import '../../../Models/cities_model.dart';
import '../../../Models/job_model.dart';
import '../job_localization_utils.dart';

part 'job_creator_controller_form_part.dart';
part 'job_creator_controller_submission_part.dart';
part 'job_creator_controller_support_part.dart';
part 'job_creator_controller_runtime_part.dart';

class JobCreatorController extends GetxController {
  static JobCreatorController ensure({
    JobModel? existingJob,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      JobCreatorController(existingJob: existingJob),
      tag: tag,
      permanent: permanent,
    );
  }

  static JobCreatorController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<JobCreatorController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<JobCreatorController>(tag: tag);
  }

  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
  var selection = 0.obs;
  final isSubmitting = false.obs;
  TextEditingController brand = TextEditingController();
  TextEditingController about = TextEditingController();
  TextEditingController isTanimi = TextEditingController();
  TextEditingController maas1 = TextEditingController();
  TextEditingController maas2 = TextEditingController();

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  TextEditingController calismaSaatiBaslangic = TextEditingController();
  TextEditingController calismaSaatiBitis = TextEditingController();
  TextEditingController basvuruSayisi = TextEditingController(text: "0");
  List<String> calismaTuruList = [
    "Tam Zamanlı",
    "Yarı Zamanlı",
    "Part-Time",
    "Uzaktan",
    "Hibrit"
  ];
  List<String> calismaGunleriList = [
    "Pazartesi",
    "Salı",
    "Çarşamba",
    "Perşembe",
    "Cuma",
    "Cumartesi",
    "Pazar",
  ];
  List<String> yanHaklarList = [
    "Yemek",
    "Yol Ücreti",
    "Servis",
    "Prim",
    "Özel Sağlık Sigortası",
    "Bireysel Emeklilik",
    "Esnek Çalışma Saatleri",
    "Uzaktan Çalışma",
  ];

  RxList<String> selectedCalismaTuruList = <String>[].obs;
  RxList<String> selectedCalismaGunleri = <String>[].obs;
  RxList<String> selectedYanHaklar = <String>[].obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;
  var meslek = "".obs;
  TextEditingController ilanBasligi = TextEditingController();
  TextEditingController pozisyonSayisi = TextEditingController(text: "1");
  var sehir = "".obs;
  var ilce = "".obs;
  var adres = "".obs;
  var lat = 0.0.obs;
  var long = 0.0.obs;
  var maasOpen = true.obs;
  final sehirler = <String>[].obs;

  final CropController cropController = CropController();
  final ImagePicker picker = ImagePicker();
  final Rx<File?> selectedImage = Rx<File?>(null);
  final Rx<Uint8List?> croppedImage = Rx<Uint8List?>(null);
  final RxBool isCropping = false.obs;

  final String loaderTag = "job_creator_loader";
  final timeStamp = DateTime.now().millisecondsSinceEpoch;
  bool _ownsLoader = false;

  final JobModel? existingJob;
  JobCreatorController({this.existingJob});

  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }

  @override
  void onClose() {
    _JobCreatorControllerSupportX(this).handleOnClose();
    super.onClose();
  }
}
