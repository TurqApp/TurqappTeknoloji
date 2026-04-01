import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Widgets/search_reset_on_page_return_scope.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeGrid/deneme_grid.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SearchDeneme/search_deneme_controller.dart';

class SearchDeneme extends StatefulWidget {
  const SearchDeneme({super.key});

  @override
  State<SearchDeneme> createState() => _SearchDenemeState();
}

class _SearchDenemeState extends State<SearchDeneme> {
  late final SearchDenemeController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    final existing = maybeFindSearchDenemeController();
    _ownsController = existing == null;
    controller = existing ?? ensureSearchDenemeController();
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(maybeFindSearchDenemeController(), controller)) {
      Get.delete<SearchDenemeController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SearchResetOnPageReturnScope(
      onReset: controller.resetSearch,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              BackButtons(text: 'practice.search_title'.tr),
              _buildSearchShell(),
              Expanded(
                child: Obx(() {
                  return _buildSearchContent();
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchShell() {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
        child: Container(
          height: 50,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.black),
                Expanded(
                  child: TextField(
                    controller: controller.searchController,
                    focusNode: controller.focusNode,
                    onChanged: controller.filterSearchResults,
                    decoration: InputDecoration(
                      hintText: 'common.search'.tr,
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchContent() {
    if (controller.isLoading.value) {
      return const Center(
        child: CupertinoActivityIndicator(radius: 20),
      );
    }
    if (controller.filteredList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.quiz_outlined,
                size: 60,
                color: Colors.grey,
              ),
              const SizedBox(height: 20),
              Text(
                'practice.search_empty_title'.tr,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: "MontserratBold",
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                controller.searchController.text.isEmpty
                    ? 'practice.search_empty_body_empty'.tr
                    : 'practice.search_empty_body_query'.tr,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontFamily: "MontserratMedium",
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: Colors.black,
      onRefresh: controller.getData,
      child: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              childAspectRatio: 0.52,
            ),
            itemCount: controller.filteredList.length,
            itemBuilder: (context, index) {
              return DenemeGrid(
                model: controller.filteredList[index],
                getData: controller.getData,
              );
            },
          ),
        ),
      ),
    );
  }
}
