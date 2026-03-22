import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/SearchAnswerKey/search_answer_key_controller.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class SearchAnswerKey extends StatefulWidget {
  const SearchAnswerKey({super.key});

  @override
  State<SearchAnswerKey> createState() => _SearchAnswerKeyState();
}

class _SearchAnswerKeyState extends State<SearchAnswerKey> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final SearchAnswerKeyController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'answer_key_search_${identityHashCode(this)}';
    _ownsController =
        SearchAnswerKeyController.maybeFind(tag: _controllerTag) == null;
    controller = SearchAnswerKeyController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController = SearchAnswerKeyController.maybeFind(
        tag: _controllerTag,
      );
      if (identical(registeredController, controller)) {
        Get.delete<SearchAnswerKeyController>(tag: _controllerTag, force: true);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'common.search'.tr),
            Expanded(
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _buildSearchBar(context, controller),
                    _buildBookletList(context, controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    SearchAnswerKeyController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              const Icon(AppIcons.search, color: Colors.pink),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  cursorColor: Colors.black,
                  controller: controller.searchController,
                  onChanged: controller.onSearchChanged,
                  inputFormatters: [LengthLimitingTextInputFormatter(100)],
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'common.search'.tr,
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontFamily: "Montserrat",
                    ),
                    border: InputBorder.none,
                  ),
                  style: TextStyles.medium15Black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookletList(
    BuildContext context,
    SearchAnswerKeyController controller,
  ) {
    return Expanded(
      child: Obx(
        () {
          if (controller.isLoading.value) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (controller.searchController.text.trim().length < 2) {
            return Center(
              child: Text(
                'answer_key.search_min_chars'.tr,
                style: TextStyle(
                  color: Colors.black54,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            );
          }
          if (controller.filteredList.isEmpty) {
            return Center(
              child: Text(
                'common.no_results'.tr,
                style: TextStyle(
                  color: Colors.black54,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: controller.filteredList.length,
            itemBuilder: (context, index) {
              final item = controller.filteredList[index];
              return Padding(
                padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
                child: GestureDetector(
                  onTap: () => controller.navigateToPreview(item),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      border:
                          Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CachedNetworkImage(
                            imageUrl: item.cover,
                            fit: BoxFit.contain,
                            height: 80,
                            width: 80,
                            placeholder: (context, url) => const Center(
                              child: CupertinoActivityIndicator(),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                          12.pw,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  item.baslik,
                                  maxLines: 2,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontFamily: "MontserratBold",
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.basimTarihi,
                                  style: const TextStyle(
                                    color: Colors.indigo,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium",
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.yayinEvi,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 15,
                                    fontFamily: "MontserratBold",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
