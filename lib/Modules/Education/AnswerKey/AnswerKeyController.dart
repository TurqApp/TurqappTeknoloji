import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/BookletModel.dart';

class AnswerKeyController extends GetxController {
  var isLoading = false.obs;
  var bookList = <BookletModel>[].obs;
  ScrollController scrollController = ScrollController();
  final RxDouble scrollOffset = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    refreshData();
  }

  List<String> lessons = [
    "LGS",
    "TYT",
    "AYT",
    "YDT",
    "YDS",
    "ALES",
    "DGS",
    "KPSS",
    "DUS",
    "TUS",
    "Dil",
    "Yazılım",
    "Spor",
    "Tasarım",
  ];

  final List<Color> colors = [
    Colors.deepPurple,
    Colors.indigo,
    Colors.teal,
    Colors.deepOrange,
    Colors.pink,
    Colors.cyan.shade700,
    Colors.blueGrey,
    Colors.pink.shade900,
  ];

  List<Color> lessonsColors = [
    Colors.lightBlue.shade700,
    Colors.pink.shade600,
    Colors.green.shade700,
    Colors.orange.shade700,
    Colors.red.shade800,
    Colors.indigo.shade800,
    Colors.lime.shade700,
    Colors.brown.shade800,
    Colors.blue.shade800,
    Colors.cyan.shade800,
    Colors.purple.shade700,
    Colors.teal.shade700,
    Colors.red.shade700,
    Colors.deepOrange.shade700,
  ];

  List<IconData> lessonsIcons = [
    Icons.psychology,
    Icons.school,
    Icons.library_books,
    Icons.translate,
    Icons.language,
    Icons.book_online,
    Icons.calculate,
    Icons.assignment,
    Icons.health_and_safety,
    Icons.medical_services,
    Icons.translate,
    Icons.code,
    Icons.sports_basketball,
    Icons.design_services,
  ];

  Future<void> refreshData() async {
    isLoading.value = true;
    try {
      QuerySnapshot snapshots = await FirebaseFirestore.instance
          .collection("Kitapciklar")
          .orderBy("timeStamp", descending: true)
          .get();

      var newList = <BookletModel>[];
      for (var doc in snapshots.docs) {
        String basimTarihi = doc.get("basimTarihi") ?? '';
        String baslik = doc.get("baslik") ?? '';
        String cover = doc.get("cover") ?? '';
        String dil = doc.get("dil") ?? '';
        List<String> kaydet = List<String>.from(doc.get("kaydet") ?? []);
        List<String> goruntuleme = List<String>.from(
          doc.get("goruntuleme") ?? [],
        );
        String sinavTuru = doc.get("sinavTuru") ?? '';
        num timeStamp = doc.get("timeStamp") ?? 0;
        String yayinEvi = doc.get("yayinEvi") ?? '';
        String userID = doc.get("userID") ?? '';

        newList.add(
          BookletModel(
            dil: dil,
            sinavTuru: sinavTuru,
            cover: cover,
            baslik: baslik,
            timeStamp: timeStamp,
            kaydet: kaydet,
            basimTarihi: basimTarihi,
            yayinEvi: yayinEvi,
            docID: doc.id,
            userID: userID,
            goruntuleme: goruntuleme,
          ),
        );
      }

      log("Çekilen kitapçık sayısı: ${newList.length}");
      log(
        "Kitapçık başlıkları: ${newList.map((e) => '${e.docID}: ${e.baslik}').toList()}",
      );

      final uniqueList = newList.toSet().toList();
      bookList.assignAll(uniqueList);
    } catch (e) {
      log("Veri çekme hatası: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
