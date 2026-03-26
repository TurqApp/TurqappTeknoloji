import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Themes/app_colors.dart';

part 'clickable_text_content_controller_part.dart';
part 'clickable_text_content_controller_fields_part.dart';
part 'clickable_text_content_controller_helpers_part.dart';
part 'clickable_text_content_view_part.dart';

class ClickableTextContent extends StatefulWidget {
  final String text;
  final void Function(String url)? onUrlTap;
  final void Function(String hashtag)? onHashtagTap;
  final void Function(String mention)? onMentionTap;
  final void Function(String plain)? onPlainTextTap;

  final double? fontSize;
  final Color? fontColor;
  final Color? urlColor;
  final Color? mentionColor;
  final Color? hashtagColor;
  final bool startWith7line;
  final Color? interactiveColor; // YENİ
  final bool showEllipsisOverlay; // YENİ: 7 satır kısaltmada sağ-altta '…'
  final bool toggleExpandOnTextTap;
  final Color? expandButtonColor;
  final double? expandButtonFontSize;

  const ClickableTextContent({
    super.key,
    required this.text,
    this.onUrlTap,
    this.onHashtagTap,
    this.onMentionTap,
    this.onPlainTextTap,
    this.fontSize,
    this.fontColor,
    this.urlColor,
    this.mentionColor,
    this.hashtagColor,
    this.startWith7line = false,
    this.interactiveColor, // YENİ
    this.showEllipsisOverlay = false,
    this.toggleExpandOnTextTap = false,
    this.expandButtonColor,
    this.expandButtonFontSize,
  });

  @override
  State<ClickableTextContent> createState() => _ClickableTextContentState();
}
