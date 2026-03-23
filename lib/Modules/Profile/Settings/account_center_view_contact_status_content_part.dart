part of 'account_center_view.dart';

extension AccountCenterViewContactStatusContentPart on _ContactStatusRow {
  Widget _buildContactStatusContent() {
    return _buildAccountCenterInfoContent(
      title: title,
      value: value,
    );
  }
}
