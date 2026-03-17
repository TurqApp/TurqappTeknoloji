import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Widgets/skeleton_loader.dart';
import 'package:turqappv2/Modules/Education/Tests/SearchTests/search_tests_controller.dart';
import 'package:turqappv2/Modules/Education/Tests/TestsGrid/tests_grid.dart';
import 'package:turqappv2/Themes/app_icons.dart';

class SearchTests extends StatelessWidget {
  const SearchTests({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SearchTestsController());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Test Ara"),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Container(
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
                            decoration: const InputDecoration(
                              hintText: 'Ara',
                              hintStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(
                                AppIcons.search,
                                color: Colors.pink,
                              ),
                              border: OutlineInputBorder(
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
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Obx(
                        () => controller.isLoading.value &&
                                controller.filteredList.isEmpty
                            ? const EducationGridSkeleton(itemCount: 4)
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
