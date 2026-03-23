part of 'account_center_view.dart';

extension AccountCenterViewAccountDisplayNamePart on _AccountRow {
  List<Widget> _buildAccountDisplayName() {
    if (!account.hasDistinctAccountCenterDisplayName) {
      return const <Widget>[];
    }

    return <Widget>[
      const SizedBox(height: 2),
      _buildAccountDisplayNameText(),
    ];
  }
}
