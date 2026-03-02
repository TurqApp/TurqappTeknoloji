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
        final data = doc.data();
        list.add(
          BookletModel(
            dil: (data["dil"] ?? '') as String,
            sinavTuru: (data["sinavTuru"] ?? '') as String,
            cover: (data["cover"] ?? '') as String,
            baslik: (data["baslik"] ?? '') as String,
            timeStamp: (data["timeStamp"] ?? 0) as num,
            kaydet: List<String>.from(data["kaydet"] ?? []),
            basimTarihi: (data["basimTarihi"] ?? '') as String,
            yayinEvi: (data["yayinEvi"] ?? '') as String,
            docID: doc.id,
            userID: (data["userID"] ?? '') as String,
            goruntuleme: List<String>.from(data["goruntuleme"] ?? []),
          ),
        );
      }
    } catch (e) {
      log("SavedOpticalFormsController.getData error: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
