import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/page_line_bar.dart';

import '../JobContent/job_content.dart';
import 'my_job_ads_controller.dart';

part 'my_job_ads_shell_part.dart';
part 'my_job_ads_content_part.dart';

class MyJobAds extends StatefulWidget {
  MyJobAds({super.key});

  @override
  State<MyJobAds> createState() => _MyJobAdsState();
}

class _MyJobAdsState extends State<MyJobAds> {
  late final MyJobAdsController controller;
  late final String _controllerTag = 'my_job_ads_${identityHashCode(this)}';
  late final String _pageLineBarTag = 'MyJobAds_${identityHashCode(this)}';
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _ownsController = MyJobAdsController.maybeFind(tag: _controllerTag) == null;
    controller = MyJobAdsController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          MyJobAdsController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<MyJobAdsController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildMyJobAdsBody(),
    );
  }
}
