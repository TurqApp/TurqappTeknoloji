part of 'blocked_users.dart';

extension _BlockedUsersShellPart on _BlockedUsersState {
  Widget _buildBlockedUsersShell(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "settings.blocked_users".tr),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: _buildBlockedUsersContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
