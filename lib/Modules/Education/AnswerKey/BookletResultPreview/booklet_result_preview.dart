import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Models/Education/booklet_result_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletResultPreview/booklet_result_preview_controller.dart';

class BookletResultPreview extends StatefulWidget {
  final BookletResultModel model;

  const BookletResultPreview({super.key, required this.model});

  @override
  State<BookletResultPreview> createState() => _BookletResultPreviewState();
}

class _BookletResultPreviewState extends State<BookletResultPreview> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final BookletResultPreviewController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'booklet_result_preview_${widget.model.docID}_${identityHashCode(this)}';
    _ownsController =
        BookletResultPreviewController.maybeFind(tag: _controllerTag) == null;
    controller = BookletResultPreviewController.ensure(
      widget.model,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController = BookletResultPreviewController.maybeFind(
        tag: _controllerTag,
      );
      if (identical(registeredController, controller)) {
        Get.delete<BookletResultPreviewController>(
          tag: _controllerTag,
          force: true,
        );
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              height: 70,
              decoration: const BoxDecoration(color: Colors.white),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: const Row(
                children: [
                  AppBackButton(icon: Icons.arrow_back),
                  SizedBox(width: 8),
                  Expanded(
                    child: AppPageTitle(
                      "tests.results_title",
                      translate: true,
                      fontSize: 25,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  itemCount: widget.model.dogruCevaplar.length + 1,
                  itemBuilder: (context, index) {
                    final realindex = index - 1;
                    if (index == 0) {
                      return Column(
                        children: [
                          Obx(
                            () => controller.anaModel.value == null
                                ? const Center(
                                    child: CupertinoActivityIndicator(),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                        border: Border.all(
                                          color: Colors.grey
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(15),
                                        child: Row(
                                          children: [
                                            CachedNetworkImage(
                                              imageUrl: controller
                                                  .anaModel.value!.cover,
                                              fit: BoxFit.contain,
                                              height: 50,
                                              placeholder: (context, url) =>
                                                  const SizedBox(
                                                height: 50,
                                                child: Center(
                                                  child:
                                                      CupertinoActivityIndicator(),
                                                ),
                                              ),
                                              errorWidget: (
                                                context,
                                                url,
                                                error,
                                              ) =>
                                                  const Icon(
                                                Icons.broken_image,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    controller
                                                        .anaModel.value!.baslik,
                                                    maxLines: 1,
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 15,
                                                      fontFamily:
                                                          'MontserratBold',
                                                    ),
                                                  ),
                                                  Text(
                                                    controller.anaModel.value!
                                                        .yayinEvi,
                                                    maxLines: 1,
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 15,
                                                      fontFamily:
                                                          'MontserratMedium',
                                                    ),
                                                  ),
                                                  Text(
                                                    widget.model.baslik,
                                                    maxLines: 1,
                                                    style: const TextStyle(
                                                      color: Colors.indigo,
                                                      fontSize: 15,
                                                      fontFamily:
                                                          'MontserratBold',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                          SizedBox(
                            height: 70,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    color: Colors.green,
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "tests.correct".tr,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          widget.model.dogru.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontFamily: "MontserratBold",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    color: Colors.red,
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "tests.wrong".tr,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          widget.model.yanlis.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontFamily: "MontserratBold",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    color: Colors.orange,
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "tests.blank".tr,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          widget.model.bos.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontFamily: "MontserratBold",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.pink.withValues(
                            alpha: index % 2 == 0 ? 0.2 : 0.4,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${realindex + 1}.",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                              for (var item in ["A", "B", "C", "D", "E"])
                                Container(
                                  width: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: widget.model.cevaplar[realindex] ==
                                            ""
                                        ? (widget.model.dogruCevaplar[realindex] ==
                                                item
                                            ? Colors.green
                                            : Colors.orange)
                                        : widget.model.cevaplar[realindex] ==
                                                    widget.model.dogruCevaplar[
                                                        realindex] &&
                                                widget.model.cevaplar[realindex] ==
                                                    item
                                            ? Colors.green
                                            : widget.model.cevaplar[realindex] !=
                                                        widget.model.dogruCevaplar[
                                                            realindex] &&
                                                    widget.model.dogruCevaplar[
                                                            realindex] ==
                                                        item
                                                ? Colors.green
                                                : widget.model.cevaplar[realindex] == item
                                                    ? Colors.red
                                                    : Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      color: widget.model.cevaplar[realindex] ==
                                                  "" ||
                                              widget.model
                                                      .cevaplar[realindex] ==
                                                  item
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 20,
                                      fontFamily: "MontserratBold",
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
