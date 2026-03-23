import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:svg_flutter/svg_flutter.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';
import 'package:turqappv2/Modules/Profile/Settings/settings_controller.dart';

part 'pasaj_settings_view_shell_part.dart';
part 'pasaj_settings_view_content_part.dart';
part 'pasaj_settings_view_data_part.dart';
part 'pasaj_settings_view_labels_part.dart';
part 'pasaj_settings_view_tile_part.dart';

class PasajSettingsView extends StatefulWidget {
  const PasajSettingsView({super.key});

  @override
  State<PasajSettingsView> createState() => _PasajSettingsViewState();
}

class _PasajSettingsViewState extends State<PasajSettingsView> {
  late final SettingsController controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    final existingController = SettingsController.maybeFind();
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = SettingsController.ensure();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(SettingsController.maybeFind(), controller)) {
      Get.delete<SettingsController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
