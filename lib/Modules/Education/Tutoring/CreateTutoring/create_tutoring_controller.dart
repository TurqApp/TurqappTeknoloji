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
    if (!Get.isRegistered<CreateTutoringController>(tag: tag)) return null;
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

  /// Şehir/ilçe değiştiğinde geocode ile lat/long hesapla.
  Future<void> _geocodeLocation() async {
    try {
      final query = town.isNotEmpty
          ? '$town, ${city.value}, ${'common.country_turkey'.tr}'
          : '${city.value}, ${'common.country_turkey'.tr}';
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
    ListBottomSheet.show(
      context: Get.context!,
      items: sehirler,
      title: 'tutoring.create.city_select'.tr,
      selectedItem: city.value,
      onSelect: (v) {
        city.value = v.toString();
        cityController.text = v.toString();
        town = "";
        districtController.text = "";
        _geocodeLocation();
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
      title: 'tutoring.create.district_select'.tr,
      selectedItem: town,
      onSelect: (v) {
        town = v.toString();
        districtController.text = v.toString();
        _geocodeLocation();
      },
    );
  }

  Future<void> loadSehirler() async {
    try {
      sehirlerVeIlcelerData.value =
          await _cityDirectoryService.getCitiesAndDistricts();
      sehirler.value = await _cityDirectoryService.getSortedCities();
      await autoFillLocationIfNeeded(allowPermissionPrompt: !Platform.isIOS);
    } catch (_) {}
  }

  Future<void> autoFillLocationIfNeeded({
    bool allowPermissionPrompt = true,
  }) async {
    try {
      if (city.value.isNotEmpty && town.isNotEmpty) {
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!allowPermissionPrompt) {
          return;
        }
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return;
        }
      }

      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) {
        return;
      }

      final place = placemarks.first;
      final cityCandidates = <String>[
        (place.administrativeArea ?? '').trim(),
        (place.locality ?? '').trim(),
      ];
      final districtCandidates = <String>[
        (place.subAdministrativeArea ?? '').trim(),
        (place.subLocality ?? '').trim(),
        (place.locality ?? '').trim(),
      ];

      final matchedCity = _matchCity(cityCandidates);
      if (matchedCity != null) {
        city.value = matchedCity;
        cityController.text = matchedCity;
        final matchedDistrict = _matchDistrict(matchedCity, districtCandidates);
        if (matchedDistrict != null) {
          town = matchedDistrict;
          districtController.text = matchedDistrict;
        }
      }

      _lat = position.latitude;
      _long = position.longitude;
    } catch (_) {}
  }

  String? _matchCity(List<String> candidates) {
    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;
      final exact = sehirler.firstWhereOrNull((item) => item == candidate);
      if (exact != null) return exact;
      final normalizedCandidate = normalizeLocationText(candidate);
      final fuzzy = sehirler.firstWhereOrNull(
        (item) => normalizeLocationText(item) == normalizedCandidate,
      );
      if (fuzzy != null) return fuzzy;
    }
    return null;
  }

  String? _matchDistrict(String matchedCity, List<String> candidates) {
    final districts = sehirlerVeIlcelerData
        .where((item) => item.il == matchedCity)
        .map((item) => item.ilce)
        .toSet()
        .toList();
    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;
      final exact = districts.firstWhereOrNull((item) => item == candidate);
      if (exact != null) return exact;
      final normalizedCandidate = normalizeLocationText(candidate);
      final fuzzy = districts.firstWhereOrNull(
        (item) => normalizeLocationText(item) == normalizedCandidate,
      );
      if (fuzzy != null) return fuzzy;
    }
    return null;
  }

  Future<List<String>> uploadImages() async {
    List<String> imageUrls = [];
    final storage = firebase_storage.FirebaseStorage.instance;
    final userId = CurrentUserService.instance.userId;
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
          AppSnackbar(
            'common.error'.tr,
            'tutoring.create.nsfw_check_failed'.tr,
          );
          continue;
        }
        if (nsfw.isNSFW) {
          AppSnackbar(
            'common.error'.tr,
            'tutoring.create.nsfw_detected'.tr,
          );
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

  Map<String, String> _profileFields() {
    final current = CurrentUserService.instance.currentUser;
    final nickname =
        (current?.nickname ?? CurrentUserService.instance.nickname).trim();
    final fullName =
        (current?.fullName ?? CurrentUserService.instance.fullName).trim();
    final displayName = fullName.isNotEmpty ? fullName : nickname;
    return {
      'nickname': nickname,
      'displayName': displayName,
      'avatarUrl': CurrentUserService.instance.avatarUrl.trim(),
      'rozet': (current?.rozet ?? '').trim(),
    };
  }

  Future<void> saveTutoring() async {
    if (!UserModerationGuard.ensureAllowed(RestrictedAction.publishTutoring)) {
      return;
    }
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      if (titleController.text.isEmpty ||
          descriptionController.text.isEmpty ||
          branchController.text.isEmpty ||
          priceController.text.isEmpty ||
          selectedLessonPlace.value.isEmpty ||
          cityController.text.isEmpty ||
          selectedGender.value.isEmpty) {
        AppSnackbar('common.error'.tr, 'tutoring.create.fill_required'.tr);
        return;
      }

      final imageUrls = await uploadImages();
      final profile = _profileFields();
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
        userID: CurrentUserService.instance.userId,
        whatsapp: false,
        availability: availability.isNotEmpty
            ? Map<String, List<String>>.from(availability)
            : null,
        lat: _lat,
        long: _long,
        avatarUrl: profile['avatarUrl'] ?? '',
        displayName: profile['displayName'] ?? '',
        nickname: profile['nickname'] ?? '',
        rozet: profile['rozet'] ?? '',
      );

      final docRef = FirebaseFirestore.instance.collection('educators').doc();
      await docRef.set(tutoring.toJson());
      Get.back();
      AppSnackbar('common.success'.tr, 'tutoring.create.published'.tr);
      clearForm();
    } catch (e) {
      AppSnackbar('common.error'.tr, 'tutoring.create.publish_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateTutoring(String docId) async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      if (titleController.text.isEmpty ||
          descriptionController.text.isEmpty ||
          branchController.text.isEmpty ||
          priceController.text.isEmpty ||
          selectedLessonPlace.value.isEmpty ||
          cityController.text.isEmpty ||
          selectedGender.value.isEmpty) {
        AppSnackbar('common.error'.tr, 'tutoring.create.fill_required'.tr);
        return;
      }

      final initialData = Get.arguments as TutoringModel?;
      final updateData = <String, dynamic>{};
      final profile = _profileFields();

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
      if ((profile['avatarUrl'] ?? '') != initialData?.avatarUrl) {
        updateData['avatarUrl'] = profile['avatarUrl'];
      }
      if ((profile['displayName'] ?? '') != initialData?.displayName) {
        updateData['displayName'] = profile['displayName'];
      }
      if ((profile['nickname'] ?? '') != initialData?.nickname) {
        updateData['nickname'] = profile['nickname'];
      }
      if ((profile['rozet'] ?? '') != initialData?.rozet) {
        updateData['rozet'] = profile['rozet'];
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
        final patchedModel = _buildPatchedModel(
          initialData: initialData,
          docId: docId,
          updateData: updateData,
        );
        if (patchedModel != null) {
          _applyLocalTutoringPatch(patchedModel);
        }
        Get.back();
        AppSnackbar('common.success'.tr, 'tutoring.create.updated'.tr);
        clearForm();
      } else {
        Get.back();
        AppSnackbar('common.info'.tr, 'tutoring.create.no_changes'.tr);
      }
    } catch (_) {
      AppSnackbar('common.error'.tr, 'tutoring.create.update_failed'.tr);
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
    _lat = null;
    _long = null;
  }

  TutoringModel? _buildPatchedModel({
    required TutoringModel? initialData,
    required String docId,
    required Map<String, dynamic> updateData,
  }) {
    final base = initialData;
    if (base == null) return null;
    return base.copyWith(
      docID: docId,
      baslik: (updateData['baslik'] ?? base.baslik).toString(),
      aciklama: (updateData['aciklama'] ?? base.aciklama).toString(),
      brans: (updateData['brans'] ?? base.brans).toString(),
      fiyat: (updateData['fiyat'] as num?) ?? base.fiyat,
      dersYeri: (updateData['dersYeri'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          base.dersYeri,
      sehir: (updateData['sehir'] ?? base.sehir).toString(),
      ilce: (updateData['ilce'] ?? base.ilce).toString(),
      cinsiyet: (updateData['cinsiyet'] ?? base.cinsiyet).toString(),
      telefon: (updateData['telefon'] as bool?) ?? base.telefon,
      avatarUrl: (updateData['avatarUrl'] ?? base.avatarUrl).toString(),
      displayName: (updateData['displayName'] ?? base.displayName).toString(),
      nickname: (updateData['nickname'] ?? base.nickname).toString(),
      rozet: (updateData['rozet'] ?? base.rozet).toString(),
      availability:
          (updateData['availability'] as Map<String, List<String>>?) ??
              base.availability,
      lat: (updateData['lat'] as double?) ?? base.lat,
      long: (updateData['long'] as double?) ?? base.long,
      imgs: (updateData['imgs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          base.imgs,
    );
  }

  void _applyLocalTutoringPatch(TutoringModel patchedModel) {
    final controller = TutoringController.maybeFind();
    if (controller != null) {
      final homeIndex = controller.tutoringList.indexWhere(
        (item) => item.docID == patchedModel.docID,
      );
      if (homeIndex != -1) {
        controller.tutoringList[homeIndex] = patchedModel;
        controller.tutoringList.refresh();
      }
      final searchIndex = controller.searchResults.indexWhere(
        (item) => item.docID == patchedModel.docID,
      );
      if (searchIndex != -1) {
        controller.searchResults[searchIndex] = patchedModel;
        controller.searchResults.refresh();
      }
    }

    final myTutoringsController = MyTutoringsController.maybeFind();
    if (myTutoringsController != null) {
      final ownerIndex = myTutoringsController.myTutorings.indexWhere(
        (item) => item.docID == patchedModel.docID,
      );
      if (ownerIndex != -1) {
        myTutoringsController.myTutorings[ownerIndex] = patchedModel;
        myTutoringsController.myTutorings.refresh();
        myTutoringsController.updateTutoringsStatus();
      }
    }

    final tutoringDetailController = TutoringDetailController.maybeFind();
    if (tutoringDetailController != null) {
      if (tutoringDetailController.tutoring.value.docID == patchedModel.docID) {
        tutoringDetailController.tutoring.value = patchedModel;
      }
    }
  }
}
