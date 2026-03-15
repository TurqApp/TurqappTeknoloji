import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Helpers/GlobalLoader/global_loader_controller.dart';

class GlobalLoader extends StatelessWidget {
  const GlobalLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<GlobalLoaderController>()
        ? Get.find<GlobalLoaderController>()
        : Get.put(GlobalLoaderController(), permanent: true);
    return Obx(() {
      if (!controller.isOn.value) return SizedBox.shrink();
      return CupertinoActivityIndicator(
        color: Colors.white,
      );
    });
  }
}
