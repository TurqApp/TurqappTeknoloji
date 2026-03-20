import 'package:flutter/material.dart';

@immutable
class PasajCardStyles {
  const PasajCardStyles._();

  static const Color detailColor = Color(0xFF616161);
  static const Color lineTwoColor = Color(0xFF111111);
  static const Color lineFourColor = Color(0xFF1E3A8A);

  static const TextStyle lineOne = TextStyle(
    color: Colors.black,
    fontSize: 15,
    fontFamily: 'MontserratBold',
    height: 1.25,
  );

  static const TextStyle lineTwo = TextStyle(
    color: lineTwoColor,
    fontSize: 14,
    fontFamily: 'MontserratMedium',
    height: 1.25,
  );

  static const TextStyle detail = TextStyle(
    color: detailColor,
    fontSize: 12,
    fontFamily: 'MontserratMedium',
    height: 1.25,
  );

  static const TextStyle lineFour = TextStyle(
    color: lineFourColor,
    fontSize: 12,
    fontFamily: 'MontserratMedium',
    height: 1.25,
  );

  static TextStyle gridLineTwo(Color color) => TextStyle(
        color: color,
        fontSize: 14,
        fontFamily: 'MontserratMedium',
        height: 1.25,
      );

  static TextStyle gridLineFour(Color color) => TextStyle(
        color: color,
        fontSize: 12,
        fontFamily: 'MontserratMedium',
        height: 1.25,
      );

  static const TextStyle gridPrice = TextStyle(
    color: Color(0xFF8B0000),
    fontSize: 19,
    fontFamily: 'MontserratBold',
    height: 1.25,
  );

  static const TextStyle gridCta = TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontFamily: 'MontserratMedium',
    height: 1.25,
  );
}
