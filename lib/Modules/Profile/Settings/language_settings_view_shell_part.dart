part of 'language_settings_view.dart';

extension LanguageSettingsViewShellPart on LanguageSettingsView {
  Widget _buildPage(BuildContext context) {
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
