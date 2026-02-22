import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/External.dart';
import 'package:turqappv2/Models/Education/TestsModel.dart';
import 'package:turqappv2/Modules/Education/Tests/MyPastTestResultsPreview.dart/MyPastTestResultsPreview.dart';
import 'package:turqappv2/Modules/Education/Tests/TestPastResultContent/TestPastResultContentController.dart';

class TestPastResultContent extends StatelessWidget {
  final TestsModel model;
  final int index;

  const TestPastResultContent({
    super.key,
    required this.index,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      TestPastResultContentController(model),
      tag: 'controller_${model.docID}_$index',
    );

    return Obx(
      () => controller.isLoading.value
          ? Padding(
              padding: EdgeInsets.all(15),
              child: Center(child: CupertinoActivityIndicator()),
            )
          : controller.count.value == 0
              ? Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, color: Colors.black, size: 40),
                      SizedBox(height: 10),
                      Text(
                        "Sonuç bulunamadı.\nBu test için yanıt verisi mevcut değil.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "Montserrat",
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    GestureDetector(
                      onTap: () => Get.to(
                        () => MyPastTestResultsPreview(model: model),
                      ),
                      child: Container(
                        margin:
                            EdgeInsets.only(left: 15, right: 15, bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.all(
                            Radius.circular(12),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 15,
                            right: 15,
                            top: 15,
                            bottom: 7,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(3),
                                ),
                                child: SizedBox(
                                  width: 75,
                                  height: 75,
                                  child: Image.network(
                                    model.img,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${model.testTuru} Testi",
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontFamily: "MontserratBold",
                                      ),
                                    ),
                                    Text(
                                      "${model.aciklama} Testi",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontFamily: "MontserratMedium",
                                      ),
                                    ),
                                    Text(
                                      timeAgo(controller.timeStamp.value),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontFamily: "MontserratMedium",
                                      ),
                                    ),
                                    if (controller.count.value != 0)
                                      Text(
                                        "${controller.count.value}. kez çözdün",
                                        style: TextStyle(
                                          color: Colors.indigo,
                                          fontSize: 12,
                                          fontFamily: "MontserratMedium",
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
                  ],
                ),
    );
  }
}
