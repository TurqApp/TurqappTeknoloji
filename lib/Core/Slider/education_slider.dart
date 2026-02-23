import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class EducationSlider extends StatelessWidget {
  final List<String> imageList;

  const EducationSlider({super.key, required this.imageList});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      items:
          imageList.map((imgPath) {
            return Builder(
              builder: (BuildContext context) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                  ), // Her iki yandan 6px boşluk
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: AssetImage(imgPath),
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
