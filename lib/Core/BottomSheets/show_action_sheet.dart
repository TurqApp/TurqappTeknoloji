import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/text_styles.dart';

Future<void> showActionSheet({
  required String title,
  required String message,
  required List<Map<String, dynamic>> actions,
  String cancelText = "Vazgeç",
  Color? titleColor,
  Color? messageColor,
  Color? cancelButtonColor,
}) {
  return showCupertinoModalPopup(
    context: Get.context!,
    builder: (context) => CupertinoActionSheet(
      title: Text(
        title,
        style: TextStyles.bold18Black.copyWith(
          color: titleColor ?? Colors.black,
        ),
      ),
      message: Text(
        message,
        style: TextStyle(
          fontSize: 15,
          fontFamily: "MontserratMedium",
          color: messageColor ?? Colors.grey.shade700,
        ),
        textAlign: TextAlign.center,
      ),
      actions: actions
          .map((action) => CupertinoActionSheetAction(
                onPressed: () {
                  Get.back();
                  action['onPressed']();
                },
                isDestructiveAction: action['isDestructive'] ?? false,
                child: Text(
                  action['text'],
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: "MontserratMedium",
                    color: action['color'] ?? CupertinoColors.activeBlue,
                  ),
                ),
              ))
          .toList(),
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Get.back(),
        child: Text(
          cancelText,
          style: TextStyle(
            fontSize: 15,
            fontFamily: "MontserratMedium",
            color: cancelButtonColor ?? CupertinoColors.systemBlue,
          ),
        ),
      ),
    ),
  );
}
