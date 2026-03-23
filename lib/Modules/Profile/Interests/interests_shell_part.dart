part of 'interests.dart';

extension _InterestsShellPart on _InterestsState {
  Widget _buildInterestsShell(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "settings.interests".tr),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: _buildInterestsContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
