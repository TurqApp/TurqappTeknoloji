part of 'scholarship_detail_view.dart';

extension ScholarshipDetailViewActionsPart on ScholarshipDetailView {
  Widget _buildActionSection({
    required BuildContext context,
    required ScholarshipDetailController controller,
    required IndividualScholarshipsModel model,
    required Map<String, dynamic> scholarshipData,
    required String scholarshipDocId,
    required String type,
    required Map<String, dynamic> userData,
  }) {
    return Obx(() {
      final isLoading = controller.isLoading.value;
      final isOwnScholarship = userData['userID']?.toString() ==
          CurrentUserService.instance.effectiveUserId;

      // Tarih kontrolü
      bool isExpired = false;
      {
        if (model.bitisTarihi.isNotEmpty) {
          final df = DateFormat('dd.MM.yyyy');
          try {
            final d = df.parse(model.bitisTarihi);
            final endOfDay = DateTime(d.year, d.month, d.day, 23, 59, 59);
            isExpired = DateTime.now().isAfter(endOfDay);
          } catch (e) {
            print('Tarih parse hatası: $e');
            isExpired = false;
          }
        }
      }

      if (isOwnScholarship) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: AdmobKare(
                key: ValueKey('sch-detail-ad-owner'),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: isLoading
                        ? null
                        : () async {
                            final scholarshipId = scholarshipDocId;
                            if (scholarshipId.isEmpty) {
                              AppSnackbar(
                                'common.error'.tr,
                                'scholarship.share_missing_id'.tr,
                              );
                              return;
                            }
                            final basvuranlar =
                                await controller.getApplicantIds(
                              scholarshipId,
                            );
                            Get.to(
                              () => ScholarshipApplicationsList(
                                docID: scholarshipDocId,
                                basvuranlar: basvuranlar,
                              ),
                            );
                          },
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: isLoading
                          ? CupertinoActivityIndicator()
                          : scholarshipDocId.isEmpty
                              ? Text(
                                  'scholarship.applications_title'
                                      .trParams({'count': '0'}),
                                  textAlign: TextAlign.center,
                                  style: TextStyles.bold16White,
                                )
                              : FutureBuilder<int>(
                                  future: controller.getApplicantCount(
                                    scholarshipDocId,
                                  ),
                                  builder: (ctx, snap) {
                                    final count = snap.hasData ? snap.data! : 0;
                                    return Text(
                                      'scholarship.applications_title'
                                          .trParams({'count': '$count'}),
                                      textAlign: TextAlign.center,
                                      style: TextStyles.bold16White,
                                    );
                                  },
                                ),
                    ),
                  ),
                ),
                10.pw,
                Expanded(
                  child: GestureDetector(
                    onTap: isLoading
                        ? null
                        : () {
                            // Ensure fresh controller instance for edit screen
                            Get.delete<CreateScholarshipController>(
                                force: true);
                            Get.to(
                              () => CreateScholarshipView(),
                              arguments: {
                                'scholarshipData': scholarshipData,
                                'scholarshipId': scholarshipData['docId'],
                              },
                            );
                          },
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: isLoading
                          ? CupertinoActivityIndicator()
                          : Text(
                              'scholarship.edit_button'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: "MontserratBold",
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: AdmobKare(
              key: ValueKey('sch-detail-ad-apply'),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isExpired ||
                          isLoading ||
                          controller.allreadyApplied.value
                      ? null
                      : () async {
                          if (model.basvuruURL.isNotEmpty) {
                            final urlString =
                                ensureUrlHasScheme(model.basvuruURL);
                            final url = Uri.parse(urlString);
                            if (await canLaunchUrl(url)) {
                              await confirmAndLaunchExternalUrl(url);
                            } else {
                              AppSnackbar(
                                'common.error'.tr,
                                'scholarship.website_open_failed'.tr,
                              );
                            }
                          } else {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Scaffold(
                                  backgroundColor: Colors.transparent,
                                  body: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CupertinoActivityIndicator(
                                            color: Colors.grey),
                                        SizedBox(height: 10),
                                        Text(
                                          "scholarship.checking_info".tr,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: "MontserratMedium",
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );

                            if (controller.applyReady.value) {
                              await controller.applyForScholarship(
                                scholarshipData['docId'] ??
                                    scholarshipData['scholarshipId'] ??
                                    '',
                                type,
                              );
                              Navigator.of(context).pop();
                              await controller
                                  .checkIfUserAlreadyApplied(scholarshipData);
                            } else {
                              Navigator.of(context).pop();
                              showModalBottomSheet(
                                backgroundColor: Colors.white,
                                context: context,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                ),
                                builder: (BuildContext context) {
                                  return Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          "scholarship.info_missing_title".tr,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 18,
                                            fontFamily: "MontserratBold",
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          "scholarship.info_missing_body".tr,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                        SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Container(
                                                  height: 50,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey
                                                        .withAlpha(50),
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                12)),
                                                  ),
                                                  child: Text(
                                                    "common.cancel".tr,
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 15,
                                                      fontFamily:
                                                          "MontserratBold",
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () async {
                                                  Navigator.of(context).pop();
                                                  scholarshipsController
                                                      .settings(context);
                                                  controller
                                                      .checkUserApplicationReadiness();
                                                },
                                                child: Container(
                                                  height: 50,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: Colors.black,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                12)),
                                                  ),
                                                  child: Text(
                                                    "scholarship.update_my_info"
                                                        .tr,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontFamily:
                                                          "MontserratBold",
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }
                          }
                        },
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isExpired
                          ? Colors.red.shade700
                          : controller.allreadyApplied.value
                              ? Colors.grey
                              : Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isLoading
                        ? CupertinoActivityIndicator()
                        : Text(
                            isExpired
                                ? 'scholarship.closed'.tr
                                : controller.allreadyApplied.value
                                    ? 'scholarship.applied'.tr
                                    : 'common.apply'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                  ),
                ),
              ),
              if (controller.allreadyApplied.value &&
                  !isExpired &&
                  !isOwnScholarship) ...[
                SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: isLoading
                        ? null
                        : () {
                            noYesAlert(
                              title: "scholarship.cancel_apply_title".tr,
                              message: "scholarship.cancel_apply_body".tr,
                              cancelText: "common.cancel".tr,
                              yesText: "scholarship.cancel_apply_button".tr,
                              yesButtonColor: CupertinoColors.destructiveRed,
                              onYesPressed: () async {
                                await controller.cancelApplication(
                                  scholarshipData['docId'] ??
                                      scholarshipData['scholarshipId'] ??
                                      '',
                                  type,
                                );
                              },
                            );
                          },
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: isLoading
                          ? CupertinoActivityIndicator()
                          : Text(
                              'scholarship.cancel_apply_button'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: "MontserratBold",
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    });
  }
}
