import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:svg_flutter/svg.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';
import 'package:turqappv2/Modules/Education/Tests/TestsGrid/tests_grid_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'tests_grid_header_part.dart';
part 'tests_grid_body_part.dart';

class TestsGrid extends StatefulWidget {
  final TestsModel model;
  final Function? update;

  const TestsGrid({super.key, required this.model, this.update});

  @override
  State<TestsGrid> createState() => _TestsGridState();
}

class _TestsGridState extends State<TestsGrid> {
  late final TestsGridController controller;
  late final String _controllerTag;
  late final bool _ownsController;

  TestsModel get model => widget.model;
  Function? get update => widget.update;

  String get _currentUserId => CurrentUserService.instance.effectiveUserId;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'tests_grid_${widget.model.docID}_${identityHashCode(this)}';
    _ownsController = maybeFindTestsGridController(tag: _controllerTag) == null;
    controller = ensureTestsGridController(
      widget.model,
      onUpdate: widget.update,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController =
          maybeFindTestsGridController(tag: _controllerTag);
      if (identical(registeredController, controller)) {
        Get.delete<TestsGridController>(tag: _controllerTag);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildCard(context);
}
