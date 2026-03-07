import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
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

  double _tailSpaceHeight() {
    final screenHeight = MediaQuery.of(context).size.height;
    return (screenHeight * 0.24).clamp(120.0, 200.0);
  }

  @override
  void initState() {
    super.initState();
    controller.getFloods(widget.mainModel.floodCount.toInt(),
        widget.mainModel.docID); // floodCount: 10 örnek
    print(widget.mainModel.floodCount.toInt());
    print(widget.mainModel.docID);
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
                      BackButtons(text: "Flood"),
                    ],
                  ),
                );
              }

              children.add(
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: contentWidget,
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
