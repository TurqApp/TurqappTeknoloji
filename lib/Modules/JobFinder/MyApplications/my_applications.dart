import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Models/job_application_model.dart';
import 'my_applications_controller.dart';

class MyApplications extends StatefulWidget {
  const MyApplications({super.key});

  @override
  State<MyApplications> createState() => _MyApplicationsState();
}

class _MyApplicationsState extends State<MyApplications> {
  late final String _controllerTag;
  late final MyApplicationsController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'my_applications_${identityHashCode(this)}';
    _ownsController =
        MyApplicationsController.maybeFind(tag: _controllerTag) == null;
    controller = MyApplicationsController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          MyApplicationsController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<MyApplicationsController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 52,
        titleSpacing: 8,
        leading: const AppBackButton(),
        title: AppPageTitle('pasaj.job_finder.my_applications'.tr),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CupertinoActivityIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.loadApplications,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 24),
            children: [
              if (controller.applications.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: EmptyRow(text: "pasaj.job_finder.no_applications".tr),
                )
              else
                ...controller.applications.map(
                  (app) => _applicationCard(app, context),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _applicationCard(JobApplicationModel app, BuildContext context) {
    final status = app.status;
    final canCancel = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: app.companyLogo.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: app.companyLogo,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _fallbackLogo(),
                        )
                      : _fallbackLogo(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.jobTitle.isNotEmpty
                          ? app.jobTitle
                          : 'pasaj.job_finder.default_job_title'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.companyName.isNotEmpty
                          ? app.companyName
                          : 'pasaj.job_finder.default_company'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _statusChip(status),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatDate(
                              app.statusUpdatedAt > 0
                                  ? app.statusUpdatedAt
                                  : app.timeStamp,
                            ),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              canCancel
                  ? AppHeaderActionButton(
                      onTap: () => _showCancelDialog(app.jobDocID, context),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        color: Color(0xFFB91C1C),
                        size: 18,
                      ),
                    )
                  : AppHeaderActionButton(
                      child: Icon(
                        _statusIcon(status),
                        color: _statusColor(status),
                        size: 18,
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackLogo() {
    return Container(
      color: Colors.grey.withAlpha(30),
      child: const Icon(
        CupertinoIcons.building_2_fill,
        color: Colors.grey,
        size: 24,
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'reviewing':
        bgColor = Colors.blue.withAlpha(25);
        textColor = Colors.blue;
        break;
      case 'accepted':
        bgColor = Colors.green.withAlpha(25);
        textColor = Colors.green;
        break;
      case 'rejected':
        bgColor = Colors.red.withAlpha(25);
        textColor = Colors.red;
        break;
      default: // pending
        bgColor = Colors.orange.withAlpha(25);
        textColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        JobApplicationModel.statusText(status),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontFamily: "MontserratMedium",
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'reviewing':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return const Color(0xFFB91C1C);
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'accepted':
        return CupertinoIcons.check_mark_circled_solid;
      case 'rejected':
        return CupertinoIcons.xmark_circle_fill;
      case 'reviewing':
        return CupertinoIcons.clock_fill;
      default:
        return CupertinoIcons.xmark;
    }
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }

  void _showCancelDialog(String jobDocID, BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text("pasaj.job_finder.cancel_apply_title".tr,
            style: TextStyle(fontFamily: "MontserratBold", fontSize: 16)),
        content: Text("pasaj.job_finder.cancel_apply_body".tr,
            style: TextStyle(fontFamily: "MontserratMedium", fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("common.cancel".tr,
                style: TextStyle(fontFamily: "MontserratMedium")),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.cancelApplication(jobDocID);
            },
            child: Text("common.remove".tr,
                style:
                    TextStyle(color: Colors.red, fontFamily: "MontserratBold")),
          ),
        ],
      ),
    );
  }
}
