part of 'account_center_view.dart';

extension AccountCenterViewPersonalRowValuePart on _PersonalDetailRow {
  Widget _buildPersonalRowValue() {
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
