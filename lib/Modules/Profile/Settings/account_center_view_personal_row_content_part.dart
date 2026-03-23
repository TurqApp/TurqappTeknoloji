part of 'account_center_view.dart';

extension AccountCenterViewPersonalRowContentPart on _PersonalDetailRow {
  Widget _buildPersonalRowContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPersonalRowTitle(),
        const SizedBox(height: 3),
        _buildPersonalRowValue(),
      ],
    );
  }
}
