import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import '../text_styles.dart';

class BackButtons extends StatelessWidget {
  static const double _horizontalPadding = 16;
  static const double _verticalPadding = 8;
  static const double _titleGap = 12;
  static const double _minHeight = 44;

  final String text;
  const BackButtons({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedWidth = constraints.maxWidth.isFinite;
        final title = AppPageTitle(
          text,
          fontSize: TextStyles.headerTextStyle.fontSize ?? 20,
        );

        final content = Row(
          mainAxisSize: hasBoundedWidth ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppBackButton(
              onTap: () {
                Get.back();
              },
            ),
            const SizedBox(width: _titleGap),
            if (hasBoundedWidth)
              Expanded(child: title)
            else
              Flexible(
                fit: FlexFit.loose,
                child: title,
              ),
          ],
        );

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _horizontalPadding,
            vertical: _verticalPadding,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: _minHeight,
                maxWidth: hasBoundedWidth
                    ? constraints.maxWidth - (_horizontalPadding * 2)
                    : double.infinity,
              ),
              child: content,
            ),
          ),
        );
      },
    );
  }
}
