import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/TextStyles.dart';
import 'package:turqappv2/Modules/RecommendedUserList/RecommendedUserContent/RecommendedUserContent.dart';
import 'package:turqappv2/Utils/EmptyPadding.dart';
import '../../Models/RecommendedUserModel.dart';
import 'RecommendedUserListController.dart';

class RecommendedUserList extends StatefulWidget {
  final int batch; // 1,2,3... her 12 içerik sonrası slot numarası
  const RecommendedUserList({super.key, this.batch = 1});

  @override
  State<RecommendedUserList> createState() => _RecommendedUserListState();
}

class _RecommendedUserListState extends State<RecommendedUserList> {
  late final PageController _pageController;
  bool _prefetchRequested = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.45, keepPage: true);
    // İlk frame’den sonra görünürlüğe yakınsa prefetch et
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryPrefetch());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RecommendedUserListController>();

    // Her build sonrası konumu tekrar kontrol et (scroll ile tetiklenir)
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryPrefetch());

    return Obx(() {
      // Loading durumu: placeholder göster
      if (controller.isLoading.value && controller.list.isEmpty) {
        return _buildLoadingPlaceholder();
      }

      // Liste boşsa hiçbir şey gösterme
      if (controller.list.isEmpty) {
        return const SizedBox.shrink();
      }

      final List<RecommendedUserModel> items = controller.list;
      // Slot bazlı döndürme: her slot farklı 15'lik pencere göstersin
      const int window = 15;
      if (items.isEmpty) return const SizedBox.shrink();
      final int start = ((widget.batch - 1) * window) % items.length;
      final List<RecommendedUserModel> showItems = [
        ...items.sublist(start),
        ...items.sublist(0, start),
      ].take(window).toList();
      if (showItems.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Tanıyor Olabileceğin Kişiler",
                  style: TextStyles.bold16Black,
                ),
                12.pw,
                Expanded(
                  child: Divider(color: Colors.grey.withAlpha(50)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 250,
            child: PageView.builder(
              padEnds: false,
              controller: _pageController,
              itemCount: showItems.length,
              itemBuilder: (context, index) {
                final model = showItems[index];
                return Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 15 : 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: RecommendedUserContent(model: model),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  void _tryPrefetch() {
    if (_prefetchRequested) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final pos = box.localToGlobal(Offset.zero);
    final screenH = MediaQuery.of(context).size.height;
    final lookahead = screenH * 1.2; // 1.2 ekran önceden
    // Widget üst kenarı, ekran altı + lookahead altında ise prefetch
    if (pos.dy < screenH + lookahead) {
      _prefetchRequested = true;
      try {
        final controller = Get.find<RecommendedUserListController>();
        controller.ensureLoaded(limit: controller.usersLimitInitial);
      } catch (_) {
        _prefetchRequested = false; // controller bulunamazsa tekrar dene
      }
    }
  }

  Widget _buildLoadingPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Tanıyor Olabileceğin Kişiler",
                style: TextStyles.bold16Black,
              ),
              12.pw,
              Expanded(
                child: Divider(color: Colors.grey.withAlpha(50)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 15),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.45,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
