part of 'account_center_view.dart';

extension AccountCenterViewPersonalRowTitlePart on _PersonalDetailRow {
  Widget _buildPersonalRowTitle() {
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
