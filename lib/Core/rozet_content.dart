import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RozetController extends GetxController {
  final String userID;
  RozetController(this.userID);

  Rx<Color> color = Colors.transparent.obs;

  @override
  void onInit() {
    super.onInit();
    fetchRozet();
  }

  void fetchRozet() async {
    final doc =
        await FirebaseFirestore.instance.collection("users").doc(userID).get();

    if (doc.exists) {
      final rozet = doc.get("rozet") ?? "";

      switch (rozet) {
        case "Kirmizi":
          color.value = Colors.red;
          break;
        case "Mavi":
          color.value = Colors.blue;
          break;
        case "Sari":
          color.value = Colors.orange;
          break;
        case "Siyah":
          color.value = Colors.black;
          break;
        case "Gri":
          color.value = Colors.grey;
          break;
        case "Turkuaz":
          color.value = const Color(0xFF40E0D0);
          break;
        default:
          color.value = Colors.transparent;
      }
    }
  }

  void updateUserID(String newUserID) {
    if (newUserID != userID) {
      fetchRozet();
    }
  }
}

class RozetContent extends StatelessWidget {
  final double size;
  final String userID;

  const RozetContent({
    super.key,
    required this.size,
    required this.userID,
  });

  @override
  Widget build(BuildContext context) {
    final tag = "rozet_$userID";
    final controller = Get.put(RozetController(userID), tag: tag);

    return Obx(() {
      final color = controller.color.value;
      return controller.color.value != Colors.transparent
          ? Transform.translate(
              offset: const Offset(0, -1),
              child: Stack(
                children: [
                  if (color != Colors.transparent)
                    Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: size - 7,
                            height: size - 7,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Icon(
                            CupertinoIcons.checkmark_seal_fill,
                            color: color,
                            size: size,
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(width: 2),
                ],
              ),
            )
          : SizedBox();
    });
  }
}
