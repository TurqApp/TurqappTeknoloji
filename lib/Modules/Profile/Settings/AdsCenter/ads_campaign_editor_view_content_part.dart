part of 'ads_campaign_editor_view.dart';

extension _AdsCampaignEditorViewContentPart on _AdsCampaignEditorViewState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _buildCampaignSection(),
            _buildTargetingSection(),
            _buildCreativeSection(),
            _buildSubmitActions(),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
