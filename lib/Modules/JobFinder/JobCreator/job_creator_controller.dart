import 'dart:convert';
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
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/Helpers/GlobalLoader/global_loader_controller.dart';
import 'package:turqappv2/Core/job_categories.dart';
import 'package:uuid/uuid.dart';
import '../../../Core/BottomSheets/list_bottom_sheet.dart';
import '../../../Models/cities_model.dart';
import '../../../Models/job_model.dart';

class JobCreatorController extends GetxController {
  var selection = 0.obs;
  TextEditingController brand = TextEditingController();
  TextEditingController about = TextEditingController();
  TextEditingController isTanimi = TextEditingController();
  TextEditingController maas1 = TextEditingController();
  TextEditingController maas2 = TextEditingController();
  List<String> calismaTuruList = [
    "Tam Zamanlı",
    "Yarı Zamanlı",
    "Part-Time",
    "Uzaktan",
    "Hibrit"
  ];
  List<String> yanHaklarList = [
    "Prim Sistemi",
    "Yemek",
    "Yol Ücreti",
    "Servis",
    "Personel İndirimi",
    "Özel Sağlık Sigortası",
    "Bireysel Emeklilik",
    "Esnek Çalışma Saatleri",
    "Uzaktan Çalışma İmkanı",
    "Şirket Aracı",
    "Şirket Hattı / Telefonu",
    "Şirket Bilgisayarı",
    "Doğum Günü İzni",
    "Evlilik İzni",
    "Yıllık Bonus",
    "Performans Bonusu",
    "Kariyer Eğitimleri",
    "Yabancı Dil Eğitimi",
    "Spor Salonu Üyeliği",
    "Etkinlik ve Sosyal Faaliyetler",
    "Çocuk Yardımı",
    "Bayram Harçlığı / Bayram Yardımı",
    "Kıyafet Desteği",
    "İkramiye",
  ];

  RxList<String> selectedCalismaTuruList = <String>[].obs;
  RxList<String> selectedYanHaklar = <String>[].obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;
  var meslek = "".obs;
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
  GoogleMapController? mapController;

  final String loaderTag = "job_creator_loader";
  final timeStamp = DateTime.now().millisecondsSinceEpoch;

  final JobModel? existingJob;
  JobCreatorController({this.existingJob});

  @override
  void onInit() {
    super.onInit();
    if (!Get.isRegistered<GlobalLoaderController>(tag: loaderTag)) {
      Get.put(GlobalLoaderController(), tag: loaderTag);
    }

    if (existingJob != null) {
      print("${existingJob!.about}aboutaboutaboutaboutaboutaboutabout");
      brand.text = existingJob!.brand;
      about.text = existingJob!.about;
      isTanimi.text = existingJob!.isTanimi;
      maas1.text = existingJob!.maas1.toString();
      maas2.text = existingJob!.maas2.toString();
      meslek.value = existingJob!.meslek;
      sehir.value = existingJob!.city;
      ilce.value = existingJob!.town;
      adres.value = existingJob!.adres;
      lat.value = existingJob!.lat;
      long.value = existingJob!.long;
      selectedCalismaTuruList.value =
          existingJob!.calismaTuru.cast<String>().toList();
      selectedYanHaklar.value = existingJob!.yanHaklar.cast<String>().toList();
    }

    loadSehirler();

    everAll([lat, long], (_) {
      moveCameraToPosition();
    });
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void moveCameraToPosition() {
    if (mapController != null && lat.value != 0 && long.value != 0) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(lat.value, long.value),
            zoom: 15,
          ),
        ),
      );
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
                    "Çalışma Türü Seç",
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
                                    color:
                                        selectedCalismaTuruList.contains(item)
                                            ? Colors.pinkAccent
                                            : Colors.black,
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
              "Yan Hak Seç",
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
                                  color: isSelected
                                      ? Colors.pinkAccent
                                      : Colors.black,
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

  Future<void> showMeslekSelector() async {
    Get.bottomSheet(
      ListBottomSheet(
        list: allJobs,
        title: "Meslek Seç",
        startSelection: meslek.value,
        onBackData: (v) {
          meslek.value = v;
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
      final String response = await rootBundle.loadString(
        'assets/data/CityDistrict.json',
      );
      final List<dynamic> data = json.decode(response);
      sehirlerVeIlcelerData.value =
          data.map((json) => CitiesModel.fromJson(json)).toList();
      sehirler.value =
          sehirlerVeIlcelerData.map((item) => item.il).toSet().toList();
    } catch (e) {
      print("Error loading cities: $e");
    }
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
    Get.bottomSheet(
      SizedBox(
        height: Get.height / 2,
        child: ListBottomSheet(
          list: sehirlerVeIlcelerData
              .where((val) => val.il == sehir.value)
              .map((e) => e.ilce)
              .toSet()
              .toList(),
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

  Future<void> getKonumVeAdres() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("Konum servisleri kapalı.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          print("Konum izni reddedildi.");
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        sehir.value = place.administrativeArea ?? "";
        ilce.value = place.subAdministrativeArea ?? "";
        lat.value = position.latitude.toDouble();
        long.value = position.longitude.toDouble();
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(lat.value, long.value),
              zoom: 15,
            ),
          ),
        );
        refresh();
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;

          adres.value = [
            place.street, // Sokak adı (örneğin: Atatürk Caddesi)
            place.name, // Bina adı veya ekstra detay
            place.subLocality, // Mahalle / semt
            place.subAdministrativeArea, // İlçe
            place.administrativeArea, // İl
            place.country // Ülke
          ].where((e) => e != null && e.isNotEmpty).join(', ');

          print("Tam Adres: ${adres.value}");
        }
      } else {
        print("Adres bulunamadı.");
      }
    } catch (e) {
      print("Konum alma hatası: $e");
    }
  }

  Future<void> uploadCroppedImageToFirebase(String docID) async {
    final loader = Get.find<GlobalLoaderController>(tag: loaderTag);
    try {
      final bytes = croppedImage.value;
      if (bytes == null) {
        print("Kırpılmış görsel bulunamadı.");
        return;
      }

      final String fileName = const Uuid().v4();

      final ref = FirebaseStorage.instance
          .ref()
          .child(FirebaseAuth.instance.currentUser!.uid)
          .child("IsBul")
          .child(docID)
          .child('$fileName.jpg');

      UploadTask uploadTask =
          ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      print("Yüklenen görsel URL: $downloadUrl");

      await FirebaseFirestore.instance
          .collection("IsBul")
          .doc(docID)
          .set({"logo": downloadUrl}, SetOptions(merge: true));

      Future.delayed(Duration(seconds: 2));
      loader.isOn.value = false;
    } catch (e) {
      print("Yükleme hatası: $e");
    }
  }

  Future<void> setData() async {
    final docID =
        existingJob?.docID ?? Uuid().v4(); // düzenleme veya yeni kayıt
    final loader = Get.find<GlobalLoaderController>(tag: loaderTag);
    loader.isOn.value = true;

    await FirebaseFirestore.instance.collection("IsBul").doc(docID).set({
      "about": about.text,
      "adres": adres.value,
      "brand": brand.text,
      "calismaTuru": selectedCalismaTuruList.toList(),
      "city": sehir.value,
      "town": ilce.value,
      "ended": false,
      "isTanimi": isTanimi.text,
      "lat": lat.value,
      "long": long.value,
      "logo": existingJob?.logo ?? "",
      "maas1": maasOpen.value ? int.tryParse(maas1.text) ?? 0 : 0,
      "maas2": maasOpen.value ? int.tryParse(maas2.text) ?? 0 : 0,
      "meslek": meslek.value,
      "timeStamp": DateTime.now().millisecondsSinceEpoch,
      "userID": FirebaseAuth.instance.currentUser!.uid,
      "yanHaklar": selectedYanHaklar.toList(),
    });

    // Yeni fotoğraf varsa her durumda yükle
    if (croppedImage.value != null) {
      Future.microtask(() => uploadCroppedImageToFirebase(docID));
    }
    selection.value = 0;
    Get.back();
  }
}
