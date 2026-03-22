import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipApplicationsContent/scholarship_applications_content.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipApplicationsList/scholarship_applications_list_controller.dart';

class ScholarshipApplicationsList extends StatefulWidget {
  final String docID;
  final List<String> basvuranlar;

  const ScholarshipApplicationsList({
    super.key,
    required this.docID,
    required this.basvuranlar,
  });

  @override
  State<ScholarshipApplicationsList> createState() =>
      _ScholarshipApplicationsListState();
}

class _ScholarshipApplicationsListState
    extends State<ScholarshipApplicationsList> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final ScholarshipApplicationsListController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'scholarship_applications_${widget.docID}_${identityHashCode(this)}';
    final existing = ScholarshipApplicationsListController.maybeFind(
      tag: _controllerTag,
    );
    _ownsController = existing == null;
    controller = existing ??
        ScholarshipApplicationsListController.ensure(
          tag: _controllerTag,
          docID: widget.docID,
          basvuranlar: widget.basvuranlar,
        );
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          ScholarshipApplicationsListController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<ScholarshipApplicationsListController>(
        tag: _controllerTag,
        force: true,
      );
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
            BackButtons(
                text: 'scholarship.applications_title'.trParams({
              'count': '${widget.basvuranlar.length}',
            })),
            Expanded(
              child: widget.basvuranlar.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.doc_text,
                            size: 60,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'scholarship.no_applications'.tr,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: controller.onRefresh,
                      child: ListView.builder(
                        itemCount: widget.basvuranlar.length,
                        itemBuilder: (context, index) {
                          return ScholarshipApplicationsContent(
                            userID: widget.basvuranlar[index],
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
