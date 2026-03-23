part of 'account_center_view.dart';

extension AccountCenterViewAccountDisplayNamePart on _AccountRow {
  List<Widget> _buildAccountDisplayName() {
    if (account.displayName.trim().isEmpty ||
        account.displayName.trim() == account.username.trim()) {
      return const <Widget>[];
    }

    return <Widget>[
      const SizedBox(height: 2),
      _buildAccountDisplayNameText(),
    ];
  }
}
