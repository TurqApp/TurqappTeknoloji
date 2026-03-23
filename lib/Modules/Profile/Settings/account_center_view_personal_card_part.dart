part of 'account_center_view.dart';

class _PersonalDetailsCard extends StatelessWidget {
  const _PersonalDetailsCard({
    required this.contactDetails,
    required this.onContactTap,
  });

  final String? contactDetails;
  final VoidCallback onContactTap;

  @override
  Widget build(BuildContext context) {
    final rows = _buildPersonalRows();

    if (rows.isEmpty) {
      return _buildPersonalEmptyState();
    }

    return _buildPersonalCardBody(rows);
  }
}
