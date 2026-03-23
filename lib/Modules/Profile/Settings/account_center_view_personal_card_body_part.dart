part of 'account_center_view.dart';

extension AccountCenterViewPersonalCardBodyPart on _PersonalDetailsCard {
  Widget _buildPersonalCardBody(List<Widget> rows) {
    return Container(
      decoration: _buildAccountCenterCardDecoration(),
      child: _buildPersonalRowsList(rows),
    );
  }
}
