import 'package:flutter/material.dart';

class TextButtonStyle {
  static ButtonStyle textButonStyle = TextButton.styleFrom(
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.all(5),
      minimumSize: Size.zero
  );
}