part of 'account_center_view.dart';

extension AccountCenterViewShellPart on AccountCenterView {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>(IntegrationTestKeys.screenAccountCenter),
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'settings.account_center'.tr),
            Expanded(
              child: _buildBody(context),
            ),
          ],
        ),
      ),
    );
  }
}
