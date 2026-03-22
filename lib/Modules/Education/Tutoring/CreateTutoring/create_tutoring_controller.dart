import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Utils/location_text_utils.dart';
import 'package:turqappv2/Core/Utils/turkish_sort.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/Services/user_moderation_guard.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Modules/Education/Tutoring/MyTutorings/my_tutorings_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringDetail/tutoring_detail_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:flutter/services.dart' show rootBundle;

part 'create_tutoring_controller_form_part.dart';
part 'create_tutoring_controller_submission_part.dart';

class CreateTutoringController extends GetxController {
  static CreateTutoringController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      CreateTutoringController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static CreateTutoringController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<CreateTutoringController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<CreateTutoringController>(tag: tag);
  }

  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
  var carouselCurrentIndex = 0.obs;
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final branchController = TextEditingController();
  final priceController = TextEditingController();
  final cityController = TextEditingController();
  final districtController = TextEditingController();
  var selectedLessonPlace = ''.obs;
  var selectedGender = ''.obs;
  var city = ''.obs;
  var town = '';
  final sehirler = <String>[].obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;
  var images = <String>[].obs;
  var isPhoneOpen = false.obs;
  var selectedBranch = ''.obs;
  var isLoading = false.obs;

  /// Müsaitlik takvimi: gün → saat aralıkları listesi
  final availability = <String, List<String>>{}.obs;

  static const List<String> weekDays = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  static const List<String> timeSlots = [
    '08:00-10:00',
    '10:00-12:00',
    '12:00-14:00',
    '14:00-16:00',
    '16:00-18:00',
    '18:00-20:00',
    '20:00-22:00',
  ];

  double? _lat;
  double? _long;

  final Map<String, String> branchIconMap = {
    'Yaz Okulu': '1.png',
    'Orta Öğretim': '2.png',
    'İlk Öğretim': '3.png',
    'Yabancı Dil': '4.png',
    'Yazılım': '5.png',
    'Direksiyon': '6.png',
    'Spor': '7.png',
    'Sanat': '8.png',
    'Müzik': '9.png',
    'Tiyatro': '10.png',
    'Kişisel Gelişim': '11.png',
    'Mesleki': '12.png',
    'Özel Eğitim': '13.png',
    'Çocuk': '14.png',
    'Diksiyon': '15.png',
    'Fotoğrafçılık': '16.png',
  };

  @override
  void onInit() {
    super.onInit();
    loadSehirler();
    ever(selectedBranch, (value) {
      branchController.text = value;
    });
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    branchController.dispose();
    priceController.dispose();
    cityController.dispose();
    districtController.dispose();
    super.onClose();
  }

  void addImage(String imagePath) {
    images.add(imagePath);
  }

  void togglePhoneOpen(bool value) {
    isPhoneOpen.value = value;
  }
}
