import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/Slider/education_slider.dart';
import 'package:turqappv2/Core/Slider/slider_admin_view.dart';
import 'package:turqappv2/Core/Widgets/pasaj_listing_ad_layout.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeGrid/deneme_grid.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/MyPracticeExams/my_practice_exams.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SavedPracticeExams/saved_practice_exams.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/deneme_sinavlari_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeTurleriListesi/deneme_turleri_listesi.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SearchDeneme/search_deneme.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavHazirla/sinav_hazirla.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavSonuclarim/sinav_sonuclarim.dart';
import 'package:turqappv2/Modules/Profile/BecomeVerifiedAccount/become_verified_account.dart';
import 'package:turqappv2/Modules/TypeWriter/type_writer.dart';
import 'package:turqappv2/Themes/app_assets.dart';
import 'package:turqappv2/Core/Widgets/skeleton_loader.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'deneme_sinavlari_content_part.dart';
part 'deneme_sinavlari_actions_part.dart';
part 'deneme_sinavlari_sections_part.dart';

class DenemeSinavlari extends StatelessWidget {
  DenemeSinavlari({
    super.key,
    this.embedded = false,
    this.showEmbeddedControls = true,
  });

  final bool embedded;
  final bool showEmbeddedControls;
  final DenemeSinavlariController controller =
      ensureDenemeSinavlariController(permanent: true);
  ScrollController get _scrollController => controller.scrollController;

  @override
  Widget build(BuildContext context) => _buildPage(context);

  Widget _buildPage(BuildContext context) {
    final bodyContent = _buildBodyContent(context);

    if (embedded) {
      return Stack(
        children: [
          Column(children: [bodyContent]),
          Obx(
            () => controller.showOkulAlert.value
                ? _buildSchoolAlertSheet(context)
                : const SizedBox.shrink(),
          ),
          if (showEmbeddedControls)
            ScrollTotopButton(
              scrollController: _scrollController,
              visibilityThreshold: 350,
            ),
          if (showEmbeddedControls) _buildFloatingAction(context),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                bodyContent,
              ],
            ),
            Obx(
              () => controller.showOkulAlert.value
                  ? _buildSchoolAlertSheet(context)
                  : const SizedBox.shrink(),
            ),
            ScrollTotopButton(
              scrollController: _scrollController,
              visibilityThreshold: 350,
            ),
            _buildFloatingAction(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              IconButton(
                onPressed: Get.back,
                icon: const Icon(
                  AppIcons.arrowLeft,
                  color: Colors.black,
                  size: 25,
                ),
              ),
              TypewriterText(
                text: 'pasaj.tabs.online_exam'.tr,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Get.to(() => SearchDeneme()),
          icon: const Icon(AppIcons.search, color: Colors.black),
        ),
      ],
    );
  }
}
