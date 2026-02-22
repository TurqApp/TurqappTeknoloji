import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/External.dart';
import 'package:turqappv2/Models/Education/BookletResultModel.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletResultPreview/BookletResultPreview.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletResultContent/BookletResultContentController.dart';

class BookletResultContent extends StatelessWidget {
  final BookletResultModel model;

  const BookletResultContent({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      BookletResultContentController(model),
      tag: model.kitapcikID,
    );

    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15),
      child: GestureDetector(
        onTap: () {
          Get.to(() => BookletResultPreview(model: model));
        },
        child: Container(
          color: Colors.white.withOpacity(0.00000001),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () =>
                              controller.anaModel.value == null
                                  ? CupertinoActivityIndicator()
                                  : Text(
                                    controller.anaModel.value!.yayinEvi,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontFamily: "MontserratBold",
                                    ),
                                  ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.indigo,
                        size: 12,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    model.baslik,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${timeAgo(model.timeStamp)} cevaplandı",
                          style: const TextStyle(
                            color: Colors.indigo,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                      Text(
                        "${model.dogru.toString()} D",
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${model.yanlis.toString()} Y",
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${model.bos.toString()} B",
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Divider(color: Colors.grey.withOpacity(0.2)),
            ],
          ),
        ),
      ),
    );
  }
}
