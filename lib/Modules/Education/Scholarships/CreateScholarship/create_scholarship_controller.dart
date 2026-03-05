import 'dart:convert';
import 'dart:developer';
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
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/scholarship_preview_view.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_view.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';

class CreateScholarshipController extends GetxController {
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
  final geriOdemeli = 'Hayır'.obs;
  final mukerrerDurumu = 'Alabilir'.obs;
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
  final applicationOption = ["TurqApp", "Web Site"].obs;
  final applicationOptionValue = "TurqApp".obs;
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
  final currentUser = FirebaseAuth.instance.currentUser;

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

  Future<Uint8List?> _compressFileToWebp(File file, {int quality = 85}) async {
    try {
      return await FlutterImageCompress.compressWithFile(
        file.path,
        format: CompressFormat.webp,
        quality: quality,
      );
    } catch (e) {
      log('WebP sıkıştırma hatası (file): $e');
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
    } catch (e) {
      log('WebP sıkıştırma hatası (bytes): $e');
      return null;
    }
  }

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
        AppSnackbar('Hata', 'Burs verisi yüklenemedi.');
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
    basvuruYapilacakYer.value =
        isEditing.value ? basvuruYapilacakYer.value : "TurqApp";
    basvuruYapilacakYerController.text = basvuruYapilacakYer.value;
    basvuruKosullariController.text = basvuruKosullari.value;
    belgelerController.text = belgeler.join('\n');
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
    basvuruYapilacakYerController.text = basvuruYapilacakYer.value;
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
    basvuruKosullariController.text = basvuruKosullari.value;
    aylar.assignAll(model.aylar);
    belgeler.assignAll(model.belgeler);
    belgelerController.text = belgeler.join('\n');
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
    aylarText.value = aylar.isEmpty ? "" : "${aylar.length} ay seçildi";
    aylarController.text = aylarText.value;
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
      final String response = await DefaultAssetBundle.of(
        Get.context!,
      ).loadString('assets/data/CityDistrict.json');
      final List<dynamic> data = jsonDecode(response);
      final Map<String, List<String>> tempMap = {};
      final Set<String> tempIller = {};

      for (var item in data) {
        final String il = item['il'];
        final String ilce = item['ilce'];
        tempIller.add(il);
        if (!tempMap.containsKey(il)) {
          tempMap[il] = [];
        }
        tempMap[il]!.add(ilce);
      }

      iller.assignAll(tempIller.toList()..sort());
      ilIlceMap.assignAll(tempMap);
    } catch (e) {
      AppSnackbar('Hata', 'İl-ilçe verisi yüklenemedi.');
    }
  }

  Future<void> loadHigherEducationData() async {
    try {
      final String response = await DefaultAssetBundle.of(
        Get.context!,
      ).loadString('assets/data/HigherEducation.json');
      final List<dynamic> data = jsonDecode(response);
      final Map<String, List<String>> tempMap = {};
      final Set<String> tempUniversiteler = {};

      for (var item in data) {
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

      tumUniversiteler.assignAll(tempUniversiteler.toList()..sort());
      universiteMap.assignAll(tempMap);
      higherEducationData.assignAll(data);
    } catch (e) {
      AppSnackbar('Hata', 'Üniversite verisi yüklenemedi.');
    }
  }

  List<String> getDistrictsForSelectedCities() {
    final List<String> districts = [];
    for (var il in sehirler) {
      districts.addAll(ilIlceMap[il] ?? []);
    }
    return districts..sort();
  }

  List<String> getUniversitiesForSelectedCities() {
    final List<String> universities = ['Tüm Üniversiteler'];

    if (lisansTuru.isEmpty) {
      if (hedefKitle.value == "Tüm Türkiye") {
        universities.addAll(tumUniversiteler);
      } else {
        for (var il in sehirler) {
          universities.addAll(universiteMap[il] ?? []);
        }
      }
      return universities.toSet().toList()
        ..sort(
          (a, b) => a == 'Tüm Üniversiteler'
              ? -1
              : b == 'Tüm Üniversiteler'
                  ? 1
                  : a.compareTo(b),
        );
    }

    if (hedefKitle.value == "Tüm Türkiye") {
      for (var uni in tumUniversiteler) {
        bool shouldAdd = false;
        for (var item in higherEducationData) {
          if (item['universite'] == uni) {
            String tip = item['tip'];
            if (lisansTuru.contains('Ön Lisans') && tip == 'ÖN LİSANS') {
              shouldAdd = true;
            } else if ((lisansTuru.contains('Lisans') ||
                    lisansTuru.contains('Yüksek Lisans') ||
                    lisansTuru.contains('Doktora')) &&
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
              if (lisansTuru.contains('Ön Lisans') && tip == 'ÖN LİSANS') {
                shouldAdd = true;
              } else if ((lisansTuru.contains('Lisans') ||
                      lisansTuru.contains('Yüksek Lisans') ||
                      lisansTuru.contains('Doktora')) &&
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
        (a, b) => a == 'Tüm Üniversiteler'
            ? -1
            : b == 'Tüm Üniversiteler'
                ? 1
                : a.compareTo(b),
      );
  }

  Future<String?> _uploadImage(String localPath, {bool isLogo = false}) async {
    if (localPath.isEmpty) {
      log('Hata: Dosya yolu boş.');
      return null;
    }

    // URL ise yükleme yapma, mevcut URL'yi döndür
    if (localPath.startsWith('http')) {
      log('Bu bir Firebase URL\'si, yükleme yapılmayacak: $localPath');
      return localPath;
    }

    try {
      final file = File(localPath);
      if (!await file.exists()) {
        log('Hata: Dosya bulunamadı: $localPath');
        AppSnackbar('Hata', 'Seçilen dosya bulunamadı.');
        return null;
      }
      final nsfw = await OptimizedNSFWService.checkImage(file);
      if (nsfw.errorMessage != null) {
        AppSnackbar('Hata', 'NSFW görsel kontrolü başarısız.');
        return null;
      }
      if (nsfw.isNSFW) {
        AppSnackbar('Hata', 'Uygunsuz görsel tespit edildi.');
        return null;
      }

      final webpBytes = await _compressFileToWebp(file, quality: 85);
      if (webpBytes == null || webpBytes.isEmpty) {
        AppSnackbar('Hata', 'Görsel WebP formatına dönüştürülemedi.');
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
      log('Görsel başarıyla yüklendi: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      log('Görsel yüklenirken bir hata oluştu: $e');
      AppSnackbar('Hata', 'Görsel yüklenirken bir hata oluştu.');
      return null;
    }
  }

  Future<String?> _captureAndUploadTemplate() async {
    try {
      if (selectedTemplateIndex.value == -1) {
        log('Hata: Şablon seçilmedi.');
        return null;
      }

      RenderRepaintBoundary? boundary = templateKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        log('Hata: RenderRepaintBoundary bulunamadı.');
        return null;
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        log('Hata: ByteData oluşturulamadı.');
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
        log('Hata: Dosya oluşturulamadı: $tempPath');
        return null;
      }
      final nsfw = await OptimizedNSFWService.checkImage(file);
      if (nsfw.errorMessage != null) {
        AppSnackbar('Hata', 'NSFW görsel kontrolü başarısız.');
        return null;
      }
      if (nsfw.isNSFW) {
        AppSnackbar('Hata', 'Uygunsuz görsel tespit edildi.');
        return null;
      }

      final webpBytes = await _compressBytesToWebp(bytes, quality: 85);
      if (webpBytes == null || webpBytes.isEmpty) {
        AppSnackbar('Hata', 'Şablon görseli WebP formatına dönüştürülemedi.');
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
      log('Şablon görüntüsü başarıyla yüklendi: $downloadUrl');
      return downloadUrl;
    } catch (e, stackTrace) {
      log('Şablon görüntüsü yakalanırken/yüklenirken hata oluştu: $e',
          stackTrace: stackTrace);
      AppSnackbar('Hata', 'Şablon görüntüsü yakalanamadı.');
      log('Şablon görüntüsü yakalanamadı: $e');

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
    basvuruYapilacakYer.value = 'TurqApp';
    baslangicTarihi.value = DateFormat('dd.MM.yyyy').format(DateTime.now());
    bitisTarihi.value =
        DateFormat('dd.MM.yyyy').format(DateTime.now().add(Duration(days: 1)));
    tutar.value = '';
    tutarController.text = '';
    ogrenciSayisi.value = '';
    ogrenciSayisiController.text = '';
    egitimKitlesi.value = '';
    lisansTuru.clear();
    geriOdemeli.value = 'Hayır';
    mukerrerDurumu.value = 'Alabilir';
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
    basvuruYapilacakYerController.text = 'TurqApp';
    websiteController.text = 'https://';
    basvuruKosullariController.text = '';
    aylarController.text = '';
    belgelerController.text = '';

    formKey.currentState?.reset();
    currentSection.value = 1;
  }

  Future<void> saveScholarship() async {
    if (formKey.currentState!.validate()) {
      try {
        isLoading.value = true;

        if (selectedTemplateIndex.value != -1) {
          final templateUrlResult = await _captureAndUploadTemplate();
          if (templateUrlResult == null) {
            AppSnackbar('Hata', 'Şablon görüntüsü yakalanamadı.');
            isLoading.value = false;
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
        if (egitimKitlesi.value == "Ortaokul") {
          altEgitimKitlesi.add("Ortaokul");
        } else if (egitimKitlesi.value == "Lise") {
          altEgitimKitlesi.add("Lise");
        } else if (egitimKitlesi.value == "Lisans") {
          altEgitimKitlesi.addAll(lisansTuru);
        } else if (egitimKitlesi.value == "Hepsi") {
          altEgitimKitlesi.addAll(["Ortaokul", "Lise"]);
          altEgitimKitlesi.addAll(lisansTuru);
        }

        final String egitimKitlesiValue = egitimKitlesi.value == "Hepsi"
            ? "Ortaokul, Lise, Lisans"
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
          userID: currentUser?.uid ?? '',
          website: website.value,
          lisansTuru: lisansTuru.join(','),
          template: template.value,
          ulke: ulke.value,
        );

        final docRef = await _firestore
            .collection('catalog')
            .doc('education')
            .collection('scholarships')
            .add(scholarship.toJson());

        await _firestore
            .collection('catalog')
            .doc('education')
            .collection('scholarships')
            .doc(docRef.id)
            .set({'likesCount': 0, 'bookmarksCount': 0},
                SetOptions(merge: true));

        // Refresh scholarships after successful save
        final scholarshipsController = Get.find<ScholarshipsController>();
        scholarshipsController.fetchScholarships();

        // After create: return to NavBarView (Education tab), then open ScholarshipsView
        try {
          // NavBar'a dön ve Education sekmesini seç
          Get.offAll(() => NavBarView());
          if (Get.isRegistered<NavBarController>()) {
            // Education sekmesi (varsayılan sıra: 0-Agenda,1-Explore,2-Shorts,3-Education,4-Profile)
            Get.find<NavBarController>().changeIndex(3);
          }
        } catch (_) {}

        // Reset scholarships search state if controller exists
        if (Get.isRegistered<ScholarshipsController>()) {
          try {
            Get.find<ScholarshipsController>().resetSearch();
          } catch (_) {}
        }

        // Bursları Education sekmesi açıkken göster
        Get.to(() => ScholarshipsView());
        AppSnackbar('Başarılı', 'Burs başarıyla paylaşıldı!');

        resetForm();
      } catch (e) {
        AppSnackbar('Hata', 'Burs paylaşılırken bir hata oluştu.');
        log('Burs paylaşılırken bir hata oluştu: $e');
      } finally {
        isLoading.value = false;
      }
    }
  }

  Future<void> updateScholarship() async {
    if (formKey.currentState!.validate()) {
      try {
        isLoading.value = true;

        // Şablon görüntüsünü yakala ve yükle
        if (selectedTemplateIndex.value != -1 &&
            templateKey.currentContext != null) {
          final templateUrlResult = await _captureAndUploadTemplate();
          if (templateUrlResult == null) {
            AppSnackbar('Hata', 'Şablon görüntüsü yakalanamadı.');
            isLoading.value = false;
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
        if (egitimKitlesi.value == "Ortaokul") {
          altEgitimKitlesi.add("Ortaokul");
        } else if (egitimKitlesi.value == "Lise") {
          altEgitimKitlesi.add("Lise");
        } else if (egitimKitlesi.value == "Lisans") {
          altEgitimKitlesi.addAll(lisansTuru);
        } else if (egitimKitlesi.value == "Hepsi") {
          altEgitimKitlesi.addAll(["Ortaokul", "Lise"]);
          altEgitimKitlesi.addAll(lisansTuru);
        }

        final String egitimKitlesiValue = egitimKitlesi.value == "Hepsi"
            ? "Ortaokul, Lise, Lisans"
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
          userID: currentUser?.uid ?? '',
          website: website.value,
          lisansTuru: lisansTuru.join(','),
          template: template.value,
          ulke: ulke.value,
        );

        await _firestore
            .collection('catalog')
            .doc('education')
            .collection('scholarships')
            .doc(scholarshipId.value)
            .update(scholarship.toJson());

        // Refresh scholarships after successful update
        final scholarshipsController = Get.find<ScholarshipsController>();
        scholarshipsController.fetchScholarships();

        // After update: return to NavBarView (Education tab), then open ScholarshipsView
        try {
          Get.offAll(() => NavBarView());
          if (Get.isRegistered<NavBarController>()) {
            Get.find<NavBarController>().changeIndex(3);
          }
        } catch (_) {}

        // Reset scholarships search state if controller exists
        if (Get.isRegistered<ScholarshipsController>()) {
          try {
            Get.find<ScholarshipsController>().resetSearch();
          } catch (_) {}
        }
        Get.to(() => ScholarshipsView());
        AppSnackbar('Başarılı', 'Burs başarıyla güncellendi!');

        resetForm();
      } catch (e) {
        AppSnackbar('Hata', 'Burs güncellenirken bir hata oluştu.');
      } finally {
        isLoading.value = false;
      }
    }
  }

  void goToPreview() {
    if (formKey.currentState!.validate()) {
      Get.to(() => ScholarshipPreviewView());
    }
  }
}
