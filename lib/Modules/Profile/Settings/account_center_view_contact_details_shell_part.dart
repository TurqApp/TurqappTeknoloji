part of 'account_center_view.dart';

extension AccountCenterViewContactDetailsShellPart on _ContactDetailsView {
  Widget _buildContactDetailsShell(CurrentUserService currentUserService) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildContactDetailsHeader(),
            _buildContactDetailsBody(currentUserService),
          ],
        ),
      ),
    );
  }
}
