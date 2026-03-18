import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Modules/Agenda/Common/agenda_spacing.dart';
import '../AgendaContent/agenda_content.dart';
import 'flood_listing_controller.dart';

class FloodListing extends StatefulWidget {
  final PostsModel mainModel;
  const FloodListing({super.key, required this.mainModel});

  @override
  State<FloodListing> createState() => _FloodListingState();
}

class _FloodListingState extends State<FloodListing> {
  final FloodListingController controller = Get.put(FloodListingController());
  static const double _chainLineWidth = 2.0;
  static const Color _chainLineColor = Color(0xFFD7DCE2);

  double _tailSpaceHeight() {
    final screenHeight = MediaQuery.of(context).size.height;
    return (screenHeight * 0.24).clamp(120.0, 200.0);
  }

  double _chainLeftOffset() =>
      AgendaSpacing.modernContainerPadding.left + AgendaSpacing.avatarRadius;

  @override
  void initState() {
    super.initState();
    controller.getFloods(widget.mainModel.floodCount.toInt(),
        widget.mainModel.docID); // floodCount: 10 örnek
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final centeredIndex = controller.centeredIndex.value;

          return ListView.builder(
            controller: controller.scrollController,
            itemCount: controller.floods.length + 1, // +1 ekledik
            itemBuilder: (context, index) {
              final tailSpace = _tailSpaceHeight();
              if (index == controller.floods.length) {
                // listenin sonu
                if (controller.floods.length < 4) {
                  // 4'ten az öğe varsa, en sonda reklam göster
                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: AdmobKare(),
                      ),
                      SizedBox(height: tailSpace),
                    ],
                  );
                }
                // aksi halde sadece boşluk
                return SizedBox(height: tailSpace);
              }

              final model = controller.floods[index];
              final itemKey = controller.getFloodKey(index);
              final isCentered = centeredIndex == index;

              final contentWidget = AgendaContent(
                key: itemKey,
                model: model,
                isPreview: true,
                shouldPlay: isCentered,
              );

              final children = <Widget>[];

              if (index == 0) {
                children.add(
                  Row(
                    children: [
                      BackButtons(text: "Dizi"),
                    ],
                  ),
                );
              }

              children.add(
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Stack(
                    children: [
                      Positioned(
                        left: _chainLeftOffset(),
                        top: index == 0 ? 50 : 0,
                        bottom: index == controller.floods.length - 1 ? 26 : 0,
                        child: Container(
                          width: _chainLineWidth,
                          decoration: BoxDecoration(
                            color: _chainLineColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      contentWidget,
                    ],
                  ),
                ),
              );

              // Her 4 gönderiden sonra kare reklam ekle
              if ((index + 1) % 4 == 0) {
                final slot = ((index + 1) ~/ 4);
                children.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: AdmobKare(key: ValueKey('flood-ad-$slot')),
                  ),
                );
              }

              return Column(children: children);
            },
          );
        }),
      ),
    );
  }
}
