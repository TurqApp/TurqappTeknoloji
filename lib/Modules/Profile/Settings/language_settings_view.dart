import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Localization/app_language_service.dart';

class LanguageSettingsView extends StatelessWidget {
  const LanguageSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = AppLanguageService.ensure();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BackButtons(text: 'language.title'.tr),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Obx(
                  () => ListView(
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'language.subtitle'.tr,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'language.note'.tr,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                      const SizedBox(height: 24),
                      ...AppLanguageService.options.map((option) {
                        final title = switch (option.code) {
                          'tr_TR' => 'language.option.tr'.tr,
                          'en_US' => 'language.option.en'.tr,
                          'de_DE' => 'language.option.de'.tr,
                          'fr_FR' => 'language.option.fr'.tr,
                          'it_IT' => 'language.option.it'.tr,
                          'ru_RU' => 'language.option.ru'.tr,
                          _ => option.nativeLabel,
                        };
                        return _LanguageOptionTile(
                          title: title,
                          subtitle: option.nativeLabel,
                          isSelected:
                              languageService.currentCode == option.code,
                          onTap: () =>
                              languageService.changeLanguage(option.code),
                        );
                      }),
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

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.black12,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? CupertinoIcons.check_mark_circled_solid
                      : CupertinoIcons.circle,
                  color: Colors.black,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
