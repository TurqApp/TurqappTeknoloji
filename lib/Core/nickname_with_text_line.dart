import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/redirection_link.dart';
import 'package:turqappv2/Modules/Agenda/TagPosts/tag_posts.dart';

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
    color: Colors.blue,
  );

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyle(
      fontSize: widget.fontSize,
      fontFamily: "Montserrat",
      color: Colors.black,
      height: 1.5,
    );

    final List<TextSpan> spans = [];
    if (widget.showNickname) {
      spans.add(
        TextSpan(
          text: '@${widget.nickname}',
          style: TextStyle(
            fontFamily: "MontserratBold",
            fontWeight: FontWeight.w700,
            fontSize: widget.fontSize,
            color: widget.nicknameColor,
          ),
          recognizer: TapGestureRecognizer()..onTap = widget.onNicknameTap,
        ),
      );
    }

    if (widget.metin.trim().isNotEmpty) {
      final List<String> words = widget.metin.split(' ');

      for (var word in words) {
        if (word.startsWith("@")) {
          spans.add(
            TextSpan(
              text: spans.isEmpty ? word : " $word",
              style: defaultStyle.copyWith(color: Colors.blue),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  widget.onNicknameTap();
                },
            ),
          );
        } else if (word.startsWith("#")) {
          spans.add(
            TextSpan(
              text: spans.isEmpty ? word : " $word",
              style: defaultStyle.copyWith(color: Colors.blue),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  widget.onAnyTap();
                  Get.to(() => TagPosts(tag: word));
                },
            ),
          );
        } else if (word.startsWith("http://") || word.startsWith("https://")) {
          spans.add(
            TextSpan(
              text: spans.isEmpty ? word : " $word",
              style: defaultStyle.copyWith(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  widget.onAnyTap();
                  RedirectionLink().goToLink(word);
                },
            ),
          );
        } else {
          spans.add(
            TextSpan(
              text: spans.isEmpty ? word : " $word",
              style: defaultStyle,
            ),
          );
        }
      }
    }

    return Padding(
      padding: widget.padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (widget.inlineExpand) {
            final tp = TextPainter(
              text: TextSpan(children: spans),
              textDirection: TextDirection.ltr,
              maxLines: widget.collapsedMaxLines,
            )..layout(maxWidth: constraints.maxWidth);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && tp.didExceedMaxLines != showExpandButton) {
                setState(() {
                  showExpandButton = tp.didExceedMaxLines;
                });
              }
            });
          } else {
            // Satır-içi genişletme kapalı olduğunda her zaman tam metin göster, buton yok
            if (showExpandButton) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => showExpandButton = false);
              });
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.inlineExpand && showExpandButton && !expanded)
                _buildCollapsedTextWithInlineButton(
                    spans, defaultStyle, constraints)
              else if (widget.inlineExpand && showExpandButton && expanded)
                _buildExpandedTextWithInlineButton(
                    spans, defaultStyle, constraints)
              else
                ClipRect(
                  child: (widget.showEllipsisOverlay &&
                          widget.inlineExpand &&
                          !expanded &&
                          showExpandButton)
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                  style: defaultStyle, children: spans),
                              maxLines: widget.maxLinesOverride ??
                                  widget.collapsedMaxLines,
                              overflow: TextOverflow.clip,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '…',
                              style: TextStyle(
                                fontSize: widget.fontSize,
                                fontFamily: "MontserratBold",
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        )
                      : RichText(
                          text: TextSpan(style: defaultStyle, children: spans),
                          maxLines: widget.maxLinesOverride ??
                              (widget.inlineExpand
                                  ? (expanded ? null : widget.collapsedMaxLines)
                                  : null),
                          overflow: widget.overflowOverride ??
                              (widget.inlineExpand
                                  ? (expanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis)
                                  : TextOverflow.visible),
                        ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCollapsedTextWithInlineButton(List<TextSpan> spans,
      TextStyle defaultStyle, BoxConstraints constraints) {
    final buttonText = "daha fazla göster";
    final buttonStyle = _buttonStyle;

    // Kısaltılmış görünümde stilleri kaybetmemek için doğrudan spans'i kullan,
    // butonu her zaman alt satırda göster.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(style: defaultStyle, children: spans),
          maxLines: widget.collapsedMaxLines,
          overflow: TextOverflow.ellipsis,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: GestureDetector(
            onTap: () => setState(() => expanded = true),
            child: Text(
              buttonText,
              style: buttonStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedTextWithInlineButton(List<TextSpan> spans,
      TextStyle defaultStyle, BoxConstraints constraints) {
    final buttonText = "daha az göster";
    final buttonStyle = _buttonStyle;

    // Wrap widget ile inline buton yerleştirme
    return _buildInlineTextWithButton(
        spans, buttonText, buttonStyle, defaultStyle, constraints, false);
  }

  Widget _buildInlineTextWithButton(
      List<TextSpan> spans,
      String buttonText,
      TextStyle buttonStyle,
      TextStyle defaultStyle,
      BoxConstraints constraints,
      bool isCollapsed) {
    final fullText = spans.map((span) => span.text ?? '').join();

    if (isCollapsed) {
      // İlk satır için metni tam göster, buton için yer kontrol et
      final firstLineText =
          _getFirstLineText(fullText, defaultStyle, constraints);
      final buttonSpan = TextSpan(text: " $buttonText", style: buttonStyle);

      // İlk satır + buton birlikte sığar mı kontrol et
      final combinedPainter = TextPainter(
        text: TextSpan(
          style: defaultStyle,
          children: [
            TextSpan(text: firstLineText),
            buttonSpan,
          ],
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: constraints.maxWidth);

      if (!combinedPainter.didExceedMaxLines) {
        // İlk satırda sığıyor, inline göster
        return GestureDetector(
          onTap: () => setState(() => expanded = true),
          child: RichText(
            text: TextSpan(
              style: defaultStyle,
              children: [
                TextSpan(text: firstLineText),
                TextSpan(text: " $buttonText", style: buttonStyle),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
        );
      } else {
        // İlk satırda sığmıyor, alt satırda göster
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: defaultStyle,
                children: [TextSpan(text: firstLineText)],
              ),
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: GestureDetector(
                onTap: () => setState(() => expanded = true),
                child: Text(
                  buttonText,
                  style: buttonStyle,
                ),
              ),
            ),
          ],
        );
      }
    } else {
      // Expanded durumda: tam metin + inline buton (mümkünse)
      final buttonSpan = TextSpan(text: " $buttonText", style: buttonStyle);
      final combinedSpans = [...spans, buttonSpan];

      final testPainter = TextPainter(
        text: TextSpan(style: defaultStyle, children: combinedSpans),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: constraints.maxWidth);

      final lines = testPainter.computeLineMetrics();

      if (lines.isNotEmpty && lines.last.width <= constraints.maxWidth) {
        // Son satırda yer var, inline göster
        return GestureDetector(
          onTap: () => setState(() => expanded = false),
          child: RichText(
            text: TextSpan(
              style: defaultStyle,
              children: [
                ...spans,
                TextSpan(text: " $buttonText", style: buttonStyle),
              ],
            ),
            overflow: TextOverflow.visible,
          ),
        );
      }

      // Ayrı satırda göster
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(style: defaultStyle, children: spans),
            overflow: TextOverflow.visible,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: GestureDetector(
              onTap: () => setState(() => expanded = false),
              child: Text(
                buttonText,
                style: buttonStyle,
              ),
            ),
          ),
        ],
      );
    }
  }

  String _getFirstLineText(
      String fullText, TextStyle defaultStyle, BoxConstraints constraints) {
    // İlk satırda ne kadar metin sığacağını hesapla
    final painter = TextPainter(
      text: TextSpan(text: fullText, style: defaultStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: constraints.maxWidth);

    if (!painter.didExceedMaxLines) {
      // Tam metin bir satıra sığıyor
      return fullText;
    }

    // Metin kesilecek, ilk satır için uygun noktayı bul
    final textPainter = TextPainter(
      text: TextSpan(text: fullText, style: defaultStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: constraints.maxWidth);

    final position = textPainter.getPositionForOffset(
        Offset(constraints.maxWidth, textPainter.size.height / 2));

    if (position.offset > 0 && position.offset < fullText.length) {
      // Kelime sınırında kesmek için
      String truncatedText = fullText.substring(0, position.offset);
      final lastSpaceIndex = truncatedText.lastIndexOf(' ');

      if (lastSpaceIndex > 0 && lastSpaceIndex < truncatedText.length - 10) {
        truncatedText = truncatedText.substring(0, lastSpaceIndex);
      }

      return truncatedText.trimRight();
    }

    return fullText;
  }
}
