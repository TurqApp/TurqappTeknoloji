import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import '../../../Core/Buttons/turq_app_button.dart';
import 'address_selector_controller.dart';

part 'address_selector_shell_part.dart';
part 'address_selector_content_part.dart';

class AddressSelector extends StatefulWidget {
  const AddressSelector({super.key});

  @override
  State<AddressSelector> createState() => _AddressSelectorState();
}

class _AddressSelectorState extends State<AddressSelector> {
  late final AddressSelectorController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    final existingController = AddressSelectorController.maybeFind();
    if (existingController != null) {
      controller = existingController;
      _ownsController = false;
    } else {
      controller = AddressSelectorController.ensure();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(AddressSelectorController.maybeFind(), controller)) {
      Get.delete<AddressSelectorController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
