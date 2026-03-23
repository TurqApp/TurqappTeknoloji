part of 'support_contact_view.dart';

extension SupportContactViewShellPart on _SupportContactViewState {
  Widget _buildContent(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'support.title'.tr),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _buildSupportCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
