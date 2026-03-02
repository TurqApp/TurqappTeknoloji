import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/CreateBook/create_book.dart';

class CreateBookController extends GetxController {
  final Function? onBack;
  final BookletModel? existingBook;
  final baslikController = TextEditingController();
  final yayinEviController = TextEditingController();
  final basimTarihiController = TextEditingController();
  final list = <CevapAnahtariHazirlikModel>[].obs;
  final selection = 0.obs;
  final sinavTuru = ''.obs;
  final imageFile = Rxn<File>();
  final showIndicator = false.obs;
  late final String docID;
  final picker = ImagePicker();

  CreateBookController(this.onBack, {this.existingBook}) {
    docID =
        existingBook?.docID ?? DateTime.now().millisecondsSinceEpoch.toString();
  }

  bool get isEditMode => existingBook != null;

  @override
  void onInit() {
    super.onInit();
    _prefillIfEditing();
  }

  @override
  void onClose() {
    baslikController.dispose();
    yayinEviController.dispose();
    basimTarihiController.dispose();
    super.onClose();
  }

  void handleBack() {
    if (selection.value != 0) {
      selection.value--;
    } else {
      Get.back();
    }
  }

  void nextStep() {
    selection.value++;
  }

  void selectSinavTuru(String value) {
    sinavTuru.value = value;
  }

  void addItem() {
    list.add(
      CevapAnahtariHazirlikModel(
        baslik: "Deneme ${list.length + 1}",
        dogruCevaplar: [],
        sira: list.length + 1,
      ),
    );
  }

  void removeLastItem() {
    if (list.isNotEmpty) {
      list.removeLast();
    }
  }

  void navigateToCevapAnahtari(
    BuildContext context,
    CevapAnahtariHazirlikModel model,
  ) {
    Get.to(
      () => CreateBookAnswerKey(
        model: model,
        onBack: () {
          list.refresh();
        },
      ),
    );
  }

  bool isFormValid() {
    return imageFile.value != null &&
        baslikController.text.isNotEmpty &&
        yayinEviController.text.isNotEmpty &&
        basimTarihiController.text.isNotEmpty &&
        sinavTuru.value.isNotEmpty;
  }

  Future<void> pickImage() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final pickedFile = await AppImagePickerService.pickSingleImage(ctx);
    if (pickedFile != null) {
      imageFile.value = pickedFile;
      await _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    if (imageFile.value == null) return;
    final detector = await NsfwDetector.load(threshold: 0.3);
    final result = await detector.detectNSFWFromFile(imageFile.value!);
    if (result?.isNsfw == true) {
      imageFile.value = null;
    }
  }

  Future<void> setData(BuildContext context) async {
    showIndicator.value = true;
    await FirebaseFirestore.instance.collection("books").doc(docID).set({
      "basimTarihi": basimTarihiController.text,
      "baslik": baslikController.text,
      "cover": existingBook?.cover ?? "",
      "dil": "Türkçe",
      "kaydet": existingBook?.kaydet ?? [],
      "sinavTuru": sinavTuru.value,
      "timeStamp":
          existingBook?.timeStamp ?? DateTime.now().millisecondsSinceEpoch,
      "yayinEvi": yayinEviController.text,
      "userID": existingBook?.userID ?? FirebaseAuth.instance.currentUser!.uid,
      "goruntuleme": existingBook?.goruntuleme ?? [],
    });
    SetOptions(merge: true);

    final oldAnswers = await FirebaseFirestore.instance
        .collection("books")
        .doc(docID)
        .collection("CevapAnahtarlari")
        .get();
    for (final doc in oldAnswers.docs) {
      await doc.reference.delete();
    }

    for (var item in list) {
      await FirebaseFirestore.instance
          .collection("books")
          .doc(docID)
          .collection("CevapAnahtarlari")
          .doc(DateTime.now().microsecondsSinceEpoch.toString())
          .set({
        "baslik": item.baslik,
        "sira": item.sira,
        "dogruCevaplar": item.dogruCevaplar,
      });
      SetOptions(merge: true);
    }

    if (imageFile.value != null) {
      await uploadImageToFirebaseStorage(imageFile.value!, context);
    } else {
      showIndicator.value = false;
      onBack?.call(true);
      Get.back();
    }
  }

  Future<void> _prefillIfEditing() async {
    final book = existingBook;
    if (book == null) return;
    baslikController.text = book.baslik;
    yayinEviController.text = book.yayinEvi;
    basimTarihiController.text = book.basimTarihi;
    sinavTuru.value = book.sinavTuru;

    final snapshot = await FirebaseFirestore.instance
        .collection("books")
        .doc(book.docID)
        .collection("CevapAnahtarlari")
        .get();
    final items = snapshot.docs
        .map(
          (doc) => CevapAnahtariHazirlikModel(
            baslik: (doc.data()['baslik'] ?? '').toString(),
            dogruCevaplar:
                List<String>.from(doc.data()['dogruCevaplar'] ?? const []),
            sira: (doc.data()['sira'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList()
      ..sort((a, b) => a.sira.compareTo(b.sira));
    list.assignAll(items);
  }

  Future<void> uploadImageToFirebaseStorage(
    File imageFile,
    BuildContext context,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        showIndicator.value = false;
        return;
      }

      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        showIndicator.value = false;
        return;
      }

      final resized = img.copyResize(
        originalImage,
        width: originalImage.width > 1400 ? 1400 : originalImage.width,
      );
      final resizedBytes = Uint8List.fromList(img.encodePng(resized));
      final webpData =
          await WebpUploadService.toWebpFromBytes(resizedBytes, quality: 85);
      if (webpData == null || webpData.isEmpty) {
        showIndicator.value = false;
        return;
      }

      final storagePath = 'books/$docID/cover.webp';
      final firebaseStorageRef = FirebaseStorage.instance.ref().child(
            storagePath,
          );
      final uploadTask = firebaseStorageRef.putData(
        webpData,
        SettableMetadata(
          contentType: 'image/webp',
          cacheControl: 'public, max-age=31536000, immutable',
        ),
      );

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes * 100)
            .toStringAsFixed(2);
        print("Yükleme ilerlemesi: $progress%");
      });

      final taskSnapshot = await uploadTask;
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();
      final cacheBustedUrl =
          '$downloadUrl${downloadUrl.contains('?') ? '&' : '?'}v=${DateTime.now().millisecondsSinceEpoch}';

      await FirebaseFirestore.instance.collection("books").doc(docID).update({
        "cover": cacheBustedUrl,
        "coverStoragePath": storagePath,
        "coverFormat": "webp",
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resim başarıyla yüklendi!')),
      );
      showIndicator.value = false;
      onBack?.call(true);
      Get.back();
    } catch (e) {
      showIndicator.value = false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Bir hata oluştu')));
    }
  }
}

class CreateBookAnswerKeyController extends GetxController {
  final CevapAnahtariHazirlikModel model;
  final Function onBack;
  final baslikController = TextEditingController();
  final inputController = TextEditingController();
  final cevaplar = <String>[].obs;
  final onIzlendi = false.obs;

  CreateBookAnswerKeyController(this.model, this.onBack) {
    baslikController.text = model.baslik;
    cevaplar.assignAll(model.dogruCevaplar);
    inputController.text = model.dogruCevaplar.join();
  }

  @override
  void onClose() {
    baslikController.dispose();
    inputController.dispose();
    super.onClose();
  }

  void kaydetCevaplar() {
    cevaplar.assignAll(
      inputController.text
          .split('')
          .where((element) => RegExp(r'[A-E]').hasMatch(element))
          .toList(),
    );
    onIzlendi.value = true;
  }

  void saveAndBack() {
    model.baslik = baslikController.text;
    model.dogruCevaplar = cevaplar.toList();
    onBack();
    Get.back();
  }
}
