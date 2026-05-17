import 'package:flutter/material.dart';

class TurqButtonTokens {
  const TurqButtonTokens._();

  static const double height = 40.0;
  static const double compactHeight = 34.0;
  static const double radius = 14.0;
  static const double horizontalPadding = 14.0;

  static const TextStyle primaryTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontFamily: 'MontserratMedium',
  );

  static const TextStyle secondaryTextStyle = TextStyle(
    color: Colors.black,
    fontSize: 15,
    fontFamily: 'MontserratMedium',
  );

  static ButtonStyle elevatedStyle({
    Color backgroundColor = Colors.black,
    Color foregroundColor = Colors.white,
    TextStyle? textStyle,
  }) {
    return ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
      minimumSize: const Size(0, height),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      textStyle: textStyle ?? primaryTextStyle,
    );
  }

  static ButtonStyle outlinedStyle({
    Color borderColor = const Color(0x1F000000),
    Color foregroundColor = Colors.black,
    TextStyle? textStyle,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: foregroundColor,
      padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
      minimumSize: const Size(0, height),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: borderColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      textStyle: textStyle ?? secondaryTextStyle,
    );
  }
}
