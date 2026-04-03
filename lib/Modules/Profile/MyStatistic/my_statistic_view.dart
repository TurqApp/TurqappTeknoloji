import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/formatters.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/Profile/MyStatistic/my_statistic_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'my_statistic_view_content_part.dart';

class MyStatisticView extends StatefulWidget {
  const MyStatisticView({super.key});

  @override
  State<MyStatisticView> createState() => _MyStatisticViewState();
}

class _MyStatisticViewState extends State<MyStatisticView> {
  late final MyStatisticController controller;
  late final String _controllerTag;
  final userService = CurrentUserService.instance;
  static const List<Color> _statColors = [
    Color(0xFF1E88E5),
    Color(0xFFF4511E),
    Color(0xFFE91E63),
    Color(0xFF43A047),
    Color(0xFFFB8C00),
    Color(0xFF8E24AA),
    Color(0xFF00897B),
    Color(0xFFFFC107),
    Color(0xFF3949AB),
    Color(0xFFD32F2F),
    Color(0xFF303F9F),
    Color(0xFF03A9F4),
    Color(0xFFCDDC39),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFFE64A19),
    Color(0xFF512DA8),
    Color(0xFF0097A7),
  ];

  String get _currentUid => userService.effectiveUserId;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'my_statistic_${identityHashCode(this)}';
    controller = ensureMyStatisticController(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (maybeFindMyStatisticController(tag: _controllerTag) != null &&
        identical(
          maybeFindMyStatisticController(tag: _controllerTag),
          controller,
        )) {
      Get.delete<MyStatisticController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          return RefreshIndicator(
            backgroundColor: Colors.black,
            color: Colors.white,
            onRefresh: controller.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  BackButtons(text: 'statistics.title'.tr),
                  if (controller.isLoading.value)
                    const Padding(
                      padding: EdgeInsets.all(15),
                      child: Center(child: CupertinoActivityIndicator()),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: _buildMyStatisticContent(),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
