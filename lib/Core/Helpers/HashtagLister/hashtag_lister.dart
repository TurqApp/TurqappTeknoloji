import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'hashtag_lister_controller.dart';

class Hashtaglister extends StatelessWidget {
  final Function(String) onTapSelected;

  Hashtaglister({super.key, required this.onTapSelected});

  final controller = Get.put(HashtagListerController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: controller.hashtags.length,
        itemBuilder: (context, index) {
          final model = controller.hashtags[index];
          return TextButton(
            onPressed: () {
              controller.hashtags.removeAt(index); // Doğrudan RxList üzerinde işlem
              onTapSelected(model.hashtag); // Seçim bilgisi gönder
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            model.hashtag,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "${model.count} görüntüleme",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "Montserrat", // typo düzeltilmiş
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Divider(height: 1, color: Colors.grey.withAlpha(20)),
                )
              ],
            ),
          );
        },
      );
    });
  }
}
