import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeGrid/deneme_grid.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SearchDeneme/search_deneme_controller.dart';

part 'search_deneme_shell_part.dart';
part 'search_deneme_content_part.dart';

class SearchDeneme extends StatefulWidget {
  const SearchDeneme({super.key});

  @override
  State<SearchDeneme> createState() => _SearchDenemeState();
}

class _SearchDenemeState extends State<SearchDeneme> {
  late final SearchDenemeController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    final existing = SearchDenemeController.maybeFind();
    _ownsController = existing == null;
    controller = existing ?? SearchDenemeController.ensure();
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(SearchDenemeController.maybeFind(), controller)) {
      Get.delete<SearchDenemeController>();
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
            BackButtons(text: 'practice.search_title'.tr),
            _buildSearchShell(),
            Expanded(
              child: Obx(() {
                return _buildSearchContent();
              }),
            ),
          ],
        ),
      ),
    );
  }
}
