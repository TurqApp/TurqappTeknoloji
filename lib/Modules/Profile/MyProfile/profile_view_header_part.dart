part of 'profile_view.dart';

extension _ProfileViewHeaderPart on _ProfileViewState {
  Widget header() {
    return Obx(() {
      return Column(
        children: [
          _buildTopHeaderRow(),
          _buildImageAndButtonsRow(),
          12.ph,
          textInfoBody(),
          _buildLinksAndHighlightsRow(),
          Padding(padding: const EdgeInsets.only(top: 0), child: counters()),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: postButtons(context),
          ),
          Divider(
            height: 0,
            color: Colors.grey.withAlpha(50),
          ),
          4.ph,
        ],
      );
    });
  }
}
