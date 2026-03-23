part of 'profile_contact.dart';

extension ProfileContactShellPart on _ProfileContactState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'profile_contact.title'.tr),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      _buildCallVisibilityTile(),
                      const SizedBox(height: 12),
                      _buildEmailVisibilityTile(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
