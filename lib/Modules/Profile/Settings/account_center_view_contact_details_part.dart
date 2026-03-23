part of 'account_center_view.dart';

class _ContactDetailsView extends StatelessWidget {
  const _ContactDetailsView();

  @override
  Widget build(BuildContext context) {
    final currentUserService = CurrentUserService.instance;
    return _buildContactDetailsShell(currentUserService);
  }
}
