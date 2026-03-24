import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Widgets/skeleton_loader.dart';
import 'package:turqappv2/Modules/Education/Tests/SearchTests/search_tests_controller.dart';
import 'package:turqappv2/Modules/Education/Tests/TestsGrid/tests_grid.dart';
import 'package:turqappv2/Themes/app_icons.dart';

class SearchTests extends StatefulWidget {
  const SearchTests({super.key});

  @override
  State<SearchTests> createState() => _SearchTestsState();
}

class _SearchTestsState extends State<SearchTests> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final SearchTestsController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'tests_search_${identityHashCode(this)}';
    _ownsController =
        SearchTestsController.maybeFind(tag: _controllerTag) == null;
    controller = SearchTestsController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController =
          SearchTestsController.maybeFind(tag: _controllerTag);
      if (identical(registeredController, controller)) {
        Get.delete<SearchTestsController>(tag: _controllerTag, force: true);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildPage();
  }

  Widget _buildPage() {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'tests.search_title'.tr),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildSearchField(),
                    _buildGridContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: 15,
          right: 15,
          left: 15,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.all(
              Radius.circular(12),
            ),
          ),
          child: TextField(
            cursorColor: Colors.black,
            controller: controller.searchController,
            focusNode: controller.focusNode,
            onChanged: controller.filterSearchResults,
            decoration: InputDecoration(
              hintText: 'common.search'.tr,
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: Icon(
                AppIcons.search,
                color: Colors.pink,
              ),
              border: const OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: 'MontserratMedium',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Obx(
        () => controller.isLoading.value && controller.filteredList.isEmpty
            ? const EducationGridSkeleton(itemCount: 4)
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 5.0,
                  mainAxisSpacing: 5.0,
                  childAspectRatio: 2 / 4,
                ),
                itemCount: controller.filteredList.length,
                itemBuilder: (context, index) {
                  return TestsGrid(
                    model: controller.filteredList[index],
                  );
                },
              ),
      ),
    );
  }
}
