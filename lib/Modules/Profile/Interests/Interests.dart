import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Core/interests_list.dart';
import 'package:turqappv2/Modules/Profile/Interests/interest_controller.dart';

class Interests extends StatelessWidget {
  Interests({super.key});
  final controller = Get.put(InterestsController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "settings.interests".tr),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Obx(
                          () => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "interests.personalize_feed".tr,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF111827),
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "interests.selection_range".trParams(
                                  <String, String>{
                                    'min':
                                        '${InterestsController.minSelection}',
                                    'max':
                                        '${InterestsController.maxSelection}',
                                  },
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  fontFamily: "Montserrat",
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text(
                                    "interests.selected_count".trParams(
                                      <String, String>{
                                        'selected':
                                            '${controller.selecteds.length}',
                                        'max':
                                            '${InterestsController.maxSelection}',
                                      },
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF111827),
                                      fontFamily: "MontserratMedium",
                                    ),
                                  ),
                                  const Spacer(),
                                  if (controller.selecteds.length >=
                                      InterestsController.minSelection)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        "interests.ready".tr,
                                        style: TextStyle(
                                          color: Color(0xFF166534),
                                          fontSize: 11,
                                          fontFamily: "MontserratBold",
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.20),
                          ),
                        ),
                        child: TextField(
                          onChanged: (value) =>
                              controller.searchText.value = value,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(40),
                          ],
                          style: const TextStyle(
                            fontFamily: "Montserrat",
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: "interests.search_hint".tr,
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontFamily: "Montserrat",
                            ),
                            prefixIcon: const Icon(Icons.search_rounded),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Obx(
                        () {
                          if (controller.selecteds.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: controller.selecteds
                                  .map(
                                    (item) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Text(
                                        item,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontFamily: "MontserratMedium",
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          );
                        },
                      ),
                      Obx(
                        () {
                          if (!controller.isReady.value) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final filtered = controller.filterItems(interestList);
                          final selectedCanonicalSet = controller.selecteds
                              .map(controller.canonicalize)
                              .toSet();
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              final isSelected = selectedCanonicalSet
                                  .contains(controller.canonicalize(item));
                              return GestureDetector(
                                onTap: () => controller.select(item),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOut,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.10)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.grey.withValues(alpha: 0.20),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontFamily: isSelected
                                                ? "MontserratBold"
                                                : "Montserrat",
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 20,
                                        height: 20,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.black
                                              : Colors.white,
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(15)),
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.black
                                                : Colors.grey,
                                          ),
                                        ),
                                        child: isSelected
                                            ? const Icon(
                                                CupertinoIcons.checkmark,
                                                color: Colors.white,
                                                size: 12,
                                              )
                                            : const SizedBox(),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      TurqAppButton(onTap: () {
                        controller.setData();
                      }),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
