import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/date_picker_bottom_sheet.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Utils/turkish_sort.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/PersonelInfo/personel_info_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'personel_info_view_actions_part.dart';
part 'personel_info_view_content_part.dart';

class PersonelInfoView extends StatefulWidget {
  PersonelInfoView({super.key});

  @override
  State<PersonelInfoView> createState() => _PersonelInfoViewState();
}

class _PersonelInfoViewState extends State<PersonelInfoView> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final PersonelInfoController controller;
  final UserRepository _userRepository = UserRepository.ensure();

  @override
  void initState() {
    super.initState();
    _controllerTag = 'scholarship_personal_${identityHashCode(this)}';
    final existing = maybeFindPersonelInfoController(tag: _controllerTag);
    _ownsController = existing == null;
    controller = existing ?? ensurePersonelInfoController(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindPersonelInfoController(tag: _controllerTag),
          controller,
        )) {
      Get.delete<PersonelInfoController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
