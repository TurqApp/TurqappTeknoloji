part of 'account_center_view.dart';

extension AccountCenterViewContactStatusValuePart on _ContactStatusRow {
  Widget _buildContactStatusValue() {
    return Text(
      value,
      style: const TextStyle(
        color: Colors.black54,
        fontSize: 13,
        fontFamily: 'MontserratMedium',
      ),
    );
  }
}
