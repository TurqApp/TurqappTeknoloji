part of 'account_center_view.dart';

extension AccountCenterViewContactStatusContentPart on _ContactStatusRow {
  Widget _buildContactStatusContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContactStatusTitle(),
        const SizedBox(height: 3),
        _buildContactStatusValue(),
      ],
    );
  }
}
