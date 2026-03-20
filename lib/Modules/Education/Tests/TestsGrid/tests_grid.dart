import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:svg_flutter/svg.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';
import 'package:turqappv2/Modules/Education/Tests/TestsGrid/tests_grid_controller.dart';

class TestsGrid extends StatelessWidget {
  final TestsModel model;
  final Function? update;

  const TestsGrid({super.key, required this.model, this.update});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      TestsGridController(model, update),
      tag: model.docID,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: Padding(
              padding: EdgeInsets.only(left: 10, right: 5),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.navigateToProfile(context),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            child: SizedBox(
                              width: 23,
                              height: 23,
                              child: Obx(
                                () => controller.avatarUrl.value.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: controller.avatarUrl.value,
                                        fit: BoxFit.cover,
                                      )
                                    : Center(
                                        child: CupertinoActivityIndicator(),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(width: 7),
                          Expanded(
                            child: Obx(() => Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        controller.nickname.value,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontFamily: "MontserratBold",
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    RozetContent(
                                        size: 12, userID: model.userID),
                                  ],
                                )),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (model.userID != FirebaseAuth.instance.currentUser!.uid)
                    GestureDetector(
                      onTap: () => controller.showReportModal(context),
                      child: Icon(
                        Icons.more_vert,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => controller.handleTestAction(context),
            child: AspectRatio(
              aspectRatio: 1,
              child: model.img.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: model.img,
                      fit: BoxFit.cover,
                    )
                  : Center(child: CupertinoActivityIndicator()),
            ),
          ),
          SizedBox(height: 7),
          GestureDetector(
            onTap: () => controller.handleTestAction(context),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "tests.type_test".trParams({
                          "type": model.testTuru,
                        }),
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                      GestureDetector(
                        onTap: controller.toggleFavorite,
                        child: Obx(
                          () => Icon(
                            controller.isFavorite.value
                                ? CupertinoIcons.bookmark_fill
                                : CupertinoIcons.bookmark,
                            color: controller.isFavorite.value
                                ? Colors.orange
                                : Colors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Text(
                    model.aciklama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                  SizedBox(height: 7),
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "tests.level_easy".tr,
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              controller.totalYanit.value * 9 / 1000000 > 1
                                  ? "${((controller.totalYanit.value * 9) / 1000000).toStringAsFixed(2)}M"
                                  : controller.totalYanit.value * 9 / 1000 > 1
                                      ? "${((controller.totalYanit.value * 9) / 1000).toStringAsFixed(1)}B"
                                      : (controller.totalYanit.value * 9)
                                          .toString(),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: SvgPicture.asset(
                                "icons/statsyeni.svg",
                                height: 20,
                                colorFilter: const ColorFilter.mode(
                                    Colors.black, BlendMode.srcIn),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (model.userID == FirebaseAuth.instance.currentUser!.uid)
                    Padding(
                      padding: EdgeInsets.only(top: 17),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => controller.copyTestId(context),
                            child: Text(
                              "ID: ${model.docID}",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => controller.copyTestId(context),
                            child: Icon(
                              CupertinoIcons.doc_on_doc,
                              color: Colors.pink,
                              size: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
          SizedBox(height: 7),
          if (model.userID != FirebaseAuth.instance.currentUser!.uid)
            GestureDetector(
              onTap: () => controller.navigateToTestSolve(context),
              child: Padding(
                padding: EdgeInsets.only(left: 8, right: 8, bottom: 8),
                child: Container(
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.pink,
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                  ),
                  child: Text(
                    "tests.start_now".tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
