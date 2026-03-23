part of 'account_center_view.dart';

extension AccountCenterViewContactStatusRowBodyPart on _ContactStatusRow {
  Widget _buildContactStatusRowBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          _buildContactStatusIcon(),
          const SizedBox(width: 12),
          Expanded(child: _buildContactStatusContent()),
          _buildStatusBadge(),
        ],
      ),
    );
  }
}
