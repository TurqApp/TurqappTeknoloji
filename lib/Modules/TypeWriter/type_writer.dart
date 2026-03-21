import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Themes/app_colors.dart';
import 'package:turqappv2/Themes/app_fonts.dart';
import 'type_writer_controller.dart';

class TypewriterText extends StatefulWidget {
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
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  late final TypewriterController controller;
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'typewriter_${widget.text.hashCode}_${identityHashCode(this)}';
    controller = TypewriterController.ensure(
      fullText: widget.text,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    final existing = TypewriterController.maybeFind(tag: _controllerTag);
    if (identical(existing, controller)) {
      Get.delete<TypewriterController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            fontSize: widget.fontSize, // 🔹 Burada kullanılıyor
            fontFamily: AppFontFamilies.mbold,
          ),
        ),
      );
    });
  }
}
