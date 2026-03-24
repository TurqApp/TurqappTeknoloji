import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';
import 'package:turqappv2/Modules/Education/Tests/CreateTest/create_test_controller.dart';

part 'create_test_body_part.dart';
part 'create_test_subjects_part.dart';
part 'create_test_picker_part.dart';
part 'create_test_shell_part.dart';

class CreateTest extends StatefulWidget {
  final TestsModel? model;

  const CreateTest({super.key, this.model});

  @override
  State<CreateTest> createState() => _CreateTestState();
}

class _CreateTestState extends State<CreateTest> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final CreateTestController controller;

  TestsModel? get model => widget.model;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'create_test_${widget.model?.docID ?? 'new'}_${identityHashCode(this)}';
    _ownsController =
        CreateTestController.maybeFind(tag: _controllerTag) == null;
    controller = CreateTestController.ensure(model, tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController =
          CreateTestController.maybeFind(tag: _controllerTag);
      if (identical(registeredController, controller)) {
        Get.delete<CreateTestController>(tag: _controllerTag, force: true);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
