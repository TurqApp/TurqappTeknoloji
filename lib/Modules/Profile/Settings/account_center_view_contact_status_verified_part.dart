part of 'account_center_view.dart';

extension AccountCenterViewContactStatusVerifiedPart on _ContactStatusRow {
  Widget _buildVerifiedStatusBadge({
    required Color statusColor,
    required String statusText,
  }) {
    return Row(
      children: [
        const Icon(
          CupertinoIcons.checkmark_seal_fill,
          color: Colors.green,
          size: 18,
        ),
        const SizedBox(width: 6),
        _buildVerifiedStatusText(
          statusColor: statusColor,
          statusText: statusText,
        ),
      ],
    );
  }
}
