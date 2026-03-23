part of 'account_center_view.dart';

extension AccountCenterViewShellBodyPart on AccountCenterView {
  Widget _buildPageShellBody(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          BackButtons(text: 'settings.account_center'.tr),
          Expanded(
            child: _buildBody(context),
          ),
        ],
      ),
    );
  }
}
