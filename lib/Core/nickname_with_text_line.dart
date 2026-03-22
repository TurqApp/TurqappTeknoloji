import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/url_utils.dart';
import 'package:turqappv2/Core/redirection_link.dart';
import 'package:turqappv2/Modules/Agenda/TagPosts/tag_posts.dart';

part 'nickname_with_text_line_view_part.dart';
part 'nickname_with_text_line_inline_part.dart';

class NicknameWithTextLine extends StatefulWidget {
  final String nickname;
  final String metin;
  final String userID;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final void Function() onNicknameTap;
  final void Function() onAnyTap;
  final Color nicknameColor;
  final bool inlineExpand;
  final int? maxLinesOverride;
  final TextOverflow? overflowOverride;
  final bool showNickname;
  final int collapsedMaxLines;
  final bool showEllipsisOverlay;

  const NicknameWithTextLine({
    super.key,
    required this.nickname,
    required this.userID,
    required this.metin,
    required this.onNicknameTap,
    required this.onAnyTap,
    this.nicknameColor = Colors.black,
    this.fontSize = 13,
    this.padding = const EdgeInsets.only(left: 8),
    this.inlineExpand = true,
    this.maxLinesOverride,
    this.overflowOverride,
    this.showNickname = true,
    this.collapsedMaxLines = 1,
    this.showEllipsisOverlay = false,
  });

  @override
  State<NicknameWithTextLine> createState() => _NicknameWithTextLineState();
}

class _NicknameWithTextLineState extends State<NicknameWithTextLine> {
  bool expanded = false;
  bool showExpandButton = false;

  static const TextStyle _buttonStyle = TextStyle(
    fontSize: 12,
    fontFamily: "Montserrat",
    color: Color(0xFF4F718E),
  );

  @override
  Widget build(BuildContext context) => _buildNicknameLine(context);
}
