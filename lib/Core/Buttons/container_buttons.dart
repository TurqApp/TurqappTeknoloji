import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/turq_button_tokens.dart';

class SaveButton extends StatelessWidget {
  final RxBool isLoading;
  final RxString selectedSchool;
  final RxString selectedClassLevel;
  final VoidCallback onTap;
  final String text;

  const SaveButton({
    super.key,
    required this.isLoading,
    required this.selectedSchool,
    required this.selectedClassLevel,
    required this.onTap,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GestureDetector(
        onTap: isLoading.value ? null : onTap,
        child: Container(
          height: TurqButtonTokens.height,
          decoration: BoxDecoration(
            color: isLoading.value ? Colors.grey.shade300 : Colors.black,
            borderRadius: BorderRadius.circular(TurqButtonTokens.radius),
          ),
          child: Center(
            child: isLoading.value
                ? CupertinoActivityIndicator()
                : Text(
                    text,
                    style: TurqButtonTokens.primaryTextStyle,
                  ),
          ),
        ),
      ),
    );
  }
}
