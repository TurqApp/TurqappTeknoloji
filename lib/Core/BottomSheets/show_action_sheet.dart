import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/text_styles.dart';

Future<void> showActionSheet({
  required String title,
  required String message,
  required List<Map<String, dynamic>> actions,
  String cancelText = "",
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
                  final callback = action['onPressed'];
                  if (callback is! Function) return;
                  Future.sync(() => callback()).catchError((error, stackTrace) {
                    FlutterError.reportError(
                      FlutterErrorDetails(
                        exception: error,
                        stack: stackTrace is StackTrace ? stackTrace : null,
                        library: 'show_action_sheet',
                        context: ErrorDescription('run action sheet action'),
                      ),
                    );
                  });
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
          cancelText.isEmpty ? 'common.cancel'.tr : cancelText,
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
