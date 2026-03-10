import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:svg_flutter/svg_flutter.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Profile/Settings/settings_controller.dart';

class PasajSettingsView extends StatelessWidget {
  PasajSettingsView({super.key});

  final SettingsController controller = Get.isRegistered<SettingsController>()
      ? Get.find<SettingsController>()
      : Get.put(SettingsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Pasaj"),
            const Padding(
              padding: EdgeInsets.fromLTRB(15, 8, 15, 12),
              child: Text(
                "Sekmeleri açıp kapatabilir, sıralamayı sürükleyerek değiştirebilirsin.",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final tabs = controller.pasajOrder.toList(growable: false);
                return ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
                  itemCount: tabs.length,
                  onReorder: controller.reorderPasajTabs,
                  buildDefaultDragHandles: false,
                  itemBuilder: (context, index) {
                    final title = tabs[index];
                    final isOn = controller.pasajVisibility[title] ?? true;
                    return Container(
                      key: ValueKey(title),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                      ),
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
                              title,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                          CupertinoSwitch(
                            value: isOn,
                            onChanged: (value) =>
                                controller.setPasajTabVisibility(title, value),
                          ),
                          const SizedBox(width: 6),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Icon(
                              CupertinoIcons.line_horizontal_3,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
