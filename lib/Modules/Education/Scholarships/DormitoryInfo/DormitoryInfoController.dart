import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:turqappv2/Models/CitiesModel.dart';
import 'package:turqappv2/Models/Education/DormitoryModel.dart';
import 'package:turqappv2/Core/BottomSheets/AppBottomSheet.dart';
import 'package:turqappv2/Core/BottomSheets/ListBottomSheet.dart';

class DormitoryInfoController extends GetxController {
  final isLoading = true.obs;
  final sehir = "Şehir Seç".obs;
  final ilce = "İlçe Seç".obs;
  final yurt = "".obs;
  final sub = "İdari Seç".obs;
  final listedeYok = false.obs;
  final yurtInput = TextEditingController();
  final yurtSelectionController = TextEditingController();
  final yurtInputText = "".obs;
  final subList = ["DEVLET", "ÖZEL"].obs;
  final sehirler = <String>[].obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;
  final yurtList = <DormitoryModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadSehirler();
    fetchYurtData();
    fetchFirestoreData();
    ever(yurt, (_) {
      yurtSelectionController.text = yurt.value;
    });
    yurtInput.addListener(() {
      yurtInputText.value = yurtInput.text;
    });
  }

  @override
  void onClose() {
    yurtInput.dispose();
    yurtSelectionController.dispose();
    super.onClose();
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

  Future<void> fetchYurtData() async {
    try {
      String jsonString = await rootBundle.loadString(
        'assets/data/Dormitory.json',
      );
      List<dynamic> jsonResponse = jsonDecode(jsonString);
      yurtList.value =
          jsonResponse.map((data) => DormitoryModel.fromJson(data)).toList();
    } catch (e) {
      print("Error loading yurt data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFirestoreData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      if (doc.exists) {
        yurt.value = doc.get("yurt") ?? "";
      }
    } catch (e) {
      print("Error fetching Firestore data: $e");
    }
  }

  void showIdariSec() {
    Get.bottomSheet(
      AppBottomSheet(
        list: subList,
        title: "İdari Seç",
        startSelection: sub.value,
        onBackData: (v) {
          print("SELECTED $v");
          sub.value = v;
          yurt.value = "";
          yurtSelectionController.clear();
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  void showIlSec() {
    Get.bottomSheet(
      ListBottomSheet(
        list: sehirler,
        title: "Şehir Seç",
        startSelection: sehir.value,
        onBackData: (v) {
          print("SELECTED $v");
          sehir.value = v;
          ilce.value = "";
          yurt.value = "";
          yurtSelectionController.clear();
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  void showYurtSec() {
    final filteredYurtList = yurtList
        .where(
          (item) =>
              item.sub == sub.value.toUpperCase() &&
              item.ilAdi == sehir.value.toUpperCase(),
        )
        .map((item) => item.adi)
        .toList();

    if (filteredYurtList.isEmpty) {
      AppSnackbar("Bilgi", "Bu şehir ve idari tür için yurt bulunamadı");
      return;
    }

    Get.bottomSheet(
      ListBottomSheet(
        list: filteredYurtList,
        title: "Yurt Seç",
        startSelection: yurt.value.isEmpty ? null : yurt.value,
        onBackData: (v) {
          print("SELECTED YURT $v");
          yurt.value = v;
          listedeYok.value = false;
          yurtInput.clear();
          yurtInputText.value = "";
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  void toggleListedeYok() {
    listedeYok.value = !listedeYok.value;
    if (listedeYok.value) {
      yurt.value = "";
      yurtSelectionController.clear();
    } else {
      yurtInput.clear();
      yurtInputText.value = "";
    }
  }

  void selectYurt(DormitoryModel item) {
    yurt.value = item.adi;
    sehir.value = "Şehir Seç";
    sub.value = "İdari Seç";
    listedeYok.value = false;
    yurtInput.clear();
    yurtInputText.value = "";
    yurtSelectionController.text = item.adi;
  }

  void saveData() async {
    if ((listedeYok.value && yurtInputText.value.isNotEmpty) ||
        (!listedeYok.value && yurt.value.isNotEmpty)) {
      try {
        final String savedYurt =
            listedeYok.value ? yurtInputText.value : yurt.value;
        await FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({"yurt": savedYurt});
        yurt.value = savedYurt;
        Get.back();
        AppSnackbar("Başarılı", "Yurt Bilgileriniz Kaydedildi.");
      } catch (e) {
        print("Error saving data: $e");
        AppSnackbar("Hata", "Veri kaydedilemedi.");
      }
    } else {
      AppSnackbar("Hata", "Lütfen bir yurt seçin veya yurt adı girin");
    }
  }

  String capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1).toLowerCase() : s;
}
