part of 'account_center_view.dart';

extension AccountCenterViewBodyContentPart on AccountCenterView {
  Widget _buildBodyContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final items = accountCenter.accounts.toList(growable: false);
        return _buildContent(context, items);
      }),
    );
  }
}
