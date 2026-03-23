part of 'account_center_view.dart';

extension AccountCenterViewContentPart on AccountCenterView {
  Widget _buildContent(
    BuildContext context,
    List<StoredAccount> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _buildContentSections(context, items),
    );
  }
}
