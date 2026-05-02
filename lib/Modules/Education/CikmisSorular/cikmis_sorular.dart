import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/Slider/education_slider.dart';
import 'package:turqappv2/Core/Services/education_question_bank_navigation_service.dart';
import 'package:turqappv2/Core/Services/slider_admin_navigation_service.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_controller.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_grid.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_preview.dart';
import 'package:turqappv2/Modules/TypeWriter/type_writer.dart';
import 'package:turqappv2/Themes/app_assets.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class CikmisSorular extends StatefulWidget {
  const CikmisSorular({
    super.key,
    this.embedded = false,
    this.showEmbeddedControls = true,
  });

  final bool embedded;
  final bool showEmbeddedControls;

  @override
  State<CikmisSorular> createState() => _CikmisSorularState();
}

class _CikmisSorularState extends State<CikmisSorular> {
  final CikmisSorularController controller =
      ensureCikmisSorularController(permanent: true);
  ScrollController get _scrollController => controller.scrollController;

  @override
  void initState() {
    super.initState();
    controller.requestScrollReset();
  }

  Widget _buildSliderHeader() {
    return EducationSlider(
      sliderId: 'denemeler',
      imageList: [
        AppAssets.previous1,
        AppAssets.practice2,
        AppAssets.previous3,
        AppAssets.previous4,
      ],
    );
  }

  Widget _buildSearchResults() {
    if (controller.isSearchLoading.value) {
      return const AppStateView.loading(title: '');
    }

    if (controller.searchResults.isEmpty) {
      return AppStateView.empty(
        title: 'past_questions.search_empty'.tr,
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      itemCount: controller.searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = controller.searchResults[index];
        final anaBaslik = (item['anaBaslik'] ?? '').toString();
        final title =
            anaBaslik.isNotEmpty ? anaBaslik : (item['title'] ?? '').toString();
        final sinavTuru = (item['sinavTuru'] ?? '').toString();
        final yil = (item['yil'] ?? '').toString();
        final baslik2 = (item['baslik2'] ?? '').toString();
        final baslik3 = (item['baslik3'] ?? '').toString();

        return ListTile(
          tileColor: const Color(0xFFF6F7FB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Text(
            title.isEmpty ? 'past_questions.mock_fallback'.tr : title,
            style: const TextStyle(
              fontFamily: 'MontserratBold',
              color: Colors.black,
            ),
          ),
          subtitle: Text(
            [sinavTuru, baslik2, baslik3]
                .where((e) => e.isNotEmpty)
                .join(' • '),
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              color: Colors.black54,
            ),
          ),
          trailing: const Icon(CupertinoIcons.chevron_right, size: 18),
          onTap: () {
            Get.to(
              () => CikmisSorularPreview(
                anaBaslik: (item['anaBaslik'] ?? '').toString(),
                sinavTuru: sinavTuru,
                yil: yil,
                baslik2: baslik2,
                baslik3: baslik3,
                sira: (item['sira'] as num?)?.toInt(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDefaultContent(List<Color> colors) {
    return Container(
      color: Colors.white,
      child: ListView(
        controller: _scrollController,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSliderHeader(),
              15.ph,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                    childAspectRatio: 3 / 4,
                  ),
                  itemCount: controller.covers.length,
                  itemBuilder: (context, index) {
                    final color = colors[index % colors.length];
                    final cover = controller.covers[index];
                    return CikmisSorularGrid(
                      anaBaslik: (cover['anaBaslik'] ?? '').toString(),
                      color: color,
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = <Color>[
      Colors.deepPurple,
      Colors.indigo,
      Colors.teal,
      Colors.deepOrange,
      Colors.pink,
      Colors.cyan.shade700,
      Colors.blueGrey,
      Colors.pink.shade900,
    ];

    final bodyContent = Expanded(
      child: Obx(() {
        if (controller.isLoading.value) {
          return ListView(
            controller: _scrollController,
            children: [
              _buildSliderHeader(),
              const SizedBox(
                height: 280,
                child: AppStateView.loading(title: ''),
              ),
            ],
          );
        }
        return controller.hasActiveSearch
            ? _buildSearchResults()
            : _buildDefaultContent(colors);
      }),
    );

    if (widget.embedded) {
      return Stack(
        children: [
          Column(children: [bodyContent]),
          if (widget.showEmbeddedControls)
            Positioned(
              bottom: 20,
              right: 20,
              child: ActionButton(
                context: context,
                menuItems: [
                  PullDownMenuItem(
                    icon: Icons.history,
                    title: 'pasaj.common.my_results'.tr,
                    onTap: () {
                      const EducationQuestionBankNavigationService()
                          .openPastQuestionResults();
                    },
                  ),
                  PullDownMenuItem(
                    icon: CupertinoIcons.slider_horizontal_3,
                    title: 'practice.slider_management'.tr,
                    onTap: () {
                      const SliderAdminNavigationService().openSliderAdmin(
                        sliderId: 'denemeler',
                        title: 'past_questions.title'.tr,
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Get.back();
                      },
                      icon: const Icon(
                        AppIcons.arrowLeft,
                        color: Colors.black,
                        size: 25,
                      ),
                    ),
                    TypewriterText(
                      text: 'past_questions.title'.tr,
                    ),
                  ],
                ),
                bodyContent,
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: ActionButton(
        context: context,
        menuItems: [
          PullDownMenuItem(
            icon: Icons.history,
            title: 'pasaj.common.my_results'.tr,
            onTap: () {
              const EducationQuestionBankNavigationService()
                  .openPastQuestionResults();
            },
          ),
          PullDownMenuItem(
            icon: CupertinoIcons.slider_horizontal_3,
            title: 'practice.slider_management'.tr,
            onTap: () {
              const SliderAdminNavigationService().openSliderAdmin(
                sliderId: 'denemeler',
                title: 'past_questions.title'.tr,
              );
            },
          ),
        ],
      ),
    );
  }
}
