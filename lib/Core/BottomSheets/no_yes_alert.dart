import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/text_styles.dart';

Future<void> infoAlert({
  required String title,
  required String message,
  String buttonText = "",
  VoidCallback? onPressed,
}) {
  return Get.dialog(
    CupertinoAlertDialog(
      title: Text(
        title,
        style: TextStyles.bold15Black,
        textAlign: TextAlign.center,
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          message,
          style: TextStyles.medium15Black,
          textAlign: TextAlign.center,
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            Get.back();
            onPressed?.call();
          },
          child: Text(
            buttonText.isEmpty ? 'common.ok'.tr : buttonText,
            style: const TextStyle(
              fontSize: 15,
              fontFamily: "Montserrat",
              color: Colors.black,
            ),
          ),
        ),
      ],
    ),
    barrierDismissible: true,
  );
}

Future<void> noYesAlert({
  required String title,
  required String message,
  required VoidCallback onYesPressed,
  String yesText = "",
  String cancelText = "",
  Color yesButtonColor = CupertinoColors.destructiveRed,
}) {
  return Get.dialog(
    CupertinoAlertDialog(
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
            cancelText.isEmpty ? 'common.cancel'.tr : cancelText,
            style: const TextStyle(
              fontSize: 15,
              fontFamily: "Montserrat",
              color: Colors.black,
            ),
          ),
        ),
        CupertinoDialogAction(
          onPressed: () {
            Get.back();
            onYesPressed();
          },
          isDestructiveAction: yesButtonColor == CupertinoColors.destructiveRed,
          child: Text(
            yesText.isEmpty ? 'common.yes'.tr : yesText,
            style: const TextStyle(
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
