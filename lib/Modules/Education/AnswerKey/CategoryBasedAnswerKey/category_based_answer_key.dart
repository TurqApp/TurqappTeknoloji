import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletPreview/booklet_preview.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/CategoryBasedAnswerKey/category_based_answer_key_controller.dart';
import 'package:turqappv2/Themes/app_icons.dart';

class CategoryBasedAnswerKey extends StatefulWidget {
  final String sinavTuru;

  const CategoryBasedAnswerKey({super.key, required this.sinavTuru});

  @override
  State<CategoryBasedAnswerKey> createState() => _CategoryBasedAnswerKeyState();
}

class _CategoryBasedAnswerKeyState extends State<CategoryBasedAnswerKey> {
  late final CategoryBasedAnswerKeyController controller;
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'category_answer_key_${widget.sinavTuru.hashCode}_${identityHashCode(this)}';
    controller = Get.isRegistered<CategoryBasedAnswerKeyController>(
      tag: _controllerTag,
    )
        ? Get.find<CategoryBasedAnswerKeyController>(tag: _controllerTag)
        : Get.put(
            CategoryBasedAnswerKeyController(widget.sinavTuru),
            tag: _controllerTag,
          );
  }

  @override
  void dispose() {
    if (Get.isRegistered<CategoryBasedAnswerKeyController>(
            tag: _controllerTag) &&
        identical(
          Get.find<CategoryBasedAnswerKeyController>(tag: _controllerTag),
          controller,
        )) {
      Get.delete<CategoryBasedAnswerKeyController>(tag: _controllerTag);
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
            BackButtons(text: widget.sinavTuru),
            Expanded(
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 15, right: 15, bottom: 15),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Row(
                            children: [
                              Icon(AppIcons.search, color: Colors.pink),
                              SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 50,
                                  child: TextField(
                                    controller: controller.search,
                                    onChanged: controller.filterSearchResults,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(100),
                                    ],
                                    decoration: InputDecoration(
                                      hintText: 'common.search'.tr,
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                        fontFamily: "Montserrat",
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontFamily: "Montserrat",
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Obx(
                        () => controller.isLoading.value
                            ? Center(
                                child: CupertinoActivityIndicator(
                                  radius: 20,
                                  color: Colors.black,
                                ),
                              )
                            : controller.filteredList.isEmpty
                                ? Padding(
                                    padding: EdgeInsets.all(15),
                                    child: Text(
                                      'common.no_results'.tr,
                                      style: TextStyle(
                                        fontFamily: "Montserrat",
                                        fontSize: 15,
                                        color: Colors.black,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: controller.filteredList.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          left: 15,
                                          right: 15,
                                          bottom: 15,
                                        ),
                                        child: GestureDetector(
                                          onTap: () => Get.to(
                                            () => BookletPreview(
                                              model: controller
                                                  .filteredList[index],
                                            ),
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(12),
                                              ),
                                              border: Border.all(
                                                color: Colors.grey.withValues(
                                                  alpha: 0.2,
                                                ),
                                              ),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(12),
                                              child: Row(
                                                children: [
                                                  CachedNetworkImage(
                                                    imageUrl: controller
                                                        .filteredList[index]
                                                        .cover,
                                                    fit: BoxFit.contain,
                                                    height: 80,
                                                    placeholder:
                                                        (context, url) =>
                                                            const SizedBox(
                                                      height: 80,
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
                                                  SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          controller
                                                              .filteredList[
                                                                  index]
                                                              .baslik,
                                                          maxLines: 2,
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize: 18,
                                                            fontFamily:
                                                                "MontserratBold",
                                                          ),
                                                        ),
                                                        SizedBox(height: 4),
                                                        Text(
                                                          controller
                                                              .filteredList[
                                                                  index]
                                                              .basimTarihi,
                                                          style: TextStyle(
                                                            color:
                                                                Colors.indigo,
                                                            fontSize: 15,
                                                            fontFamily:
                                                                "MontserratMedium",
                                                          ),
                                                        ),
                                                        SizedBox(height: 4),
                                                        Text(
                                                          controller
                                                              .filteredList[
                                                                  index]
                                                              .yayinEvi,
                                                          style: TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 15,
                                                            fontFamily:
                                                                "MontserratBold",
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
                                      );
                                    },
                                  ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
