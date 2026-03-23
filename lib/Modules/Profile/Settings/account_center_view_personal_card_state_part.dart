part of 'account_center_view.dart';

extension AccountCenterViewPersonalCardStatePart on _PersonalDetailsCard {
  Widget _buildPersonalCardState(List<Widget> rows) {
    if (rows.isEmpty) {
      return _buildPersonalEmptyState();
    }

    return _buildPersonalCardBody(rows);
  }
}
