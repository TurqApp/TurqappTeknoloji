part of 'market_detail_view.dart';

extension MarketDetailViewShellPart on _MarketDetailViewState {
  Widget _buildMarketDetailScaffold(
    BuildContext context,
    List<String> galleryImages,
  ) {
    return Scaffold(
      key: const ValueKey(IntegrationTestKeys.screenMarketDetail),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 52,
        titleSpacing: 8,
        leading: const AppBackButton(),
        title: AppPageTitle('pasaj.market.detail_title'.tr),
        actions: [
          if (!_isOwner)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: EducationShareIconButton(
                onTap: () => const MarketShareService().shareItem(item),
                size: 36,
                iconSize: 20,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: EducationFeedShareIconButton(
              onTap: () => const MarketFeedPostShareService().shareItem(item),
              size: 36,
              iconSize: 20,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: PullDownButton(
              itemBuilder: (context) => [
                if (!_isOwner)
                  PullDownMenuItem(
                    onTap: _showReportSheet,
                    title: 'pasaj.market.report_listing'.tr,
                    icon: CupertinoIcons.exclamationmark_circle,
                  ),
              ],
              buttonBuilder: (context, showMenu) => AppHeaderActionButton(
                onTap: showMenu,
                child: const Icon(
                  AppIcons.ellipsisVertical,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshItem,
        child: _buildMarketDetailContent(context, galleryImages),
      ),
    );
  }
}
