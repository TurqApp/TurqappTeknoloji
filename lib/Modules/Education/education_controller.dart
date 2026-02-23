import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/answer_key.dart';
import 'package:turqappv2/Modules/Education/Antreman3/antreman_view.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/deneme_sinavlari.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_controller.dart';
import 'package:turqappv2/Modules/Education/Tests/tests.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_view.dart';

class EducationController extends GetxController {
  final titles = [
    "Burslar",
    "Çöz Geç",
    "Deneme Sınavları",
    //  "Çıkmış Sorular",
    "Test - Sınav",
    "Cevap Anahtarı",
    "Özel Ders",
    // "İşBul",
  ];

  final icons = [
    CupertinoIcons.create_solid,
    CupertinoIcons.doc_text,
    CupertinoIcons.book,
    // Icons.history_edu_outlined,
    CupertinoIcons.doc_append,
    Icons.fact_check_outlined,
    Icons.school_outlined,
    // Icons.business_center_outlined,
  ];

  final colors = [
    Colors.green,
    Colors.indigo,
    Colors.pink,
    Colors.deepOrange,
    Colors.teal,
    Colors.purple,
    //Colors.deepPurple,
    // Colors.pink.shade900,
  ];

  void navigateToModule(int index) {
    final pages = {
      0: ScholarshipsView(),
      1: AntremanView2(),
      2: DenemeSinavlari(),
      //3: CikmisSorular(),
      3: Tests(),
      4: AnswerKey(),
      5: TutoringView(),
      // 7: JobFinder(),
    };

    final page = pages[index];

    if (page != null) {
      // If navigating to Scholarships, reset search state so it doesn't persist
      if (index == 0) {
        if (Get.isRegistered<ScholarshipsController>()) {
          try {
            Get.find<ScholarshipsController>().resetSearch();
          } catch (_) {}
        }
      }
      Get.to(() => page);
    } else {
      print('Geçersiz modül index: $index');
    }
  }
}
