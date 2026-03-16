import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/turq_button_tokens.dart';

class TurqAppButton extends StatelessWidget {
  final EdgeInsets padding;
  final String text;
  final Color bgColor;
  final Color textColor;
  final double borderRadiusAll;
  final double height;
  final double fontSize;
  final VoidCallback onTap;

  const TurqAppButton({
    super.key,
    this.padding = const EdgeInsets.only(left: 0, right: 0),
    this.text = "Kaydet",
    this.borderRadiusAll = TurqButtonTokens.radius,
    this.bgColor = Colors.black,
    this.textColor = Colors.white,
    this.height = TurqButtonTokens.height,
    this.fontSize = 15,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.all(Radius.circular(borderRadiusAll)),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontFamily: "MontserratMedium",
            ),
          ),
        ),
      ),
    );
  }
}
