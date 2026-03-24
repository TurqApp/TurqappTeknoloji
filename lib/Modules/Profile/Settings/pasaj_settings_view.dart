import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:svg_flutter/svg_flutter.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';
import 'package:turqappv2/Modules/Profile/Settings/settings_controller.dart';

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

class _PasajToggleTile extends StatelessWidget {
  const _PasajToggleTile({
    super.key,
    required this.controller,
    required this.title,
  });

  final SettingsController controller;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isOn = controller.pasajVisibility[title] ?? true;
      return GestureDetector(
        key: ValueKey('pasaj-row-$title-$isOn'),
        behavior: HitTestBehavior.opaque,
        onTap: () => controller.setPasajTabVisibility(title, !isOn),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8E8E8)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    SvgPicture.asset(
                      "assets/icons/sinav.svg",
                      height: 22,
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _pasajDisplayTitle(title),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                key: ValueKey('pasaj-switch-$title-$isOn'),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 54,
                height: 32,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isOn ? Colors.black : const Color(0xFFEDEDED),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  alignment:
                      isOn ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  String _pasajDisplayTitle(String title) {
    final translationKey = pasajTitleTranslationKey(title);
    if (translationKey.isNotEmpty) return translationKey.tr;
    return title;
  }
}
