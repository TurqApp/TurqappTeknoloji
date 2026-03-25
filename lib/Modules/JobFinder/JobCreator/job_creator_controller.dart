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
  }) =>
      maybeFind(tag: tag) ??
      Get.put(
        JobCreatorController(existingJob: existingJob),
        tag: tag,
        permanent: permanent,
      );

  static JobCreatorController? maybeFind({String? tag}) =>
      Get.isRegistered<JobCreatorController>(tag: tag)
          ? Get.find<JobCreatorController>(tag: tag)
          : null;

  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
  final selection = 0.obs, isSubmitting = false.obs;
  final brand = TextEditingController(),
      about = TextEditingController(),
      isTanimi = TextEditingController(),
      maas1 = TextEditingController(),
      maas2 = TextEditingController();

  final calismaSaatiBaslangic = TextEditingController(),
      calismaSaatiBitis = TextEditingController(),
      basvuruSayisi = TextEditingController(text: '0');
  final selectedCalismaTuruList = <String>[].obs,
      selectedCalismaGunleri = <String>[].obs,
      selectedYanHaklar = <String>[].obs;
  final _choices = _JobCreatorChoiceLists();
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;
  final meslek = ''.obs;
  final ilanBasligi = TextEditingController();
  final pozisyonSayisi = TextEditingController(text: '1');
  final sehir = ''.obs, ilce = ''.obs, adres = ''.obs;
  final lat = 0.0.obs, long = 0.0.obs, maasOpen = true.obs;
  final sehirler = <String>[].obs;

  final _mediaState = _JobCreatorMediaState();
  final _runtimeState = _JobCreatorRuntimeState();

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
