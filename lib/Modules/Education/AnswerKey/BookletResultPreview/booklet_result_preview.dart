import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/booklet_result_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletResultPreview/booklet_result_preview_controller.dart';

class BookletResultPreview extends StatelessWidget {
  final BookletResultModel model;

  const BookletResultPreview({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BookletResultPreviewController(model));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              height: 70,
              decoration: const BoxDecoration(color: Colors.white),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_back, color: Colors.black),
                          SizedBox(width: 12),
                          Text(
                            "tests.results_title".tr,
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 25,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  itemCount: model.dogruCevaplar.length + 1,
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
                                              placeholder:
                                                  (context, url) =>
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
                                                    model.baslik,
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
                                          model.dogru.toString(),
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
                                          model.yanlis.toString(),
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
                                          model.bos.toString(),
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
                                    color: model.cevaplar[realindex] == ""
                                        ? (model.dogruCevaplar[realindex] ==
                                                item
                                            ? Colors.green
                                            : Colors.orange)
                                        : model.cevaplar[realindex] ==
                                                    model.dogruCevaplar[
                                                        realindex] &&
                                                model.cevaplar[realindex] ==
                                                    item
                                            ? Colors.green
                                            : model.cevaplar[realindex] !=
                                                        model.dogruCevaplar[
                                                            realindex] &&
                                                    model.dogruCevaplar[
                                                            realindex] ==
                                                        item
                                                ? Colors.green
                                                : model.cevaplar[realindex] ==
                                                        item
                                                    ? Colors.red
                                                    : Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      color: model.cevaplar[realindex] == "" ||
                                              model.cevaplar[realindex] == item
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
