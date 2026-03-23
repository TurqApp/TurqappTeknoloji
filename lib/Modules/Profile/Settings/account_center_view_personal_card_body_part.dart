part of 'account_center_view.dart';

extension AccountCenterViewPersonalCardBodyPart on _PersonalDetailsCard {
  Widget _buildPersonalCardBody(List<Widget> rows) {
    return _buildAccountCenterCard(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              const Divider(height: 1, indent: 18, endIndent: 18),
          ],
        ],
      ),
    );
  }
}
