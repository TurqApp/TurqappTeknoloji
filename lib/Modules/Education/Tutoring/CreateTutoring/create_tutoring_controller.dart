import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:flutter/services.dart' show rootBundle;

class CreateTutoringController extends GetxController {
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

  /// Doğrulama belgeleri (diploma/sertifika dosya yolları)
  var verificationDocs = <String>[].obs;

  /// Şehir/ilçe değiştiğinde geocode ile lat/long hesapla.
  Future<void> _geocodeLocation() async {
    try {
      final query = town.isNotEmpty
          ? '$town, ${city.value}, Türkiye'
          : '${city.value}, Türkiye';
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        _lat = locations.first.latitude;
        _long = locations.first.longitude;
      }
    } catch (_) {
      _lat = null;
      _long = null;
    }
  }

  void addVerificationDoc(String filePath) {
    verificationDocs.add(filePath);
  }

  Future<List<String>> _uploadVerificationDocs() async {
    if (verificationDocs.isEmpty) return [];
    final urls = <String>[];
    final storage = firebase_storage.FirebaseStorage.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    for (final docPath in verificationDocs) {
      if (docPath.startsWith('http')) {
        urls.add(docPath);
        continue;
      }
      try {
        final downloadUrl = await WebpUploadService.uploadFileAsWebp(
          storage: storage,
          file: File(docPath),
          storagePathWithoutExt:
              'users/$userId/verification_${DateTime.now().millisecondsSinceEpoch}',
        );
        urls.add(downloadUrl);
      } catch (_) {
      }
    }
    return urls;
  }

  void toggleTimeSlot(String day, String slot) {
    final current = availability[day] ?? [];
    if (current.contains(slot)) {
      current.remove(slot);
    } else {
      current.add(slot);
    }
    if (current.isEmpty) {
      availability.remove(day);
    } else {
      availability[day] = current;
    }
    availability.refresh();
  }

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

  void showIlSec() {
    Get.bottomSheet(
      ListBottomSheet(
        list: sehirler,
        title: "Şehir Seç",
        startSelection: city.value,
        onBackData: (v) {
          city.value = v;
          cityController.text = v;
          town = "";
          districtController.text = "";
          _geocodeLocation();
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  void showIlcelerSec() {
    final List<String> ilceListesi = sehirlerVeIlcelerData
        .where((doc) => doc.il == city.value && city.value.isNotEmpty)
        .map((doc) => doc.ilce)
        .toList();

    Get.bottomSheet(
      ListBottomSheet(
        list: ilceListesi,
        title: "İlçe Seç",
        startSelection: town,
        onBackData: (v) {
          town = v;
          districtController.text = v;
          _geocodeLocation();
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  Future<void> loadSehirler() async {
    try {
      final String response = await DefaultAssetBundle.of(
        Get.context!,
      ).loadString('assets/data/CityDistrict.json');
      final List<dynamic> data = jsonDecode(response);
      sehirlerVeIlcelerData.value =
          data.map((json) => CitiesModel.fromJson(json)).toList();
      sehirler.value =
          sehirlerVeIlcelerData.map((item) => item.il).toSet().toList();
    } catch (_) {
    }
  }

  Future<List<String>> uploadImages() async {
    List<String> imageUrls = [];
    final storage = firebase_storage.FirebaseStorage.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Not: Storage’dan hiçbir veri silinmeyecek — eski görseller korunur

    final newLocalImages =
        images.where((path) => !path.startsWith('http')).toList();
    if (images.isEmpty &&
        selectedBranch.value.isNotEmpty &&
        newLocalImages.isEmpty) {
      final iconFileName = branchIconMap[selectedBranch.value];
      if (iconFileName != null) {
        final byteData = await rootBundle.load(
          'assets/tutorings/$iconFileName',
        );
        final tempDir = await Directory.systemTemp.createTemp();
        final tempFile = File('${tempDir.path}/$iconFileName');
        try {
          await tempFile.writeAsBytes(byteData.buffer.asUint8List());

          final downloadUrl = await WebpUploadService.uploadFileAsWebp(
            storage: storage,
            file: tempFile,
            storagePathWithoutExt:
                'users/$userId/${path.basenameWithoutExtension(iconFileName)}_${DateTime.now().millisecondsSinceEpoch}',
          );
          imageUrls.add(downloadUrl);
        } finally {
          try {
            if (await tempFile.exists()) await tempFile.delete();
            if (await tempDir.exists()) {
              await tempDir.delete(recursive: true);
            }
          } catch (_) {}
        }
      }
    } else {
      for (var imagePath in newLocalImages) {
        final localFile = File(imagePath);
        final nsfw = await OptimizedNSFWService.checkImage(localFile);
        if (nsfw.errorMessage != null) {
          AppSnackbar("Hata", "NSFW görsel kontrolü başarısız.");
          continue;
        }
        if (nsfw.isNSFW) {
          AppSnackbar("Hata", "Uygunsuz görsel tespit edildi.");
          continue;
        }
        final downloadUrl = await WebpUploadService.uploadFileAsWebp(
          storage: storage,
          file: localFile,
          storagePathWithoutExt:
              'users/$userId/${path.basenameWithoutExtension(imagePath)}_${DateTime.now().millisecondsSinceEpoch}',
        );
        imageUrls.add(downloadUrl);
      }
    }
    return imageUrls;
  }

  void saveTutoring() async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        branchController.text.isEmpty ||
        priceController.text.isEmpty ||
        selectedLessonPlace.value.isEmpty ||
        cityController.text.isEmpty ||
        selectedGender.value.isEmpty) {
      AppSnackbar("Hata", "Boş Alanları Doldurunuz!");
      return;
    }

    isLoading.value = true;
    try {
      final imageUrls = await uploadImages();
      final verDocUrls = await _uploadVerificationDocs();
      final tutoring = TutoringModel(
        docID: '',
        aciklama: descriptionController.text,
        baslik: titleController.text,
        brans: branchController.text,
        cinsiyet: selectedGender.value,
        dersYeri: [selectedLessonPlace.value],
        end: 0,
        favorites: [],
        fiyat: num.tryParse(priceController.text) ?? 0,
        imgs: imageUrls.isNotEmpty ? imageUrls : null,
        ilce: districtController.text,
        onayVerildi: false,
        sehir: cityController.text,
        telefon: isPhoneOpen.value,
        timeStamp: DateTime.now().millisecondsSinceEpoch,
        userID: FirebaseAuth.instance.currentUser?.uid ?? '',
        whatsapp: false,
        availability: availability.isNotEmpty
            ? Map<String, List<String>>.from(availability)
            : null,
        lat: _lat,
        long: _long,
        verificationDocs: verDocUrls.isNotEmpty ? verDocUrls : null,
      );

      await FirebaseFirestore.instance
          .collection('educators')
          .add(tutoring.toJson());
      Get.back();
      AppSnackbar("Başarılı", "Özel ders ilanı paylaşıldı!");
      clearForm();
    } catch (e) {
      AppSnackbar("Hata", "İlan paylaşılırken bir hata oluştu.");
    } finally {
      isLoading.value = false;
    }
  }

  void updateTutoring(String docId) async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        branchController.text.isEmpty ||
        priceController.text.isEmpty ||
        selectedLessonPlace.value.isEmpty ||
        cityController.text.isEmpty ||
        selectedGender.value.isEmpty) {
      AppSnackbar("Hata", "Boş Alanları Doldurunuz!");
      return;
    }

    isLoading.value = true;
    try {
      final initialData = Get.arguments as TutoringModel?;
      final updateData = <String, dynamic>{};

      // Only add fields to updateData if they have changed
      if (titleController.text != initialData?.baslik) {
        updateData['baslik'] = titleController.text;
      }
      if (descriptionController.text != initialData?.aciklama) {
        updateData['aciklama'] = descriptionController.text;
      }
      if (branchController.text != initialData?.brans) {
        updateData['brans'] = branchController.text;
      }
      if (num.tryParse(priceController.text) != initialData?.fiyat) {
        updateData['fiyat'] = num.tryParse(priceController.text) ?? 0;
      }
      if (selectedLessonPlace.value !=
          (initialData?.dersYeri.isNotEmpty ?? false
              ? initialData?.dersYeri[0]
              : '')) {
        updateData['dersYeri'] = [selectedLessonPlace.value];
      }
      if (cityController.text != initialData?.sehir) {
        updateData['sehir'] = cityController.text;
      }
      if (districtController.text != initialData?.ilce) {
        updateData['ilce'] = districtController.text;
      }
      if (selectedGender.value != initialData?.cinsiyet) {
        updateData['cinsiyet'] = selectedGender.value;
      }
      if (isPhoneOpen.value != initialData?.telefon) {
        updateData['telefon'] = isPhoneOpen.value;
      }

      // Availability
      if (availability.isNotEmpty) {
        updateData['availability'] =
            Map<String, List<String>>.from(availability);
      }

      // Lat/Long (şehir/ilçe değiştiyse geocode edilmiştir)
      if (_lat != null && _long != null) {
        updateData['lat'] = _lat;
        updateData['long'] = _long;
      }

      // Only update images if new images were added
      final newLocalImages =
          images.where((path) => !path.startsWith('http')).toList();
      if (newLocalImages.isNotEmpty) {
        final imageUrls = await uploadImages();
        updateData['imgs'] = imageUrls.isNotEmpty ? imageUrls : null;
      }

      if (updateData.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('educators')
            .doc(docId)
            .update(updateData);
        Get.back();
        AppSnackbar("Başarılı", "İlan güncellendi!");
        clearForm();
      } else {
        Get.back();
        AppSnackbar("Bilgi", "Değişiklik yapılmadı!");
      }
    } catch (_) {
      AppSnackbar("Hata", "İlan güncellenirken bir hata oluştu.");
    } finally {
      isLoading.value = false;
    }
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    branchController.clear();
    priceController.clear();
    cityController.clear();
    districtController.text = '';
    selectedLessonPlace.value = '';
    selectedGender.value = '';
    city.value = '';
    town = '';
    images.clear();
    isPhoneOpen.value = false;
    selectedBranch.value = '';
    availability.clear();
    verificationDocs.clear();
    _lat = null;
    _long = null;
  }
}
