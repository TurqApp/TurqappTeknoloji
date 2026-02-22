import 'package:flutter/material.dart';

class PostActionStyle {
  const PostActionStyle({
    required this.iconSize,
    required this.textStyle,
    this.reshareIcon,
    this.sendIconSize = 18,
    this.rowSpacing = 0,
  });

  final double iconSize;
  final TextStyle textStyle;
  final IconData? reshareIcon;
  final double sendIconSize;
  final double rowSpacing;

  const PostActionStyle.modern()
      : iconSize = 20,
        textStyle = const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontFamily: 'MontserratMedium',
        ),
        reshareIcon = Icons.repeat,
        sendIconSize = 18,
        rowSpacing = 0;

  const PostActionStyle.classic()
      : iconSize = 20,
        textStyle = const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontFamily: 'MontserratMedium',
        ),
        reshareIcon = Icons.repeat,
        sendIconSize = 18,
        rowSpacing = 0;
}
