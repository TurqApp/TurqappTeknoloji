part of 'language_settings_view.dart';

extension LanguageSettingsViewListPart on LanguageSettingsView {
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
}
