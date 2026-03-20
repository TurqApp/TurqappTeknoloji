import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Models/Education/question_bank_model.dart';

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
          .collection('reports')
          .add(sikayet.toJson());
      AppSnackbar('common.success'.tr, 'training.complaint_thanks'.tr);
    } catch (e) {
      AppSnackbar('common.error'.tr, 'training.complaint_submit_failed'.tr);
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
        'key': 'question_wrong',
        'title': 'training.complaint_option_question_wrong_title'.tr,
        'desc': 'training.complaint_option_question_wrong_desc'.trParams({
          'exam': question.sinavTuru,
          'lesson': question.ders,
          'number': question.soruNo,
        }),
      },
      {
        'key': 'answer_wrong',
        'title': 'training.complaint_option_answer_wrong_title'.tr,
        'desc': 'training.complaint_option_answer_wrong_desc'.trParams({
          'exam': question.sinavTuru,
          'lesson': question.ders,
          'number': question.soruNo,
        }),
      },
      {
        'key': 'wrong_lesson',
        'title': 'training.complaint_option_wrong_lesson_title'
            .trParams({'lesson': question.ders}),
        'desc': 'training.complaint_option_wrong_lesson_desc'.trParams({
          'exam': question.sinavTuru,
          'lesson': question.ders,
          'number': question.soruNo,
        }),
      },
    ];

    // Calculate percentages
    final int totalAnswers = question.correctCount + question.wrongCount;
    final double correctPercentage =
        totalAnswers == 0 ? 0 : (question.correctCount / totalAnswers) * 100;
    final double incorrectPercentage =
        totalAnswers == 0 ? 0 : (question.wrongCount / totalAnswers) * 100;

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
              "training.question_about".tr,
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
                  option['key'],
                );
                return GestureDetector(
                  onTap: () {
                    if (isSelected) {
                      selectedSikayets.remove(option['key']);
                    } else {
                      selectedSikayets.add(option['key']!);
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    padding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.grey.shade100 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey[300]!,
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
                            color: isSelected ? Colors.black : Colors.black54,
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
                'training.correct_ratio'
                    .trParams({'value': correctPercentage.toStringAsFixed(1)}),
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.green,
                  fontFamily: "MontserratMedium",
                ),
              ),
              Text(
                'training.wrong_ratio'.trParams({
                  'value': incorrectPercentage.toStringAsFixed(1),
                }),
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
                    'common.error'.tr,
                    'training.complaint_select_one'.tr,
                  );
                  return;
                }
                for (var title in selectedSikayets) {
                  final selectedOption = sikayetOptions.firstWhere(
                    (option) => option['key'] == title,
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
                child: Text('common.send'.tr, style: TextStyles.antremanTitle),
              ),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
