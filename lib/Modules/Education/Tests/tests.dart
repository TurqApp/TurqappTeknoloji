import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/Slider/education_slider.dart';
import 'package:turqappv2/Modules/Education/Tests/CreateTest/create_test.dart';
import 'package:turqappv2/Modules/Education/Tests/LessonsBasedTests/lesson_based_tests.dart';
import 'package:turqappv2/Modules/Education/Tests/MyTestResults/my_test_results.dart';
import 'package:turqappv2/Modules/Education/Tests/MyTests/my_tests.dart';
import 'package:turqappv2/Modules/Education/Tests/SavedTests/saved_tests.dart';
import 'package:turqappv2/Modules/Education/Tests/SearchTests/search_tests.dart';
import 'package:turqappv2/Modules/Education/Tests/TestEntry/test_entry.dart';
import 'package:turqappv2/Modules/Education/Tests/tests_controller.dart';
import 'package:turqappv2/Modules/Education/Tests/TestsGrid/tests_grid.dart';
import 'package:turqappv2/Modules/TypeWriter/type_writer.dart';
import 'package:turqappv2/Themes/app_assets.dart';
import 'package:turqappv2/Core/Widgets/skeleton_loader.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'tests_shell_part.dart';
part 'tests_shell_content_part.dart';
part 'tests_sections_part.dart';

class Tests extends StatefulWidget {
  const Tests({
    super.key,
    this.embedded = false,
    this.showEmbeddedControls = true,
  });
  final bool embedded;
  final bool showEmbeddedControls;

  @override
  State<Tests> createState() => _TestsState();
}

class _TestsState extends State<Tests> {
  late final TestsController controller;
  late final String _controllerTag;
  ScrollController get _scrollController => controller.scrollController;

  bool get embedded => widget.embedded;
  bool get showEmbeddedControls => widget.showEmbeddedControls;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'tests_${embedded ? 'embedded' : 'root'}_${identityHashCode(this)}';
    controller = ensureTestsController(tag: _controllerTag);
  }

  @override
  void dispose() {
    final existing = maybeFindTestsController(tag: _controllerTag);
    if (identical(existing, controller)) {
      Get.delete<TestsController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildPage(context);
  }
}
