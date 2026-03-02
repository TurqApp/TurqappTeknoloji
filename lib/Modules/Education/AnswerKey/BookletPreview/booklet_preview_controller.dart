import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/answer_key_sub_model.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletAnswer/booklet_answer.dart';

class BookletPreviewController extends GetxController {
  final BookletModel model;

  final isBookmarked = false.obs;
  final nickname = ''.obs;
  final pfImage = ''.obs;
  final fullName = ''.obs;
  final answerKeys = <AnswerKeySubModel>[].obs;

  BookletPreviewController(this.model);

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  void _initialize() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null && model.kaydet.contains(currentUserId)) {
      isBookmarked.value = true;
    }
    fetchAnswerKeys();
    fetchUserData();
  }

  Future<void> fetchAnswerKeys() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("books")
          .doc(model.docID)
          .collection("CevapAnahtarlari")
          .get();

      final newList = <AnswerKeySubModel>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final baslik = (data["baslik"] ?? "").toString();
        final rawCevaplar = data["dogruCevaplar"];
        final cevaplar = rawCevaplar is List
            ? rawCevaplar.map((e) => e.toString()).toList()
            : <String>[];
        final sira = data["sira"] is num
            ? data["sira"] as num
            : num.tryParse((data["sira"] ?? "0").toString()) ?? 0;

        newList.add(
          AnswerKeySubModel(
            baslik: baslik,
            docID: doc.id,
            dogruCevaplar: cevaplar,
            sira: sira,
          ),
        );
      }
      newList.sort((a, b) => a.sira.compareTo(b.sira));
      answerKeys.assignAll(newList);
      log(
        "Çekilen cevap anahtarları: ${newList.map((e) => e.baslik).toList()}",
      );
    } catch (e) {
      log("Cevap anahtarlarını çekme hatası: $e");
    }
  }

  Future<void> fetchUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(model.userID)
          .get();
      nickname.value = doc.get("nickname") ?? '';
      pfImage.value = doc.get("pfImage") ?? '';
      fullName.value = doc.get("firstName") ?? '';
      log(
        "Kullanıcı verisi çekildi: ${model.docID} için nickname: ${nickname.value}",
      );
    } catch (e) {
      log("Kullanıcı verisi çekme hatası: $e");
    }
  }

  Future<void> toggleBookmark() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final docRef =
          FirebaseFirestore.instance.collection('books').doc(model.docID);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        if (!docSnapshot.exists) return;

        final data = docSnapshot.data();
        final favorites = List<String>.from(data?['kaydet'] ?? []);

        if (favorites.contains(userId)) {
          favorites.remove(userId);
          isBookmarked.value = false;
        } else {
          favorites.add(userId);
          isBookmarked.value = true;
        }

        transaction.update(docRef, {'kaydet': favorites});
      });
    } catch (e) {
      log("Yer işareti değiştirme hatası: $e");
    }
  }

  void navigateToAnswerKey(BuildContext context, AnswerKeySubModel subModel) {
    Get.to(() => BookletAnswer(model: subModel, anaModel: model));
  }
}
