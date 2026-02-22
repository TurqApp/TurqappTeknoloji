import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Themes/AppColors.dart';
import '../TextStyles.dart';

class BackButtons extends StatelessWidget {
  final String text;
  BackButtons({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(
            CupertinoIcons.arrow_left,
            color: AppColors.textBlack,
          ),
        ),
        Text(
          text,
          style: TextStyles.headerTextStyle,
        )
      ],
    );
  }
}
