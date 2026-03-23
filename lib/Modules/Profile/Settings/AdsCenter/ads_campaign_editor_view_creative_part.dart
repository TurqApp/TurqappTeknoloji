part of 'ads_campaign_editor_view.dart';

extension _AdsCampaignEditorViewCreativePart on _AdsCampaignEditorViewState {
  Future<void> _attachCreativeIfFilled(String campaignId) async {
    final headline = _creativeHeadline.text.trim();
    final mediaUrl = _creativeMediaUrl.text.trim();
    final destination = _destinationUrl.text.trim();

    if (headline.isEmpty && mediaUrl.isEmpty && destination.isEmpty) {
      return;
    }

    final creative = AdCreative.empty().copyWith(
      campaignId: campaignId,
      type: _creativeType,
      storagePath: _creativeStoragePath.text.trim(),
      mediaURL: mediaUrl,
      hlsMasterURL: _creativeHlsUrl.text.trim(),
      thumbnailURL: _creativeThumbUrl.text.trim(),
      durationSec: int.tryParse(_creativeDuration.text.trim()) ?? 0,
      headline: headline,
      bodyText: _creativeBody.text.trim(),
      ctaText: _ctaText.text.trim(),
      destinationURL: destination,
      moderationStatus: AdModerationStatus.pending,
      updatedAt: DateTime.now(),
    );

    final creativeId = await _controller.saveCreative(creative);

    final currentCampaign = widget.initialCampaign;
    final existing = currentCampaign?.creativeIds ?? const <String>[];
    final merged = <String>{...existing, creativeId}.toList(growable: false);

    if (currentCampaign != null) {
      await _controller.saveCampaign(
        currentCampaign.copyWith(
          creativeIds: merged,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      final saved =
          _controller.campaigns.firstWhereOrNull((c) => c.id == campaignId);
      if (saved != null) {
        await _controller.saveCampaign(
          saved.copyWith(
            creativeIds: merged,
            updatedAt: DateTime.now(),
          ),
        );
      }
    }
  }
}
