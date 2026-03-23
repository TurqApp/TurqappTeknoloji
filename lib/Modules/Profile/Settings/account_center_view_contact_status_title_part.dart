part of 'account_center_view.dart';

extension AccountCenterViewContactStatusTitlePart on _ContactStatusRow {
  Widget _buildContactStatusTitle() {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontFamily: 'MontserratBold',
      ),
    );
  }
}
