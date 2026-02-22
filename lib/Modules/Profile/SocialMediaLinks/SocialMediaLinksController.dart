import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turqappv2/Models/SocialMediaModel.dart';
import 'AddSocialMediaBottomSheet.dart';

class SocialMediaController extends GetxController {
  RxList<SocialMediaModel> list = <SocialMediaModel>[].obs;

  var selected = "".obs;
  var textController = TextEditingController();
  var urlController = TextEditingController();
  var imageFile = Rxn<File>();
  var enableSave = false.obs;
  var isUploading = false.obs;

  List<String> sosyal = [
    "TurqApp",
    "instagram",
    "facebook",
    "whatsApp",
    "x",
    "youtube",
    "linkedin",
    "tiktok",
    "pinterest",
  ];

  @override
  void onInit() {
    super.onInit();
    getData();
    selected.listen((_) => updateEnableSave());
    textController.addListener(updateEnableSave);
    urlController.addListener(updateEnableSave);
  }

  Future<void> pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    imageFile.value = pickedFile != null ? File(pickedFile.path) : null;
  }

  void updateEnableSave() {
    enableSave.value = textController.text.trim().isNotEmpty &&
        urlController.text.trim().isNotEmpty &&
        (selected.value.isNotEmpty || imageFile.value != null);
  }

  Future<void> getData() async {
    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("SosyalMedyaLinkleri")
        .get();
    List<SocialMediaModel> temp = [];
    for (var doc in snap.docs) {
      temp.add(SocialMediaModel(
        docID: doc.id,
        title: doc.get("title"),
        url: doc.get("url"),
        sira: doc.get("sira"),
        logo: doc.get("logo"),
      ));
    }

    list.value = temp;
  }

  void resetFields() {
    selected.value = "";
    textController.clear();
    urlController.clear();
    imageFile.value = null;
  }

  void showAddBottomSheet() {
    Get.bottomSheet(
      AddSocialMediaBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
    ).then((_) {
      getData();
    });
  }

  Future<void> updateAllSira() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final batch = FirebaseFirestore.instance.batch();

    for (int i = 0; i < list.length; i++) {
      final model = list[i];
      final docRef = FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("SosyalMedyaLinkleri")
          .doc(model.docID);

      batch.update(docRef, {"sira": i});
    }

    await batch.commit();
  }

  Future<void> updateItemOrder(int oldIndex, int newIndex) async {
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    // Firestore'da güncelle
    for (int i = 0; i < list.length; i++) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection("SosyalMedyaLinkleri")
          .doc(list[i].docID)
          .update({"sira": i});
    }
  }

  Future<String> uploadAssetImage(String assetPath, String docID) async {
    isUploading.value = true;
    final byteData = await rootBundle.load(assetPath);
    final data = byteData.buffer.asUint8List();
    final ref = FirebaseStorage.instance.ref(
        "social_icons/${FirebaseAuth.instance.currentUser!.uid}/$docID.png");
    final uploadTask = await ref.putData(data);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadFileImage(File file, String docID) async {
    isUploading.value = true;
    final ref = FirebaseStorage.instance.ref(
        "social_icons/${FirebaseAuth.instance.currentUser!.uid}/$docID.png");
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}
