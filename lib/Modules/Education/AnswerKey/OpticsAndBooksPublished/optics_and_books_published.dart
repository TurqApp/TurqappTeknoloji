import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/AnswerKeyContent/answer_key_content.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticalFormContent/optical_form_content.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticsAndBooksPublished/optics_and_books_published_controller.dart';

class OpticsAndBooksPublished extends StatefulWidget {
  const OpticsAndBooksPublished({super.key});

  @override
  State<OpticsAndBooksPublished> createState() =>
      _OpticsAndBooksPublishedState();
}

class _OpticsAndBooksPublishedState extends State<OpticsAndBooksPublished> {
  late final OpticsAndBooksPublishedController controller;
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  late final String _pageLineBarTag =
      'OpticsAndBooksPublished_${identityHashCode(this)}';
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _ownsController = maybeFindOpticsAndBooksPublishedController() == null;
    controller = ensureOpticsAndBooksPublishedController();
    controller.refreshOnOpen();
    _scrollController.addListener(() {
      controller.scrollOffset.value = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindOpticsAndBooksPublishedController(),
          controller,
        )) {
      Get.delete<OpticsAndBooksPublishedController>(force: true);
    }
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildBooksPage() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Obx(
        () => controller.isLoading.value
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: CupertinoActivityIndicator(),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 0.6,
                  ),
                  itemCount: controller.list.length,
                  itemBuilder: (context, index) {
                    final item = controller.list[index];
                    return AnswerKeyContent(
                      key: ValueKey(item.docID),
                      model: item,
                      onUpdate: (v) => controller.getData(),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildOpticalPage() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Obx(
        () => controller.selection.value == 1 && controller.isLoading.value
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: CupertinoActivityIndicator(),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.optikler.length,
                itemBuilder: (context, index) {
                  return OpticalFormContent(
                    model: controller.optikler[index],
                    update: () => controller.getOptikler(),
                  );
                },
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                BackButtons(text: 'pasaj.common.published'.tr),
                Obx(
                  () => PageLineBar(
                    barList: [
                      "${'answer_key.book'.tr} (${controller.list.length})",
                      "${'answer_key.optical_form'.tr} (${controller.optikler.length})",
                    ],
                    pageName: _pageLineBarTag,
                    pageController: _pageController,
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      controller.setSelection(index);
                      syncPageLineBarSelection(
                        _pageLineBarTag,
                        index,
                      );
                    },
                    children: [
                      _buildBooksPage(),
                      _buildOpticalPage(),
                    ],
                  ),
                ),
              ],
            ),
            ScrollTotopButton(
              scrollController: _scrollController,
              visibilityThreshold: 350,
            ),
          ],
        ),
      ),
    );
  }
}
