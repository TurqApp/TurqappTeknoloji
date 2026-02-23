import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Themes/app_colors.dart';
import 'package:turqappv2/Themes/app_fonts.dart';
import 'type_writer_controller.dart';

class TypewriterText extends StatelessWidget {
  final String text;
  final Color textColor;
  final double fontSize;

  const TypewriterText({
    super.key,
    required this.text,
    this.textColor = Colors.black,
    this.fontSize = 20, // 🔹 Varsayılan font boyutu
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TypewriterController(text), tag: text);

    return Obx(() {
      return ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [AppColors.primaryColor, AppColors.secondColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
        child: Text(
          controller.displayedText.value,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize, // 🔹 Burada kullanılıyor
            fontFamily: AppFontFamilies.mbold,
          ),
        ),
      );
    });
  }
}
