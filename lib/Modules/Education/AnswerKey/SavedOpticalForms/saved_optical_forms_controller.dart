import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';

class SavedOpticalFormsController extends GetxController {
  final list = <BookletModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  Future<void> getData() async {
    isLoading.value = true;
    try {
      list.clear();
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final snapshots = await FirebaseFirestore.instance
          .collection("books")
          .where("kaydet", arrayContains: uid)
          .orderBy("timeStamp", descending: true)
          .get();

      for (var doc in snapshots.docs) {
        list.add(BookletModel.fromMap(doc.data(), doc.id));
      }
    } catch (e) {
      log("SavedOpticalFormsController.getData error: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
