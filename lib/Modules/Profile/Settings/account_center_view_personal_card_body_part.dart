part of 'account_center_view.dart';

extension AccountCenterViewPersonalCardBodyPart on _PersonalDetailsCard {
  Widget _buildPersonalCardBody(List<Widget> rows) {
    return _buildAccountCenterCard(
      child: _buildPersonalRowsList(rows),
    );
  }
}
