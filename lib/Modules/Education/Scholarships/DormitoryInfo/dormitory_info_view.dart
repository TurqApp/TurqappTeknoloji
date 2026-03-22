import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Modules/Education/Scholarships/DormitoryInfo/dormitory_info_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'dormitory_info_view_actions_part.dart';
part 'dormitory_info_view_content_part.dart';

class DormitoryInfoView extends StatefulWidget {
  DormitoryInfoView({super.key});

  @override
  State<DormitoryInfoView> createState() => _DormitoryInfoViewState();
}

class _DormitoryInfoViewState extends State<DormitoryInfoView> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final DormitoryInfoController controller;
  final UserRepository _userRepository = UserRepository.ensure();

  @override
  void initState() {
    super.initState();
    _controllerTag = 'scholarship_dormitory_${identityHashCode(this)}';
    final existing = DormitoryInfoController.maybeFind(tag: _controllerTag);
    _ownsController = existing == null;
    controller =
        existing ?? DormitoryInfoController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          DormitoryInfoController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<DormitoryInfoController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
