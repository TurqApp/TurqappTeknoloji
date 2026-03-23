part of 'notification_settings_view.dart';

extension _NotificationSettingsViewMainPart on _NotificationSettingsViewState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'notifications.title'.tr),
            Expanded(
              child: _loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _deviceNoticeCard(),
                        const SizedBox(height: 18),
                        ..._buildInstantSection(),
                        const SizedBox(height: 14),
                        ..._buildCategorySection(context),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
