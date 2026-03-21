import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import '../../../Core/Buttons/turq_app_button.dart';
import 'address_selector_controller.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  children: [BackButtons(text: 'address.title'.tr)],
                ),
                SizedBox(
                  height: 12,
                ),
                Container(
                  constraints: BoxConstraints(
                    minHeight: 150,
                    maxHeight: 150,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: controller.addressController,
                    maxLength: 100,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'address.hint'.tr,
                      hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontFamily: "MontserratMedium",
                          fontSize: 15),
                      counterText: "",
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontFamily: "MontserratMedium",
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(
                  height: 12,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Obx(() {
                      return Text(
                        "${controller.currentLength.value}/150",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: "MontserratMedium",
                        ),
                      );
                    })
                  ],
                ),
                SizedBox(
                  height: 12,
                ),
                TurqAppButton(onTap: () {
                  controller.setData();
                }),
                SizedBox(
                  height: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
