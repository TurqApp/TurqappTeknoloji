part of 'deneme_sinavlari.dart';

extension DenemeSinavlariContentPart on DenemeSinavlari {
  Widget _buildSliderHeader() {
    return Column(
      children: [
        EducationSlider(
          sliderId: 'online_sinav',
          imageList: [
            AppAssets.practice1,
            AppAssets.practice2,
            AppAssets.practice3,
          ],
        ),
        20.ph,
      ],
    );
  }

  Widget _buildBodyContent(BuildContext context) {
    return Expanded(
      child: RefreshIndicator(
        color: Colors.white,
        backgroundColor: Colors.black,
        onRefresh: controller.getData,
        child: Obx(() {
          if (!controller.listingSelectionReady.value) {
            return ListView(
              controller: _scrollController,
              children: [
                _buildSliderHeader(),
                const AppStateView.loading(title: ''),
              ],
            );
          }
          final items = controller.hasActiveSearch
              ? controller.searchResults
              : controller.list;
          if (controller.isLoading.value) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildSliderHeader(),
                  const EducationGridSkeleton(itemCount: 4),
                ],
              ),
            );
          }
          if (controller.isSearchLoading.value) {
            return ListView(
              controller: _scrollController,
              children: [
                _buildSliderHeader(),
                const AppStateView.loading(title: ''),
              ],
            );
          }
          if (items.isEmpty) {
            return ListView(
              controller: _scrollController,
              children: [
                _buildSliderHeader(),
                _buildEmptyState(),
              ],
            );
          }
          return ListView(
            controller: _scrollController,
            children: [
              _buildSliderHeader(),
              _buildExamTypeStrip(),
              if (!embedded) _buildSearchEntry(),
              _buildListing(items),
              Obx(
                () => !controller.hasActiveSearch &&
                        controller.isLoadingMore.value
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CupertinoActivityIndicator()),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildListing(List<dynamic> items) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: controller.listingSelection.value == 0
            ? Column(
                children: PasajListingAdLayout.buildListChildren(
                  items: items,
                  itemBuilder: (item, index) => DenemeGrid(
                    model: item,
                    getData: controller.getData,
                    isListLayout: true,
                  ),
                  adBuilder: (slot) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: AdmobKare(
                      key: ValueKey('practice-exam-list-ad-$slot'),
                      suggestionPlacementId: 'practice_exam',
                    ),
                  ),
                ),
              )
            : Column(
                children: PasajListingAdLayout.buildTwoColumnGridChildren(
                  items: items,
                  horizontalSpacing: 4,
                  rowSpacing: 4,
                  itemBuilder: (item, index) => DenemeGrid(
                    model: item,
                    getData: controller.getData,
                  ),
                  adBuilder: (slot) => AdmobKare(
                    key: ValueKey('practice-exam-grid-ad-$slot'),
                    suggestionPlacementId: 'practice_exam',
                  ),
                ),
              ),
      ),
    );
  }
}
