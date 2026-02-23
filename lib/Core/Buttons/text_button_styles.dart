import 'package:flutter/material.dart';

class TextButtonStyle {
  static ButtonStyle textButonStyle = TextButton.styleFrom(
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.all(5),
      minimumSize: Size.zero,
      foregroundColor: Colors.black,
      textStyle: TextStyle(
        fontSize: 15,
        fontFamily: "MontserratMedium",
      ));
}
