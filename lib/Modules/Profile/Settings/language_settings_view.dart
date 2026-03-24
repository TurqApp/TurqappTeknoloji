import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Localization/app_language_service.dart';

part 'language_settings_view_option_part.dart';

class LanguageSettingsView extends StatelessWidget {
  const LanguageSettingsView({super.key});

  Widget _buildLanguageList(AppLanguageService languageService) {
    return Obx(
      () => ListView(
        children: [
          const SizedBox(height: 8),
          const _LanguageHeader(),
          const SizedBox(height: 24),
          ...AppLanguageService.options.map((option) {
            return _LanguageOptionTile(
              title: _localizedLanguageTitle(option.code, option.nativeLabel),
              subtitle: option.nativeLabel,
              isSelected: languageService.currentCode == option.code,
              onTap: () => languageService.changeLanguage(option.code),
            );
          }),
        ],
      ),
    );
  }

  String _localizedLanguageTitle(String code, String fallback) {
    return switch (code) {
      'tr_TR' => 'language.option.tr'.tr,
      'en_US' => 'language.option.en'.tr,
      'de_DE' => 'language.option.de'.tr,
      'fr_FR' => 'language.option.fr'.tr,
      'it_IT' => 'language.option.it'.tr,
      'ru_RU' => 'language.option.ru'.tr,
      _ => fallback,
    };
  }

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
                child: _buildLanguageList(languageService),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageHeader extends StatelessWidget {
  const _LanguageHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }
}
