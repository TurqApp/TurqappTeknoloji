part of 'antreman_view.dart';

extension _AntremanViewContentPart on AntremanView2 {
  void _dismissSharedEducationSearchFocus() {
    final educationController = EducationController.maybeFind();
    if (educationController == null) return;
    if (educationController.searchFocus.hasFocus) {
      educationController.searchFocus.unfocus();
    }
    educationController.isKeyboardOpen.value = false;
    educationController.isSearchMode.value = false;
  }

  BoxDecoration _sectionCardDecoration({
    required Color color,
    bool elevated = false,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          color.withValues(alpha: 0.98),
          Color.lerp(color, Colors.black, 0.16) ?? color,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.18),
      ),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: color.withValues(alpha: 0.20),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ]
          : [],
    );
  }

  BoxDecoration _surfaceDecoration() {
    return BoxDecoration(
      color: const Color(0xFFF6F7FB),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: const Color(0xFFE5E8F0),
      ),
    );
  }

  Widget _buildSubjectTile(
    BuildContext context, {
    required String ders,
    required VoidCallback onTap,
    bool showDivider = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE8EBF3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ders,
                      style: TextStyles.textFieldTitle.copyWith(
                        fontSize: 15,
                        color: const Color(0xFF151821),
                      ),
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F4FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.chevron_right,
                      color: Color(0xFF151821),
                      size: 18,
                    ),
                  ),
                ],
              ),
              if (showDivider) ...[
                const SizedBox(height: 8),
                appDivider(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Expanded(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Obx(() {
              if (controller.hasActiveSearch) {
                return _buildSearchResults(context);
              }

              if (!controller.mainCategoryLoaded.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.mainCategory.value.isEmpty) {
                return _buildMainCategoryList();
              }

              return _buildExpandedCategoryList(context);
            }),
          ),
          Obx(
            () => controller.isSubjectSelecting.value
                ? Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.16),
                        alignment: Alignment.center,
                        child: Container(
                          width: (MediaQuery.of(context).size.width * 0.5)
                              .clamp(150.0, 180.0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CupertinoActivityIndicator(radius: 14),
                              const SizedBox(height: 12),
                              Text(
                                'training.questions_loading'.tr,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF151821),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    if (controller.isSearchLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.searchResults.isEmpty) {
      return Center(
        child: Text(
          'training.search_no_match'.tr,
          style: const TextStyle(
            color: Colors.black54,
            fontFamily: 'MontserratMedium',
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: controller.searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = controller.searchResults[index];
        return ListTile(
          onTap: () {
            _dismissSharedEducationSearchFocus();
            controller.openSearchResult(item);
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          tileColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          title: Text(
            '${item.sinavTuru} • ${item.ders}',
            style: TextStyles.textFieldTitle.copyWith(
              fontSize: 15,
              color: const Color(0xFF151821),
            ),
          ),
          subtitle: Text(
            'training.question_meta'.trParams({
              'number': item.soruNo,
              'year': item.yil,
            }),
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: const Icon(
            CupertinoIcons.chevron_right,
            size: 18,
            color: Color(0xFF151821),
          ),
        );
      },
    );
  }

  Widget _buildMainCategoryList() {
    return ListView.builder(
      itemCount: controller.mainCategories.length,
      itemBuilder: (context, index) {
        final category = controller.mainCategories[index];
        return Semantics(
          label: IntegrationTestKeys.questionBankCategory(category),
          button: true,
          child: GestureDetector(
            onTap: () async {
              _dismissSharedEducationSearchFocus();
              await controller.setMainCategory(category);
            },
            child: Container(
              key: ValueKey(IntegrationTestKeys.questionBankCategory(category)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              margin: const EdgeInsets.symmetric(vertical: 7),
              decoration: _sectionCardDecoration(
                color: controller.getRandomColor(index),
                elevated: true,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: TextStyles.antremanTitle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Premium soru akışını bu kategoriden aç.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      CupertinoIcons.chevron_right,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandedCategoryList(BuildContext context) {
    final categories = controller.visibleMainCategories;
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final anaBaslik = categories[index];
        return Obx(
          () => Column(
            key: Key(anaBaslik),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  if (controller.expandedIndex.value == index) {
                    controller.expandedIndex.value = -1;
                  } else {
                    controller.expandedIndex.value = index;
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  margin: const EdgeInsets.symmetric(vertical: 7),
                  decoration: _sectionCardDecoration(
                    color: controller.getRandomColor(index),
                    elevated: controller.expandedIndex.value == index,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              anaBaslik,
                              style: TextStyles.antremanTitle,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ders ve sinav turunu secerek devam et.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          controller.expandedIndex.value == index
                              ? AppIcons.up
                              : AppIcons.down,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: controller.expandedIndex.value == index ? null : 0,
                child: controller.expandedIndex.value == index
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(6, 6, 6, 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: _surfaceDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(
                              controller.subjects[anaBaslik]!.keys.length,
                              (sinavIndex) => _buildExamTypeSection(
                                context,
                                anaBaslik: anaBaslik,
                                sinavIndex: sinavIndex,
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExamTypeSection(
    BuildContext context, {
    required String anaBaslik,
    required int sinavIndex,
  }) {
    final sinavTuru =
        controller.subjects[anaBaslik]!.keys.elementAt(sinavIndex);
    final dersler = controller.subjects[anaBaslik]![sinavTuru]!;

    if (anaBaslik == sinavTuru) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          dersler.length,
          (dersIndex) {
            final ders = dersler[dersIndex];
            return Padding(
              padding: EdgeInsets.only(
                bottom: dersIndex < dersler.length - 1 ? 8 : 0,
              ),
              child: _buildSubjectTile(
                context,
                ders: ders,
                onTap: () {
                  controller.selectSubject(
                    ders,
                    anaBaslik,
                    sinavTuru,
                  );
                },
              ),
            );
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            if (controller.expandedSubIndex.value == sinavIndex) {
              controller.expandedSubIndex.value = -1;
            } else {
              controller.expandedSubIndex.value = sinavIndex;
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            margin: const EdgeInsets.only(top: 4, bottom: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE3E7F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    sinavTuru,
                    style: TextStyles.bold18Black.copyWith(fontSize: 16),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F5FA),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    controller.expandedSubIndex.value == sinavIndex
                        ? AppIcons.up
                        : AppIcons.down,
                    color: Colors.black87,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: controller.expandedSubIndex.value == sinavIndex ? null : 0,
          child: controller.expandedSubIndex.value == sinavIndex
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
                  child: Column(
                    children: List.generate(
                      dersler.length,
                      (dersIndex) {
                        final ders = dersler[dersIndex];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: dersIndex < dersler.length - 1 ? 8 : 0,
                          ),
                          child: _buildSubjectTile(
                            context,
                            ders: ders,
                            onTap: () {
                              controller.selectSubject(
                                ders,
                                anaBaslik,
                                sinavTuru,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
