part of 'pasaj_settings_view.dart';

extension PasajSettingsViewShellPart on _PasajSettingsViewState {
  Widget _buildPage(BuildContext context) {
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
}
