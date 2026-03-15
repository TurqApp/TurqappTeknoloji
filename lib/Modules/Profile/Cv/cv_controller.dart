import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/cv_repository.dart';
import 'package:turqappv2/Models/CVModels/school_model.dart';

part 'cv_controller_sections_part.dart';
part 'cv_controller_persistence_part.dart';

class CvController extends GetxController {
  final CvRepository _cvRepository = CvRepository.ensure();
  var selection = 0.obs;
  TextEditingController firstName = TextEditingController(text: "");
  TextEditingController lastName = TextEditingController(text: "");
  TextEditingController linkedin = TextEditingController(text: "");
  TextEditingController mail = TextEditingController(text: "");
  TextEditingController phoneNumber = TextEditingController(text: "");
  TextEditingController onYazi = TextEditingController(text: "");

  RxList<CvSchoolModel> okullar = <CvSchoolModel>[].obs;
  RxList<CVLanguegeModel> diler = <CVLanguegeModel>[].obs;
  RxList<CVExperinceModel> isDeneyimleri = <CVExperinceModel>[].obs;
  RxList<CVReferenceHumans> referanslar = <CVReferenceHumans>[].obs;
  RxList<String> skills = <String>[].obs;
  RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDataFromFirestore();
  }

  @override
  void onClose() {
    firstName.dispose();
    lastName.dispose();
    mail.dispose();
    phoneNumber.dispose();
    linkedin.dispose();
    onYazi.dispose();
    super.onClose();
  }

  // ── Validations ──

  bool validateEmail(String email) {
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    return regex.hasMatch(email);
  }

  bool validatePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length == 10 || digits.length == 11;
  }

  bool validateLinkedIn(String url) {
    final normalized = url.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return normalized.contains('linkedin.com/');
  }

  bool _validateYear(String year) {
    if (year == "Halen" || year.isEmpty) return true;
    final y = int.tryParse(year);
    if (y == null) return false;
    return y >= 1950 && y <= DateTime.now().year + 6;
  }

  // ── School ──
}
