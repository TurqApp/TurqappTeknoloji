import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/AnswerKeyCreatingOption/answer_key_creating_option_controller.dart';

class AnswerKeyCreatingOption extends StatelessWidget {
  final Function onBack;

  const AnswerKeyCreatingOption({required this.onBack, super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AnswerKeyCreatingOptionController(onBack));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Yeni Oluştur"),
            Expanded(
              child: GestureDetector(
                onTap: () => controller.navigateToCreateAnswerKey(context),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 15),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.pink,
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                      SizedBox(height: 15),
                      Text(
                        "Optik Form\nOluştur",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: GestureDetector(
                onTap: () => controller.navigateToCreateBook(context),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 15),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book_outlined, color: Colors.white, size: 40),
                      SizedBox(height: 15),
                      Text(
                        "Kitap Cevap Anahtarı\nOluştur",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
