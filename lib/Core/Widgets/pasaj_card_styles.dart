import 'package:flutter/material.dart';

@immutable
class PasajCardStyles {
  const PasajCardStyles._();

  static const Color detailColor = Color(0xFF616161);

  static const TextStyle detail = TextStyle(
    color: detailColor,
    fontSize: 12,
    fontFamily: 'MontserratMedium',
    height: 1.1,
  );
}
