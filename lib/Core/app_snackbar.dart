import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void AppSnackbar(
  String title,
  String message, {
  Color? backgroundColor,
  Duration? duration,
  SnackPosition? snackPosition,
  EdgeInsets? margin,
  double? borderRadius,
  Widget? icon,
  Color? colorText,
  TextStyle? titleStyle,
  TextStyle? messageStyle,
}) {
  Get.snackbar(
    '',
    '',
    titleText: Text(
      title,
      style: titleStyle ??
          TextStyle(
        color: colorText ?? Colors.white,
        fontSize: 16,
        fontFamily: "MontserratBold",
      ),
    ),
    messageText: Text(
      message,
      style: messageStyle ??
          TextStyle(
        color: colorText ?? Colors.white,
        fontSize: 14,
        fontFamily: "MontserratMedium",
      ),
    ),
    backgroundColor: backgroundColor ?? Colors.grey.shade900.withValues(alpha: 0.5),
    snackPosition: snackPosition ?? SnackPosition.TOP,
    duration: duration ?? const Duration(seconds: 3),
    margin: margin ?? const EdgeInsets.all(12),
    borderRadius: borderRadius ?? 12,
    icon: icon ?? const Icon(CupertinoIcons.info, color: Colors.white, size: 24),
  );
}
