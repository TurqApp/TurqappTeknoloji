import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class JobCreatorController extends GetxController {
  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
  var selection = 0.obs;
  final isSubmitting = false.obs;
  TextEditingController brand = TextEditingController();
  TextEditingController about = TextEditingController();
  TextEditingController isTanimi = TextEditingController();
  TextEditingController maas1 = TextEditingController();
  TextEditingController maas2 = TextEditingController();
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

  final JobModel? existingJob;
  JobCreatorController({this.existingJob});

  int parseMoneyInput(String value) {
    return int.tryParse(value.replaceAll('.', '').trim()) ?? 0;
  }

  String _formatMoneyInput(int value) {
    final raw = value.toString();
    final reversed = raw.split('').reversed.join();
    final chunks = <String>[];
    for (var i = 0; i < reversed.length; i += 3) {
      final end = (i + 3 < reversed.length) ? i + 3 : reversed.length;
      chunks.add(reversed.substring(i, end));
    }
    return chunks
        .map((chunk) => chunk.split('').reversed.join())
        .toList()
        .reversed
        .join('.');
  }

  @override
  void onInit() {
    super.onInit();
    if (!Get.isRegistered<GlobalLoaderController>(tag: loaderTag)) {
      Get.put(GlobalLoaderController(), tag: loaderTag);
    }

    if (existingJob != null) {
      brand.text = existingJob!.brand;
      about.text = existingJob!.about;
      isTanimi.text = existingJob!.isTanimi;
      maas1.text =
          existingJob!.maas1 > 0 ? _formatMoneyInput(existingJob!.maas1) : '';
      maas2.text =
          existingJob!.maas2 > 0 ? _formatMoneyInput(existingJob!.maas2) : '';
      calismaSaatiBaslangic.text = existingJob!.calismaSaatiBaslangic;
      calismaSaatiBitis.text = existingJob!.calismaSaatiBitis;
      meslek.value = existingJob!.meslek;
      sehir.value = existingJob!.city;
      ilce.value = existingJob!.town;
      adres.value = existingJob!.adres;
      lat.value = existingJob!.lat;
      long.value = existingJob!.long;
      selectedCalismaTuruList.value =
          existingJob!.calismaTuru.cast<String>().toList();
      selectedCalismaGunleri.value =
          existingJob!.calismaGunleri.cast<String>().toList();
      selectedYanHaklar.value = existingJob!.yanHaklar.cast<String>().toList();
      ilanBasligi.text = existingJob!.ilanBasligi;
      basvuruSayisi.text = existingJob!.applicationCount.toString();
      pozisyonSayisi.text = existingJob!.pozisyonSayisi.toString();
    } else {
      selectedCalismaGunleri.assignAll(
        calismaGunleriList.take(5).toList(growable: false),
      );
    }

    loadSehirler();

    if (existingJob == null || (lat.value == 0 && long.value == 0)) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Future.delayed(
          const Duration(milliseconds: 250),
          () =>
              autoFillLocationIfNeeded(allowPermissionPrompt: !Platform.isIOS),
        );
      });
    }
  }

  Future<void> pickImage({required ImageSource source}) async {
    File? file;
    if (source == ImageSource.gallery) {
      final ctx = Get.context;
      if (ctx == null) return;
      file = await AppImagePickerService.pickSingleImage(ctx);
    } else {
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) file = File(picked.path);
    }
    if (file == null) return;
    selectedImage.value = file;
    showCropDialog();
  }

  Future<void> showCropDialog() async {
    Get.dialog(
      Obx(() {
        if (selectedImage.value == null) return SizedBox.shrink();

        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.black,
          child: Column(
            children: [
              Expanded(
                child: Crop(
                  aspectRatio: 1,
                  image: selectedImage.value!.readAsBytesSync(),
                  controller: cropController,
                  onCropped: (result) {
                    if (result is CropSuccess) {
                      croppedImage.value =
                          result.croppedImage; // sadece preview için
                      selectedImage.value = null;
                      Get.back(); // Kırpma ekranını kapat
                    }
                  },
                  initialRectBuilder:
                      InitialRectBuilder.withSizeAndRatio(size: 0.8),
                  baseColor: Colors.black,
                  maskColor: Colors.black.withValues(alpha: 0.6),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    cropController.crop();
                  },
                  child: Text("Kırp ve Kullan"),
                ),
              )
            ],
          ),
        );
      }),
      barrierDismissible: false,
    );
  }

  Future<void> selectCalismaTuru() async {
    Get.bottomSheet(
      Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "Çalışma Türü",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 12,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: calismaTuruList.map((item) {
                  return Obx(() => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextButton(
                          style: ButtonStyle(
                            padding: WidgetStateProperty.all<EdgeInsets>(
                                EdgeInsets.zero),
                            minimumSize:
                                WidgetStateProperty.all<Size>(Size.zero),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            overlayColor: WidgetStateProperty.all(
                                Colors.transparent), // isteğe bağlı
                          ),
                          onPressed: () {
                            if (selectedCalismaTuruList.contains(item)) {
                              selectedCalismaTuruList.remove(item);
                            } else {
                              selectedCalismaTuruList.add(item);
                            }
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium",
                                  ),
                                ),
                              ),
                              Container(
                                width: 25,
                                height: 25,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(4)),
                                    color:
                                        selectedCalismaTuruList.contains(item)
                                            ? Colors.black
                                            : Colors.transparent,
                                    border: Border.all(color: Colors.black)),
                                child: Icon(
                                  CupertinoIcons.checkmark,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              )
                            ],
                          ),
                        ),
                      ));
                }).toList(),
              ),
              SizedBox(height: 12),
            ],
          )),
      isScrollControlled: true,
    );
  }

  Future<void> selectYanHaklar(BuildContext context) async {
    Get.bottomSheet(
      Container(
        height: Get.height / 2,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ek İmkanlar",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: "MontserratBold",
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: yanHaklarList.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final item = yanHaklarList[index];
                  return Obx(() {
                    final isSelected = selectedYanHaklar.contains(item);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextButton(
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all<EdgeInsets>(
                              EdgeInsets.zero),
                          minimumSize: WidgetStateProperty.all<Size>(Size.zero),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          overlayColor:
                              WidgetStateProperty.all(Colors.transparent),
                        ),
                        onPressed: () {
                          if (isSelected) {
                            selectedYanHaklar.remove(item);
                          } else {
                            selectedYanHaklar.add(item);
                          }
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                            ),
                            Container(
                              width: 25,
                              height: 25,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(4)),
                                color: isSelected
                                    ? Colors.black
                                    : Colors.transparent,
                                border: Border.all(color: Colors.black),
                              ),
                              child: Icon(
                                CupertinoIcons.checkmark,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
      isScrollControlled: true,
    ).then((_) {
      closeKeyboard(context);
    });
  }

  Future<void> selectCalismaGunleri() async {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Çalışma Günleri",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: "MontserratBold",
              ),
            ),
            SizedBox(height: 12),
            ...calismaGunleriList.map((item) {
              return Obx(() => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextButton(
                      style: ButtonStyle(
                        padding: WidgetStateProperty.all<EdgeInsets>(
                            EdgeInsets.zero),
                        minimumSize: WidgetStateProperty.all<Size>(Size.zero),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        overlayColor:
                            WidgetStateProperty.all(Colors.transparent),
                      ),
                      onPressed: () {
                        if (selectedCalismaGunleri.contains(item)) {
                          selectedCalismaGunleri.remove(item);
                        } else {
                          selectedCalismaGunleri.add(item);
                        }
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                          Container(
                            width: 25,
                            height: 25,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(4)),
                              color: selectedCalismaGunleri.contains(item)
                                  ? Colors.black
                                  : Colors.transparent,
                              border: Border.all(color: Colors.black),
                            ),
                            child: const Icon(
                              CupertinoIcons.checkmark,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ));
            }),
            SizedBox(height: 12),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> showMeslekSelector() async {
    Get.bottomSheet(
      SizedBox(
        height: Get.height / 2,
        child: ListBottomSheet(
          list: allJobs,
          title: "Meslek",
          startSelection: meslek.value,
          onBackData: (v) {
            meslek.value = v;
          },
        ),
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
      sehirlerVeIlcelerData.value =
          await _cityDirectoryService.getCitiesAndDistricts();
      sehirler.value = await _cityDirectoryService.getSortedCities();
    } catch (_) {}
  }

  Future<void> showSehirSelect() async {
    Get.bottomSheet(
      SizedBox(
        height: Get.height / 2,
        child: ListBottomSheet(
          list: sehirler,
          title: "Şehir Seç",
          startSelection: sehir.value,
          onBackData: (v) {
            sehir.value = v;
          },
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  Future<void> showIlceSelect() async {
    final districts = sehirlerVeIlcelerData
        .where((val) => val.il == sehir.value)
        .map((e) => e.ilce)
        .toSet()
        .toList()
        .cast<String>();
    sortTurkishStrings(districts);
    Get.bottomSheet(
      SizedBox(
        height: Get.height / 2,
        child: ListBottomSheet(
          list: districts,
          title: "İlçe Seç",
          startSelection: ilce.value,
          onBackData: (v) {
            ilce.value = v;
          },
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  Future<void> autoFillLocationIfNeeded({
    bool allowPermissionPrompt = true,
  }) async {
    try {
      if (sehir.value.isNotEmpty && ilce.value.isNotEmpty) {
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
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

      if (placemarks.isNotEmpty) {
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
          sehir.value = matchedCity;
          final matchedDistrict =
              _matchDistrict(matchedCity, districtCandidates);
          if (matchedDistrict != null) {
            ilce.value = matchedDistrict;
          }
        }
        lat.value = position.latitude.toDouble();
        long.value = position.longitude.toDouble();
        adres.value = [
          place.street,
          place.name,
          place.subLocality,
          place.subAdministrativeArea,
          place.administrativeArea,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      }
    } catch (_) {}
  }

  String? _matchCity(List<String> candidates) {
    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;
      final exact = sehirler.firstWhereOrNull((city) => city == candidate);
      if (exact != null) return exact;
      final normalizedCandidate = _normalizeLocation(candidate);
      final fuzzy = sehirler.firstWhereOrNull(
        (city) => _normalizeLocation(city) == normalizedCandidate,
      );
      if (fuzzy != null) return fuzzy;
    }
    return null;
  }

  String? _matchDistrict(String city, List<String> candidates) {
    final districts = sehirlerVeIlcelerData
        .where((item) => item.il == city)
        .map((item) => item.ilce)
        .toSet()
        .toList()
        .cast<String>();
    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;
      final exact =
          districts.firstWhereOrNull((district) => district == candidate);
      if (exact != null) return exact;
      final normalizedCandidate = _normalizeLocation(candidate);
      final fuzzy = districts.firstWhereOrNull(
        (district) => _normalizeLocation(district) == normalizedCandidate,
      );
      if (fuzzy != null) return fuzzy;
    }
    return null;
  }

  String _normalizeLocation(String value) {
    return value
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('i̇', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .trim();
  }

  Future<void> uploadCroppedImageToFirebase(String docID) async {
    final bytes = croppedImage.value;
    if (bytes == null) return;

    final tempDir = await Directory.systemTemp.createTemp('job_logo_');
    final tempFile = File('${tempDir.path}/logo_check.webp');
    try {
      await tempFile.writeAsBytes(bytes, flush: true);
      final nsfw = await OptimizedNSFWService.checkImage(tempFile);
      if (nsfw.errorMessage != null) {
        throw Exception('Görsel güvenlik kontrolü tamamlanamadı');
      }
      if (nsfw.isNSFW) {
        throw Exception('Uygunsuz görsel tespit edildi');
      }

      final downloadUrl = await WebpUploadService.uploadBytesAsWebp(
        storage: FirebaseStorage.instance,
        bytes: bytes,
        storagePathWithoutExt: "isBul/$docID/logo",
      );

      await FirebaseFirestore.instance
          .collection("isBul")
          .doc(docID)
          .set({"logo": downloadUrl}, SetOptions(merge: true));
    } finally {
      try {
        if (await tempFile.exists()) await tempFile.delete();
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  }

  Future<void> setData() async {
    if (isSubmitting.value) return;
    final docID =
        existingJob?.docID ?? Uuid().v4(); // düzenleme veya yeni kayıt
    final loader = Get.find<GlobalLoaderController>(tag: loaderTag);
    isSubmitting.value = true;
    loader.isOn.value = true;
    try {
      final current = CurrentUserService.instance.currentUser;
      final nickname = (current?.nickname ?? '').trim();
      final fullName = [
        current?.firstName ?? '',
        current?.lastName ?? '',
      ].where((part) => part.trim().isNotEmpty).join(' ').trim();
      final displayName = fullName.isEmpty ? nickname : fullName;
      final avatarUrl = (current?.avatarUrl ?? '').trim();
      final rozet = (current?.rozet ?? '').trim();

      final jobData = <String, dynamic>{
        "about": about.text,
        "adres": adres.value,
        "avatarUrl": avatarUrl,
        "brand": brand.text,
        "calismaGunleri": selectedCalismaGunleri.toList(),
        "calismaSaatiBaslangic": calismaSaatiBaslangic.text.trim(),
        "calismaSaatiBitis": calismaSaatiBitis.text.trim(),
        "calismaTuru": selectedCalismaTuruList.toList(),
        "city": sehir.value,
        "displayName": displayName,
        "town": ilce.value,
        "ended": false,
        "isTanimi": isTanimi.text,
        "lat": lat.value,
        "long": long.value,
        "logo": existingJob?.logo ?? "",
        "maas1": maasOpen.value ? parseMoneyInput(maas1.text) : 0,
        "maas2": maasOpen.value ? parseMoneyInput(maas2.text) : 0,
        "meslek": meslek.value,
        "nickname": nickname,
        "authorAvatarUrl": avatarUrl,
        "authorDisplayName": displayName,
        "authorNickname": nickname,
        "userID": FirebaseAuth.instance.currentUser?.uid ?? '',
        "rozet": rozet,
        "yanHaklar": selectedYanHaklar.toList(),
        "ilanBasligi": ilanBasligi.text,
        "basvuruSayisi": int.tryParse(basvuruSayisi.text) ?? 0,
        "pozisyonSayisi": int.tryParse(pozisyonSayisi.text) ?? 1,
      };

      if (existingJob != null) {
        jobData["timeStamp"] = DateTime.now().millisecondsSinceEpoch;
        await FirebaseFirestore.instance
            .collection("isBul")
            .doc(docID)
            .update(jobData);
      } else {
        jobData["timeStamp"] = DateTime.now().millisecondsSinceEpoch;
        jobData["viewCount"] = 0;
        jobData["applicationCount"] = 0;
        await FirebaseFirestore.instance
            .collection("isBul")
            .doc(docID)
            .set(jobData);
      }

      selection.value = 0;
      final shouldUploadLogo = croppedImage.value != null;
      if (shouldUploadLogo) {
        try {
          await uploadCroppedImageToFirebase(docID);
        } catch (e) {
          AppSnackbar('Hata', e.toString().replaceFirst('Exception: ', ''));
          return;
        }
      }
      loader.isOn.value = false;
      isSubmitting.value = false;
      Get.back();
    } finally {
      if (loader.isOn.value) {
        loader.isOn.value = false;
      }
      if (isSubmitting.value) {
        isSubmitting.value = false;
      }
    }
  }
}
