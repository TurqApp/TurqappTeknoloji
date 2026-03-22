import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

class ChatSearchField extends StatelessWidget {
  const ChatSearchField({
    super.key,
    required this.controller,
    this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextField(
          key: const ValueKey(IntegrationTestKeys.inputChatSearch),
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'common.search'.tr,
            hintStyle: const TextStyle(
              color: Colors.grey,
              fontFamily: 'MontserratMedium',
            ),
            border: InputBorder.none,
            icon: const Icon(
              CupertinoIcons.search,
              color: Colors.grey,
              size: 18,
            ),
          ),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: 'MontserratMedium',
          ),
        ),
      ),
    );
  }
}
