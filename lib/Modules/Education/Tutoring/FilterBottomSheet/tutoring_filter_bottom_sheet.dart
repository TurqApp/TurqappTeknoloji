import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Education/Tutoring/FilterBottomSheet/tutoring_filter_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/Widgets/pasaj_selection_chip.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'tutoring_filter_bottom_sheet_content_part.dart';

class TutoringFilterBottomSheet extends StatelessWidget {
  final TutoringController controller;

  TutoringFilterBottomSheet({super.key, required this.controller});
  final TutoringFilterController filterController =
      ensureTutoringFilterController();

  String _branchLabel(String value) {
    const map = {
      'Yaz Okulu': 'tutoring.branch.summer_school',
      'Orta Öğretim': 'tutoring.branch.secondary_education',
      'İlk Öğretim': 'tutoring.branch.primary_education',
      'Yabancı Dil': 'tutoring.branch.foreign_language',
      'Yazılım': 'tutoring.branch.software',
      'Direksiyon': 'tutoring.branch.driving',
      'Spor': 'tutoring.branch.sports',
      'Sanat': 'tutoring.branch.art',
      'Müzik': 'tutoring.branch.music',
      'Tiyatro': 'tutoring.branch.theatre',
      'Kişisel Gelişim': 'tutoring.branch.personal_development',
      'Mesleki': 'tutoring.branch.vocational',
      'Özel Eğitim': 'tutoring.branch.special_education',
      'Çocuk': 'tutoring.branch.children',
      'Diksiyon': 'tutoring.branch.diction',
      'Fotoğrafçılık': 'tutoring.branch.photography',
    };
    return (map[value] ?? value).tr;
  }

  String _genderLabel(String value) {
    const map = {
      'Erkek': 'tutoring.gender.male',
      'Kadın': 'tutoring.gender.female',
      'Farketmez': 'tutoring.gender.any',
    };
    return (map[value] ?? value).tr;
  }

  String _sortLabel(String value) {
    const map = {
      'En Yeni': 'tutoring.sort.latest',
      'Bana En Yakın': 'tutoring.sort.nearest',
      'En Çok Görüntülenen': 'tutoring.sort.most_viewed',
    };
    return (map[value] ?? value).tr;
  }

  String _lessonPlaceLabel(String value) {
    const map = {
      'Öğrencinin Evi': 'tutoring.lesson_place.student_home',
      'Öğretmenin Evi': 'tutoring.lesson_place.teacher_home',
      'Öğrencinin veya Öğretmenin Evi': 'tutoring.lesson_place.either_home',
      'Uzaktan Eğitim': 'tutoring.lesson_place.remote',
      'Ders Verme Alanı': 'tutoring.lesson_place.lesson_area',
    };
    return (map[value] ?? value).tr;
  }

  @override
  Widget build(BuildContext context) {
    return _buildPage(context);
  }
}
