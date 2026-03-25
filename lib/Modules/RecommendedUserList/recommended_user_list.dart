import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/RecommendedUserList/RecommendedUserContent/recommended_user_content.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import '../../Models/recommended_user_model.dart';
import 'recommended_user_list_controller.dart';

class RecommendedUserList extends StatefulWidget {
  final int batch; // 1,2,3... her 12 içerik sonrası slot numarası
  const RecommendedUserList({super.key, this.batch = 1});

  @override
  State<RecommendedUserList> createState() => _RecommendedUserListState();
}

class _RecommendedUserListState extends State<RecommendedUserList> {
  late final ScrollController _scrollController;
  late final RecommendedUserListController controller;
  bool _prefetchRequested = false;

  @override
  void initState() {
    super.initState();
    controller = RecommendedUserListController.ensure();
    _scrollController = ScrollController(keepScrollOffset: false);
    // İlk frame’den sonra görünürlüğe yakınsa prefetch et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tryPrefetch();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Her build sonrası konumu tekrar kontrol et (scroll ile tetiklenir)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tryPrefetch();
    });

    return Obx(() {
      // Slot akışta sabit kalsın; veri gelene kadar placeholder göster.
      if (controller.list.isEmpty && !controller.hasError.value) {
        return _buildLoadingPlaceholder();
      }

      // Hata varsa sessizce gizle
      if (controller.list.isEmpty) {
        return const SizedBox.shrink();
      }

      final List<RecommendedUserModel> items = controller.list;
      // Slot bazlı döndürme: her slot farklı 15'lik pencere göstersin
      const int window = 6;
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
                  'recommended_users.title'.tr,
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
            height: (MediaQuery.of(context).size.height * 0.245)
                .clamp(170.0, 205.0),
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: showItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final model = showItems[index];
                return SizedBox(
                  width: (MediaQuery.of(context).size.width * 0.44)
                      .clamp(150.0, 186.0),
                  child: RecommendedUserContent(model: model),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  void _tryPrefetch() {
    if (!mounted) return;
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
                'recommended_users.title'.tr,
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
          height:
              (MediaQuery.of(context).size.height * 0.245).clamp(170.0, 205.0),
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
