import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Widgets/skeleton_loader.dart';
import 'package:turqappv2/Modules/Education/Tests/SearchTests/search_tests_controller.dart';
import 'package:turqappv2/Modules/Education/Tests/TestsGrid/tests_grid.dart';
import 'package:turqappv2/Themes/app_icons.dart';

part 'search_tests_shell_part.dart';
part 'search_tests_content_part.dart';

class SearchTests extends StatefulWidget {
  const SearchTests({super.key});

  @override
  State<SearchTests> createState() => _SearchTestsState();
}

class _SearchTestsState extends State<SearchTests> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final SearchTestsController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'tests_search_${identityHashCode(this)}';
    _ownsController =
        SearchTestsController.maybeFind(tag: _controllerTag) == null;
    controller = SearchTestsController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController =
          SearchTestsController.maybeFind(tag: _controllerTag);
      if (identical(registeredController, controller)) {
        Get.delete<SearchTestsController>(tag: _controllerTag, force: true);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildPage();
  }
}
