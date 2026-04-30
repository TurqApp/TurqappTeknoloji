import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/education_detail_navigation_service.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class TutoringCategoryModel {
  final String name;
  final IconData icon;
  final Color color;

  TutoringCategoryModel({
    required this.name,
    required this.icon,
    required this.color,
  });

  String get localizedName => tutoringBranchLabel(name);
}

String tutoringBranchKey(String raw) {
  switch (raw) {
    case 'Yaz Okulu':
      return 'tutoring.branch.summer_school';
    case 'Orta Öğretim':
      return 'tutoring.branch.secondary_education';
    case 'İlk Öğretim':
      return 'tutoring.branch.primary_education';
    case 'Yabancı Dil':
      return 'tutoring.branch.foreign_language';
    case 'Yazılım':
      return 'tutoring.branch.software';
    case 'Direksiyon':
      return 'tutoring.branch.driving';
    case 'Spor':
      return 'tutoring.branch.sports';
    case 'Sanat':
      return 'tutoring.branch.art';
    case 'Müzik':
      return 'tutoring.branch.music';
    case 'Tiyatro':
      return 'tutoring.branch.theatre';
    case 'Kişisel Gelişim':
      return 'tutoring.branch.personal_development';
    case 'Mesleki':
      return 'tutoring.branch.vocational';
    case 'Özel Eğitim':
      return 'tutoring.branch.special_education';
    case 'Çocuk':
      return 'tutoring.branch.children';
    case 'Diksiyon':
      return 'tutoring.branch.diction';
    case 'Fotoğrafçılık':
      return 'tutoring.branch.photography';
    default:
      return raw;
  }
}

String tutoringBranchLabel(String raw) {
  final key = tutoringBranchKey(raw);
  return key == raw ? raw : key.tr;
}

List<TutoringCategoryModel> kategoriler = [
  TutoringCategoryModel(
    name: "Yaz Okulu",
    icon: Icons.sunny,
    color: Colors.pink,
  ),
  TutoringCategoryModel(
    name: "Orta Öğretim",
    icon: Icons.school_outlined,
    color: Colors.blueGrey,
  ),
  TutoringCategoryModel(
    name: "İlk Öğretim",
    icon: Icons.home_outlined,
    color: Colors.teal,
  ),
  TutoringCategoryModel(
    name: "Yabancı Dil",
    icon: Icons.language_outlined,
    color: Colors.deepOrange,
  ),
  TutoringCategoryModel(
    name: "Yazılım",
    icon: Icons.computer_outlined,
    color: Colors.indigo,
  ),
  TutoringCategoryModel(
    name: "Direksiyon",
    icon: Icons.directions_car_outlined,
    color: Colors.orange,
  ),
  TutoringCategoryModel(
    name: "Spor",
    icon: Icons.fitness_center_outlined,
    color: Colors.green,
  ),
  TutoringCategoryModel(
    name: "Sanat",
    icon: Icons.palette_outlined,
    color: Colors.purple,
  ),
  TutoringCategoryModel(
    name: "Müzik",
    icon: Icons.music_note_outlined,
    color: Colors.black,
  ),
  TutoringCategoryModel(
    name: "Tiyatro",
    icon: Icons.theater_comedy_outlined,
    color: Colors.red,
  ),
  TutoringCategoryModel(
    name: "Kişisel Gelişim",
    icon: Icons.self_improvement_outlined,
    color: Colors.amber,
  ),
  TutoringCategoryModel(
    name: "Mesleki",
    icon: Icons.business_center_outlined,
    color: Colors.brown,
  ),
  TutoringCategoryModel(
    name: "Özel Eğitim",
    icon: Icons.accessibility_outlined,
    color: Colors.cyan,
  ),
  TutoringCategoryModel(
    name: "Çocuk",
    icon: Icons.child_care_outlined,
    color: Colors.pinkAccent,
  ),
  TutoringCategoryModel(
    name: "Diksiyon",
    icon: Icons.speaker_outlined,
    color: Colors.grey,
  ),
  TutoringCategoryModel(
    name: "Fotoğrafçılık",
    icon: Icons.camera_alt_outlined,
    color: Colors.indigo,
  ),
];

class TutoringCategoryWidget extends StatelessWidget {
  final List<TutoringCategoryModel> categories;

  const TutoringCategoryWidget({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceEvenly, // Aralarındaki mesafeyi eşit tutuyor
        children: categories.map((category) {
          return GestureDetector(
            onTap: () {
              const EducationDetailNavigationService()
                  .openTutoringCategory(category.name);
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: category.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      category.icon,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  8.ph,
                  Text(
                    category.localizedName,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
