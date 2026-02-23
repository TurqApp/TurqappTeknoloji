import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/text_styles.dart';

Future<void> noYesAlert({
  required String title,
  required String message,
  required VoidCallback onYesPressed,
  String yesText = "Evet",
  String cancelText = "Vazgeç",
  Color yesButtonColor = CupertinoColors.destructiveRed,
}) {
  return Get.dialog(
    CupertinoAlertDialog(
      // Başlık stili
      title: Text(
        title,
        style: TextStyles.bold15Black,
        textAlign: TextAlign.center,
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          message,
          style: TextStyles.medium15Black,
          textAlign: TextAlign.center,
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Get.back(),
          child: Text(
            cancelText,
            style: TextStyle(
                fontSize: 15, fontFamily: "Montserrat", color: Colors.black),
          ),
        ),
        CupertinoDialogAction(
          onPressed: () {
            Get.back();
            onYesPressed();
          },
          isDestructiveAction: yesButtonColor == CupertinoColors.destructiveRed,
          child: Text(
            yesText,
            style: TextStyle(
              fontSize: 15,
              fontFamily: "Montserrat",
            ),
          ),
        ),
      ],
    ),
    barrierDismissible: true,
  );
}
