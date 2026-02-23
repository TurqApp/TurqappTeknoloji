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

class SearchAnswerKey extends StatelessWidget {
  const SearchAnswerKey({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SearchAnswerKeyController());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Ara"),
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
                  decoration: const InputDecoration(
                    hintText: "Ara",
                    hintStyle: TextStyle(
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
        () => ListView.builder(
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
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
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
        ),
      ),
    );
  }
}
