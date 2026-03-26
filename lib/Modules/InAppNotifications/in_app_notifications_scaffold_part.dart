part of 'in_app_notifications.dart';

Widget _buildInAppNotificationsPage(
  _InAppNotificationsState state,
  BuildContext context,
) {
  return Scaffold(
    key: const ValueKey(IntegrationTestKeys.screenNotifications),
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          state._buildHeader(context),
          state._buildTabs(),
          Expanded(child: state._buildContent()),
        ],
      ),
    ),
  );
}
