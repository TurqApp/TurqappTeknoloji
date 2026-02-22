import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:turqappv2/Core/TextStyles.dart';
import 'package:turqappv2/Models/Education/QuestionBankModel.dart';

class Complaint {
  final String postID;
  final String sikayetDesc;
  final String sikayetTitle;
  final int timeStamp;
  final String userID;
  final String yorumID;

  Complaint({
    required this.postID,
    required this.sikayetDesc,
    required this.sikayetTitle,
    required this.timeStamp,
    required this.userID,
    required this.yorumID,
  });

  Map<String, dynamic> toJson() {
    return {
      'postID': postID,
      'sikayetDesc': sikayetDesc,
      'sikayetTitle': sikayetTitle,
      'timeStamp': timeStamp,
      'userID': userID,
      'yorumID': yorumID,
    };
  }
}

class ComplaintController extends GetxController {
  final RxString selectedSikayet = ''.obs;
  final String userID = FirebaseAuth.instance.currentUser?.uid ?? '';

  void submitSikayet(
    String postID,
    String sikayetTitle,
    String sikayetDesc,
  ) async {
    final sikayet = Complaint(
      postID: postID,
      sikayetDesc: sikayetDesc,
      sikayetTitle: sikayetTitle,
      timeStamp: DateTime.now().millisecondsSinceEpoch,
      userID: userID,
      yorumID: '',
    );

    try {
      await FirebaseFirestore.instance
          .collection('Sikayetler')
          .add(sikayet.toJson());
      AppSnackbar("Başarılı", "Bilgilendirmeniz için teeşkkürler.");
    } catch (e) {
      AppSnackbar("Hata", "Bildiriminiz gönderilirken bir hata oluştu");
    }
  }
}

class ComplaintBottomSheet extends StatelessWidget {
  final QuestionBankModel question;

  const ComplaintBottomSheet({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final ComplaintController sikayetController =
        Get.put(ComplaintController());
    final RxList<String> selectedSikayets =
        <String>[].obs; // Multiple selections

    final List<Map<String, String>> sikayetOptions = [
      {
        'title': 'Sorunun yanlış olduğunu düşünüyorum.',
        'desc':
            '${question.sinavTuru} ${question.ders} ${question.soruNo}. soru içeriğinde bir hata olduğunu düşünüyorum, bu soru doğru değil.',
      },
      {
        'title': 'Cevabın yanlış olduğunu düşünüyorum.',
        'desc':
            '${question.sinavTuru} ${question.ders} ${question.soruNo}. sorunun doğru cevabı yanlış olarak işaretlenmiş.',
      },
      {
        'title': 'Soru ${question.ders} dersine ait değil.',
        'desc':
            '${question.sinavTuru} ${question.ders} ${question.soruNo}. soru, ${question.ders} dersi kategorisine uygun değil.',
      },
    ];

    // Calculate percentages
    final double correctPercentage = (question.dogruCevapVerenler.length /
            (question.dogruCevapVerenler.length +
                question.yanlisCevapVerenler.length +
                1)) *
        100;
    final double incorrectPercentage = (question.yanlisCevapVerenler.length /
            (question.dogruCevapVerenler.length +
                question.yanlisCevapVerenler.length +
                1)) *
        100;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(height: 12),
          Center(
            child: Text(
              "Soru hakkında",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: "MontserratBold",
              ),
            ),
          ),
          SizedBox(height: 12),
          Obx(() {
            return Column(
              children: sikayetOptions.map((option) {
                final isSelected = selectedSikayets.contains(
                  option['title'],
                );
                return GestureDetector(
                  onTap: () {
                    if (isSelected) {
                      selectedSikayets.remove(option['title']);
                    } else {
                      selectedSikayets.add(option['title']!);
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    padding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[50] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          option['title']!,
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                isSelected ? Colors.blue[800] : Colors.black54,
                            fontFamily: isSelected
                                ? "MontserratBold"
                                : "MontserratMedium",
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color:
                              isSelected ? Colors.green[600] : Colors.grey[400],
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          }),
          SizedBox(height: 16),
          Row(
            children: [
              // Green bar for correct answers
              Expanded(
                flex: correctPercentage.toInt(),
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(5),
                      right: Radius.zero,
                    ),
                  ),
                ),
              ),
              // Red bar for incorrect answers (adjacent to green bar)
              Expanded(
                flex: incorrectPercentage.toInt(),
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.zero,
                      right: Radius.circular(5),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "%${correctPercentage.toStringAsFixed(1)} Doğru",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.green,
                  fontFamily: "MontserratMedium",
                ),
              ),
              Text(
                "%${incorrectPercentage.toStringAsFixed(1)} Yanlış",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.red,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ],
          ),
          SizedBox(height: 32),
          Center(
            child: GestureDetector(
              onTap: () {
                if (selectedSikayets.isEmpty) {
                  AppSnackbar(
                    "Hata",
                    "Lütfen en az bir bildiri seçeneği seçin!",
                  );
                  return;
                }
                for (var title in selectedSikayets) {
                  final selectedOption = sikayetOptions.firstWhere(
                    (option) => option['title'] == title,
                  );
                  sikayetController.submitSikayet(
                    question.docID,
                    selectedOption['title']!,
                    selectedOption['desc']!,
                  );
                }
                selectedSikayets.clear(); // Clear selections after submission
                Get.back();
              },
              child: Container(
                height: 40,
                alignment: Alignment.center,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("Gönder", style: TextStyles.antremanTitle),
              ),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
