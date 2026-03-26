part of 'market_view.dart';

extension MarketViewShellPart on MarketView {
  Widget _buildView(BuildContext context) {
    if (!MarketView._bannerWarmupTriggered) {
      MarketView._bannerWarmupTriggered = true;
      unawaited(
        ensureAdmobBannerWarmupService().warmForPasajEntry(
          surfaceKey: 'market',
        ),
      );
    }

    final content = Column(
      children: [
        const Divider(height: 1, color: Color(0xFFE0E0E0)),
        Expanded(child: _buildBody(context)),
      ],
    );

    if (embedded) {
      return content;
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                const AppBackButton(),
                const SizedBox(width: 8),
                Text(
                  'pasaj.market.title'.tr,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontFamily: 'MontserratBold',
                  ),
                ),
              ],
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Obx(() {
      if (!controller.listingSelectionReady.value) {
        return const Center(child: CupertinoActivityIndicator());
      }
      return RefreshIndicator(
        onRefresh: controller.refreshHome,
        child: CustomScrollView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMarketSlider(),
                  _buildCategoryStrip(),
                  const SizedBox(height: 8),
                  if (controller.hasAdvancedFilters)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (controller.selectedCityFilter.value.isNotEmpty)
                              _buildFilterPill(
                                controller.selectedCityFilter.value,
                              ),
                            if (controller
                                .selectedContactFilter.value.isNotEmpty)
                              _buildFilterPill(
                                controller.selectedContactFilter.value ==
                                        'phone'
                                    ? 'pasaj.market.contact_phone'.tr
                                    : 'pasaj.market.contact_message'.tr,
                              ),
                            if (controller.minPriceFilter.value.isNotEmpty)
                              _buildFilterPill(
                                'pasaj.market.min_price'
                                    .trParams(<String, String>{
                                  'value': controller.minPriceFilter.value,
                                }),
                              ),
                            if (controller.maxPriceFilter.value.isNotEmpty)
                              _buildFilterPill(
                                'pasaj.market.max_price'
                                    .trParams(<String, String>{
                                  'value': controller.maxPriceFilter.value,
                                }),
                              ),
                            if (controller.sortSelection.value != 'newest')
                              _buildFilterPill(
                                controller.sortSelection.value == 'price_asc'
                                    ? 'pasaj.market.sort_price_asc'.tr
                                    : 'pasaj.market.sort_price_desc'.tr,
                              ),
                            GestureDetector(
                              onTap: controller.clearAdvancedFilters,
                              child: Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Text(
                                  'common.clear'.tr,
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                    fontFamily: 'MontserratBold',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if ((controller.isLoading.value ||
                    controller.isSearchLoading.value) &&
                controller.visibleItems.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.visibleItems.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else if (controller.listingSelection.value == 0)
              SliverToBoxAdapter(
                key: const ValueKey<String>('market-listing-list'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    children: PasajListingAdLayout.buildListChildren(
                      items: controller.visibleItems,
                      itemBuilder: (item, index) => _buildListingCard(item),
                      adBuilder: (slot) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: AdmobKare(
                          key: ValueKey('market-list-ad-$slot'),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                key: const ValueKey<String>('market-listing-grid'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 0, 15, 16),
                  child: Column(
                    children: PasajListingAdLayout.buildTwoColumnGridChildren(
                      items: controller.visibleItems,
                      horizontalSpacing: 4,
                      rowSpacing: 4,
                      itemBuilder: (item, index) => _buildGridCard(item),
                      adBuilder: (slot) => AdmobKare(
                        key: ValueKey('market-grid-ad-$slot'),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
