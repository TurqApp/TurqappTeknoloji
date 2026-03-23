part of 'account_center_view.dart';

extension AccountCenterViewPersonalRowContentPart on _PersonalDetailRow {
  Widget _buildPersonalRowContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'MontserratBold',
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 13,
            fontFamily: 'MontserratMedium',
          ),
        ),
      ],
    );
  }
}
