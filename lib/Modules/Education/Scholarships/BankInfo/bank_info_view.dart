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
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/Scholarships/BankInfo/bank_info_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'bank_info_view_actions_part.dart';
part 'bank_info_view_content_part.dart';

class BankInfoView extends StatefulWidget {
  BankInfoView({super.key});

  @override
  State<BankInfoView> createState() => _BankInfoViewState();
}

class _BankInfoViewState extends State<BankInfoView> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final BankInfoController controller;
  final UserRepository _userRepository = UserRepository.ensure();

  @override
  void initState() {
    super.initState();
    _controllerTag = 'scholarship_bank_${identityHashCode(this)}';
    final existing = maybeFindBankInfoController(tag: _controllerTag);
    _ownsController = existing == null;
    controller = existing ?? ensureBankInfoController(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
            maybeFindBankInfoController(tag: _controllerTag), controller)) {
      Get.delete<BankInfoController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _buildBody(context),
    );
  }
}
