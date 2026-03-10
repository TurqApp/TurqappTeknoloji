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
      final savedSnapshots = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("books")
          .orderBy("createdAt", descending: true)
          .get();

      for (var savedDoc in savedSnapshots.docs) {
        final bookDoc = await FirebaseFirestore.instance
            .collection("books")
            .doc(savedDoc.id)
            .get();
        if (!bookDoc.exists) continue;
        list.add(BookletModel.fromMap(bookDoc.data() ?? {}, bookDoc.id));
      }
    } catch (e) {
      log("SavedOpticalFormsController.getData error: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
