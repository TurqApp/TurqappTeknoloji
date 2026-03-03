import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Slider/slider_catalog.dart';

class EducationSlider extends StatelessWidget {
  final List<String> imageList;
  final String? sliderId;

  const EducationSlider({
    super.key,
    required this.imageList,
    this.sliderId,
  });

  @override
  Widget build(BuildContext context) {
    if (sliderId == null || sliderId!.isEmpty) {
      return _buildCarousel(context, imageList);
    }

    final sliderRef =
        FirebaseFirestore.instance.collection('sliders').doc(sliderId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: sliderRef.snapshots(),
      builder: (context, metaSnapshot) {
        final hiddenDefaults =
            ((metaSnapshot.data?.data()?['hiddenDefaults'] as List<dynamic>?) ??
                    const <dynamic>[])
                .map((e) => e is num ? e.toInt() : -1)
                .where((e) => e >= 0)
                .toSet();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: sliderRef.collection('items').orderBy('order').snapshots(),
          builder: (context, itemsSnapshot) {
            final defaults = SliderCatalog.defaultImagesFor(sliderId!);
            final sourceImages = <String>[];
            final remoteDocs = itemsSnapshot.data?.docs ?? const [];
            final remoteByOrder = <int, String>{};
            final extras = <String>[];

            for (final doc in remoteDocs) {
              final order = (doc.data()['order'] as num?)?.toInt() ?? 0;
              final url = (doc.data()['imageUrl'] ?? '').toString();
              if (url.isEmpty) continue;
              if (order < defaults.length) {
                remoteByOrder[order] = url;
              } else {
                extras.add(url);
              }
            }

            for (var i = 0; i < defaults.length; i++) {
              if (hiddenDefaults.contains(i) && !remoteByOrder.containsKey(i)) {
                continue;
              }
              sourceImages.add(remoteByOrder[i] ?? defaults[i]);
            }
            sourceImages.addAll(extras);

            return _buildCarousel(
              context,
              sourceImages.isEmpty ? imageList : sourceImages,
            );
          },
        );
      },
    );
  }

  Widget _buildCarousel(BuildContext context, List<String> sources) {
    return CarouselSlider(
      items: sources.map((imgPath) {
        final isRemote = imgPath.startsWith('http');
        return Builder(
          builder: (BuildContext context) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: isRemote
                        ? CachedNetworkImageProvider(imgPath)
                        : AssetImage(imgPath) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
      options: CarouselOptions(
        autoPlay: true,
        height: MediaQuery.of(context).size.width / 2.7,
        enlargeCenterPage: false,
        autoPlayInterval: const Duration(seconds: 10),
        viewportFraction: 0.9,
      ),
    );
  }
}
