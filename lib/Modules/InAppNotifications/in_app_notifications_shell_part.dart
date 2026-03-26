part of 'in_app_notifications.dart';

extension InAppNotificationsShellPart on _InAppNotificationsState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      key: const ValueKey(IntegrationTestKeys.screenNotifications),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabs(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }
}
