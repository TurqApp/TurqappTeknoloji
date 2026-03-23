part of 'account_center_view.dart';

extension AccountCenterViewPersonalRowContentPart on _PersonalDetailRow {
  Widget _buildPersonalRowContent() {
    return _buildAccountCenterInfoContent(
      title: title,
      value: value,
    );
  }
}
