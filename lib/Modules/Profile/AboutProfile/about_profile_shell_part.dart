part of 'about_profile.dart';

extension _AboutProfileShellPart on _AboutProfileState {
  Widget _buildAboutProfileShell(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() => _buildAboutProfileContent()),
      ),
    );
  }
}
