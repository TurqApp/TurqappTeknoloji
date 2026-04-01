part of 'market_detail_view.dart';

extension MarketDetailViewShellContentPart on _MarketDetailViewState {
  Widget _buildMarketDetailScaffoldContent(
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
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isOwner) ...[
                  EducationShareIconButton(
                    onTap: () => const MarketShareService().shareItem(item),
                    size: 36,
                    iconSize: 18,
                  ),
                  const SizedBox(width: 6),
                  AppHeaderActionButton(
                    onTap: _isTogglingSaved ? null : _performToggleSaved,
                    size: 36,
                    opacity: _isTogglingSaved ? 0.6 : 1,
                    child: Icon(
                      _isSaved ? AppIcons.saved : AppIcons.save,
                      color: _isSaved ? Colors.orange : Colors.black54,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                EducationFeedShareIconButton(
                  onTap: () => const MarketFeedPostShareService().shareItem(item),
                  size: 36,
                  iconSize: 18,
                ),
                const SizedBox(width: 6),
                PullDownButton(
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
                    size: 36,
                    child: const Icon(
                      AppIcons.ellipsisVertical,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                ),
              ],
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
