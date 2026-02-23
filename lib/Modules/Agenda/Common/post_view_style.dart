import 'package:flutter/material.dart';
import 'post_action_style.dart';

class PostViewStyle {
  const PostViewStyle({
    required this.actionStyle,
    required this.padding,
    required this.cornerRadius,
    required this.textQuoteStyle,
    required this.headerSpacing,
  });

  final PostActionStyle actionStyle;
  final EdgeInsets padding;
  final double cornerRadius;
  final TextStyle textQuoteStyle;
  final double headerSpacing;

  const PostViewStyle.modern()
      : actionStyle = const PostActionStyle.modern(),
        padding = const EdgeInsets.symmetric(horizontal: 5),
        cornerRadius = 12,
        textQuoteStyle = const TextStyle(
          fontSize: 56,
          height: 1,
          color: Colors.black12,
          fontFamily: 'MontserratBold',
        ),
        headerSpacing = 8;

  const PostViewStyle.classic()
      : actionStyle = const PostActionStyle.classic(),
        padding = const EdgeInsets.symmetric(horizontal: 15),
        cornerRadius = 8,
        textQuoteStyle = const TextStyle(
          fontSize: 56,
          height: 1,
          color: Colors.black12,
          fontFamily: 'MontserratBold',
        ),
        headerSpacing = 8;
}
