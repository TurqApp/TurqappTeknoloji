part of 'account_center_view.dart';

extension AccountCenterViewPersonalCardBodyPart on _PersonalDetailsCard {
  Widget _buildPersonalCardBody(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: _buildPersonalRowsList(rows),
    );
  }
}
