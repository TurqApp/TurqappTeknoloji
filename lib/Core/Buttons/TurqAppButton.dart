import 'package:flutter/material.dart';

class TurqAppButton extends StatelessWidget {
  final EdgeInsets padding;
  final String text;
  final Color bgColor;
  final Color textColor;
  final double borderRadiusAll;
  final VoidCallback onTap;

  const TurqAppButton({
    super.key,
    this.padding = const EdgeInsets.only(left: 0, right: 0),
    this.text = "Kaydet",
    this.borderRadiusAll = 12.0,
    this.bgColor = Colors.black,
    this.textColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.all(Radius.circular(borderRadiusAll)),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontFamily: "MontserratMedium",
            ),
          ),
        ),
      ),
    );
  }
}
