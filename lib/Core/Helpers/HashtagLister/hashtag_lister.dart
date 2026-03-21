import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'hashtag_lister_controller.dart';

class Hashtaglister extends StatefulWidget {
  final Function(String) onTapSelected;

  const Hashtaglister({super.key, required this.onTapSelected});

  @override
  State<Hashtaglister> createState() => _HashtaglisterState();
}

class _HashtaglisterState extends State<Hashtaglister> {
  late final String _controllerTag;
  late final HashtagListerController controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'hashtag_lister_${identityHashCode(this)}';
    _ownsController =
        HashtagListerController.maybeFind(tag: _controllerTag) == null;
    controller = HashtagListerController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          HashtagListerController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<HashtagListerController>(tag: _controllerTag);
    }
    super.dispose();
  }

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
              controller.hashtags
                  .removeAt(index); // Doğrudan RxList üzerinde işlem
              widget.onTapSelected(model.hashtag); // Seçim bilgisi gönder
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 7, horizontal: 15),
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
                        "${model.count} ${'common.views'.tr}",
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
