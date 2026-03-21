import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Models/Education/booklet_result_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletResultPreview/booklet_result_preview.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletResultContent/booklet_result_content_controller.dart';

class BookletResultContent extends StatefulWidget {
  final BookletResultModel model;

  const BookletResultContent({super.key, required this.model});

  @override
  State<BookletResultContent> createState() => _BookletResultContentState();
}

class _BookletResultContentState extends State<BookletResultContent> {
  late final BookletResultContentController controller;
  late final String _controllerTag;

  BookletResultModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'booklet_result_content_${widget.model.kitapcikID}_${identityHashCode(this)}';
    controller = Get.isRegistered<BookletResultContentController>(
      tag: _controllerTag,
    )
        ? Get.find<BookletResultContentController>(tag: _controllerTag)
        : Get.put(
            BookletResultContentController(widget.model),
            tag: _controllerTag,
          );
  }

  @override
  void dispose() {
    if (Get.isRegistered<BookletResultContentController>(tag: _controllerTag) &&
        identical(
          Get.find<BookletResultContentController>(tag: _controllerTag),
          controller,
        )) {
      Get.delete<BookletResultContentController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15),
      child: GestureDetector(
        onTap: () {
          Get.to(() => BookletResultPreview(model: model));
        },
        child: Container(
          color: Colors.white.withValues(alpha: 0.00000001),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => controller.anaModel.value == null
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
                          "answer_key.answered_suffix".trParams({
                            "time": timeAgo(model.timeStamp),
                          }),
                          style: const TextStyle(
                            color: Colors.indigo,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                      Text(
                        "${model.dogru} ${'tests.correct'.tr}",
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${model.yanlis} ${'tests.wrong'.tr}",
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${model.bos} ${'tests.blank'.tr}",
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
              Divider(color: Colors.grey.withValues(alpha: 0.2)),
            ],
          ),
        ),
      ),
    );
  }
}
