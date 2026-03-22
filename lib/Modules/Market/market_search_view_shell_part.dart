part of 'market_search_view.dart';

extension _MarketSearchViewShellPart on _MarketSearchViewState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(context),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                final query = controller.searchQuery.value.trim();
                final showRecentSearches = query.length < 2;
                final items = controller.visibleItems;

                if (!showRecentSearches &&
                    controller.isSearchLoading.value &&
                    items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (showRecentSearches) {
                  return _buildRecentSearches();
                }

                if (items.isEmpty) {
                  return _buildInfoState(
                    icon: CupertinoIcons.cube_box,
                    title: 'common.no_results'.tr,
                    subtitle: 'pasaj.market.search.no_results_body'.tr,
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                      child: Row(
                        children: [
                          Text(
                            'pasaj.market.search.result_count'
                                .trParams({'count': '${items.length}'}),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontFamily: 'MontserratBold',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: ListView.builder(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: items.length,
                          itemBuilder: (context, index) =>
                              _buildListCard(items[index]),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 15, 0),
      child: Row(
        children: [
          const AppBackButton(),
          const SizedBox(width: 8),
          Expanded(
            child: TurqSearchBar(
              controller: controller.search,
              focusNode: _focusNode,
              hintText: 'pasaj.market.search_hint'.tr,
              onChanged: controller.setSearchQuery,
              onClear: () => controller.setSearchQuery(''),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(30, 30),
              fixedSize: const Size(30, 30),
            ),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              builder: (_) => MarketFilterSheet(controller: controller),
            ),
            child: Icon(
              Icons.filter_alt_outlined,
              color: controller.hasAdvancedFilters ? Colors.pink : Colors.black,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
