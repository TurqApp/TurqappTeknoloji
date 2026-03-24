import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:svg_flutter/svg_flutter.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';
import 'package:turqappv2/Modules/Profile/Settings/settings_controller.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'settings.pasaj'.tr),
            Expanded(
              child: _buildPasajList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasajList() {
    return Obx(() {
      final tabs = _resolvedPasajTabs();
      return ListView(
        padding: const EdgeInsets.fromLTRB(15, 6, 15, 20),
        children: tabs
            .map(
              (title) => _PasajToggleTile(
                key: ValueKey('pasaj-tile-$title'),
                controller: controller,
                title: title,
              ),
            )
            .toList(growable: false),
      );
    });
  }

  List<String> _resolvedPasajTabs() {
    final tabs = controller.pasajOrder.toList(growable: true);
    if (!tabs.contains(PasajTabIds.practiceExams)) {
      final onlineIndex = tabs.indexOf(PasajTabIds.onlineExam);
      if (onlineIndex >= 0) {
        tabs.insert(onlineIndex, PasajTabIds.practiceExams);
      } else {
        tabs.add(PasajTabIds.practiceExams);
      }
    }
    return tabs;
  }
}
