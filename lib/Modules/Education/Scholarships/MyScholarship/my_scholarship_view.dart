import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/Education/Scholarships/MyScholarship/my_scholarship_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipDetail/scholarship_detail_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipDetail/scholarship_detail_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarship_type_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class MyScholarshipView extends StatefulWidget {
  MyScholarshipView({super.key});

  @override
  State<MyScholarshipView> createState() => _MyScholarshipViewState();
}

class _MyScholarshipViewState extends State<MyScholarshipView> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final MyScholarshipController controller;
  late final bool _ownsDetailController;
  late final ScholarshipDetailController detailController;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'scholarship_my_${identityHashCode(this)}';
    _ownsController =
        !Get.isRegistered<MyScholarshipController>(tag: _controllerTag);
    controller = _ownsController
        ? Get.put(MyScholarshipController(), tag: _controllerTag)
        : Get.find<MyScholarshipController>(tag: _controllerTag);
    _ownsDetailController = !Get.isRegistered<ScholarshipDetailController>();
    detailController = _ownsDetailController
        ? Get.put(ScholarshipDetailController())
        : Get.find<ScholarshipDetailController>();
  }

  @override
  void dispose() {
    if (_ownsController &&
        Get.isRegistered<MyScholarshipController>(tag: _controllerTag)) {
      final registeredController =
          Get.find<MyScholarshipController>(tag: _controllerTag);
      if (identical(registeredController, controller)) {
        Get.delete<MyScholarshipController>(tag: _controllerTag, force: true);
      }
    }
    if (_ownsDetailController && Get.isRegistered<ScholarshipDetailController>()) {
      final registeredController = Get.find<ScholarshipDetailController>();
      if (identical(registeredController, detailController)) {
        Get.delete<ScholarshipDetailController>(force: true);
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
            BackButtons(text: 'scholarship.my_listings'.tr),
            Expanded(
              child: Obx(
                () => controller.isLoading.value &&
                        controller.myScholarships.isEmpty
                    ? Center(child: CupertinoActivityIndicator())
                    : controller.myScholarships.isEmpty
                        ? EmptyRow(text: 'scholarship.no_my_listings'.tr)
                        : ListView.builder(
                            itemCount: controller.myScholarships.length,
                            itemBuilder: (context, index) {
                              final scholarshipData =
                                  controller.myScholarships[index];
                              final burs = scholarshipData['model'];
                              final type = scholarshipData['type'] as String;
                              final userData = scholarshipData['userData']
                                  as Map<String, dynamic>?;
                              final firmaData = scholarshipData['firmaData']
                                  as Map<String, dynamic>?;

                              return Container(
                                margin: EdgeInsets.only(
                                    left: 10, right: 10, bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    Get.to(
                                      () => ScholarshipDetailView(),
                                      arguments: scholarshipData,
                                    );
                                  },
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Görsel (solda)
                                      Container(
                                        width: Get.width / 4,
                                        height: (Get.width / 4) * (3 / 4),
                                        margin: EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: burs.img.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: burs.img,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) =>
                                                      Center(
                                                    child:
                                                        CupertinoActivityIndicator(),
                                                  ),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          Icon(
                                                    Icons.error,
                                                    color: Colors.red,
                                                    size: 40,
                                                  ),
                                                )
                                              : Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade200,
                                                  ),
                                                  child: Icon(
                                                    Icons.image,
                                                    color: Colors.grey,
                                                    size: 40,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      // Metinler (sağda, alt alta)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            10.ph,
                                            Text(
                                              isIndividualScholarshipType(type)
                                                  ? 'scholarship.applications_suffix'
                                                      .trParams({
                                                      'title': burs.baslik,
                                                    })
                                                  : burs.baslik,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontFamily: 'MontserratBold',
                                                color: Colors.black,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  isIndividualScholarshipType(
                                                          type)
                                                      ? (userData?['nickname']
                                                                  ?.isNotEmpty ??
                                                              false
                                                          ? userData![
                                                              'nickname']
                                                          : 'common.unknown_user'
                                                              .tr)
                                                      : (firmaData?['adi']
                                                                  ?.isNotEmpty ??
                                                              false
                                                          ? firmaData!['adi']
                                                          : 'common.unknown_company'
                                                              .tr),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontFamily:
                                                        'MontserratMedium',
                                                    color: Colors.blue.shade900,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                RozetContent(
                                                  size: 15,
                                                  userID: CurrentUserService
                                                      .instance.userId,
                                                ),
                                              ],
                                            ),
                                            4.ph,
                                            Text(
                                              burs.aciklama,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontFamily: 'Montserrat',
                                                color: Colors.black,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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
    );
  }
}
