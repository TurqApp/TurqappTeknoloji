part of 'tutoring_view.dart';

extension TutoringViewContentPart on TutoringView {
  Widget _buildBodyContent(BuildContext context) {
    return Expanded(
      child: RefreshIndicator(
        color: Colors.white,
        backgroundColor: Colors.black,
        onRefresh: () async {
          await tutoringController.listenToTutoringData(forceRefresh: true);
          applyFilterTrigger.value = false;
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Obx(() {
            if (!viewModeController.isReady.value) {
              return const SizedBox(
                height: 280,
                child: AppStateView.loading(title: ''),
              );
            }

            final filteredList = _buildFilteredList();

            return Column(
              children: [
                EducationSlider(
                  sliderId: 'ozel_ders',
                  imageList: [
                    AppAssets.tutoring1,
                    AppAssets.tutoring2,
                    AppAssets.tutoring3,
                  ],
                ),
                if (!embedded) ...[
                  16.ph,
                  _buildSearchAndFilterRow(context),
                ],
                16.ph,
                TutoringCategoryWidget(categories: kategoriler),
                16.ph,
                _buildListingContent(filteredList),
                Obx(() {
                  if (tutoringController.isLoadingMore.value) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CupertinoActivityIndicator()),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            );
          }),
        ),
      ),
    );
  }

  List<TutoringModel> _buildFilteredList() {
    var filteredList = (tutoringController.hasActiveSearch
            ? tutoringController.searchResults
            : tutoringController.tutoringList)
        .toList();

    if (!applyFilterTrigger.value) {
      return filteredList;
    }

    if (filterController.selectedBranch.value != null &&
        filterController.selectedBranch.value!.isNotEmpty) {
      filteredList = filteredList
          .where(
            (tutoring) =>
                tutoring.brans == filterController.selectedBranch.value,
          )
          .toList();
    }
    if (filterController.selectedGender.value != null &&
        filterController.selectedGender.value!.isNotEmpty) {
      filteredList = filteredList
          .where(
            (tutoring) =>
                tutoring.cinsiyet == filterController.selectedGender.value,
          )
          .toList();
    }
    if (filterController.selectedLessonPlace.value != null &&
        filterController.selectedLessonPlace.value!.isNotEmpty) {
      filteredList = filteredList
          .where(
            (tutoring) => filterController.selectedLessonPlace.value!.any(
              (place) => tutoring.dersYeri.contains(place),
            ),
          )
          .toList();
    }
    if (filterController.maxPrice.value != null) {
      filteredList = filteredList
          .where(
            (tutoring) => tutoring.fiyat <= filterController.maxPrice.value!,
          )
          .toList();
    }
    if (filterController.minPrice.value != null) {
      filteredList = filteredList
          .where(
            (tutoring) => tutoring.fiyat >= filterController.minPrice.value!,
          )
          .toList();
    }
    if (filterController.selectedCity.value != null &&
        filterController.selectedCity.value!.isNotEmpty) {
      filteredList = filteredList
          .where(
            (tutoring) => tutoring.sehir == filterController.selectedCity.value,
          )
          .toList();
    }
    if (filterController.selectedDistrict.value != null &&
        filterController.selectedDistrict.value!.isNotEmpty) {
      filteredList = filteredList
          .where(
            (tutoring) =>
                tutoring.ilce == filterController.selectedDistrict.value,
          )
          .toList();
    }

    if (filterController.selectedSort.value == 'En Yeni') {
      filteredList.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    } else if (filterController.selectedSort.value == 'En Çok Görüntülenen') {
      filteredList.sort(
        (a, b) => (b.viewCount ?? 0).compareTo(a.viewCount ?? 0),
      );
    } else if (filterController.selectedSort.value == 'Bana En Yakın') {
      final userCity =
          (CurrentUserService.instance.currentUser?.city ?? '').trim();
      filteredList.sort((a, b) {
        final aScore = a.sehir == userCity ? 1 : 0;
        final bScore = b.sehir == userCity ? 1 : 0;
        if (aScore != bScore) return bScore.compareTo(aScore);
        return b.timeStamp.compareTo(a.timeStamp);
      });
    }

    return filteredList;
  }

  Widget _buildSearchAndFilterRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Expanded(
            child: TurqSearchBar(
              controller: tutoringController.searchPreviewController,
              hintText: 'tutoring.search_hint'.tr,
              onTap: () =>
                  const EducationDetailNavigationService().openTutoringSearch(),
            ),
          ),
          8.pw,
          Obx(
            () => AppHeaderActionButton(
              onTap: viewModeController.toggleView,
              child: Icon(
                viewModeController.isGridView.value
                    ? AppIcons.squareGrid2
                    : AppIcons.list,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
          8.pw,
          Obx(
            () => AppHeaderActionButton(
              onTap: () => _openFilterSheet(context),
              child: const Icon(
                CupertinoIcons.arrow_up_arrow_down,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
          8.pw,
          Obx(
            () => AppHeaderActionButton(
              onTap: () => _openFilterSheet(context),
              child: const Icon(
                Icons.filter_alt_outlined,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    closeKeyboard(context);
    await Get.bottomSheet(
      TutoringFilterBottomSheet(controller: tutoringController),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
    );
    applyFilterTrigger.value = true;
  }

  Widget _buildListingContent(List<TutoringModel> filteredList) {
    return Obx(() {
      if (tutoringController.isLoading.value ||
          tutoringController.isSearchLoading.value) {
        return const AppStateView.loading(title: '');
      }

      final content = TutoringWidgetBuilder(
        tutoringList: filteredList,
        isGridView: viewModeController.isGridView.value,
      );
      if (viewModeController.isGridView.value) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: content,
        );
      }
      return content;
    });
  }
}
