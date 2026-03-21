import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import '../text_styles.dart';

class BackButtons extends StatelessWidget {
  final String text;
  const BackButtons({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBackButton(
          onTap: () {
            Get.back();
          },
        )
            ,
        const SizedBox(width: 8),
        Flexible(
          fit: FlexFit.loose,
          child: AppPageTitle(
            text,
            fontSize: TextStyles.headerTextStyle.fontSize ?? 20,
          ),
        ),
      ],
    );
  }
}
