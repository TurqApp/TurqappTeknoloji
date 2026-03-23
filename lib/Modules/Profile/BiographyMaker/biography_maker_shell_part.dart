part of 'biography_maker.dart';

extension BiographyMakerShellPart on _BiographyMakerState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'biography.title'.tr),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: _buildContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
