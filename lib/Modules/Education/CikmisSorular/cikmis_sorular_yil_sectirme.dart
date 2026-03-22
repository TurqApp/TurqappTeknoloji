import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/cikmis_sorular_repository.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_baslik2_secimi.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_baslik3_secimi.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_preview.dart';

part 'cikmis_sorular_yil_sectirme_actions_part.dart';
part 'cikmis_sorular_yil_sectirme_content_part.dart';

class CikmisSorularYilSectirme extends StatefulWidget {
  final String anaBaslik;
  final String sinavTuru;
  final String baslik2;
  final String baslik3;

  const CikmisSorularYilSectirme({
    super.key,
    required this.anaBaslik,
    required this.sinavTuru,
    required this.baslik2,
    required this.baslik3,
  });

  @override
  State<CikmisSorularYilSectirme> createState() =>
      _CikmisSorularYilSectirmeState();
}

class _CikmisSorularYilSectirmeState extends State<CikmisSorularYilSectirme> {
  final CikmisSorularRepository _repository = CikmisSorularRepository.ensure();
  List<String> yillar = [];
  static const _english = 'İngilizce';
  static const _german = 'Almanca';
  static const _arabic = 'Arapça';
  static const _french = 'Fransızca';
  static const _russian = 'Rusça';
  static const _associate = 'Ön Lisans';
  static const _undergraduate = 'Lisans';
  static const _aGroup = 'A Grubu';
  static const _fieldKnowledge = 'Alan Bilgisi';
  static const _educationSciences = 'Eğitim Bilimleri';
  static const _generalAbilityCulture = 'GK - GY';
  static const _ydt = 'YDT';
  static const _tyt = 'TYT';
  static const _ayt = 'AYT';
  static const _dgs = 'DGS';
  static const _lgs = 'LGS';
  static const _kpss = 'KPSS';
  static const _ktbt = 'KTBT';
  static const _ttbt = 'TTBT';
  static const _ales = 'ALES';
  static const _yks = 'YKS';

  String _denemeLabel(int index) =>
      'past_questions.mock_label'.trParams({'index': '${index + 1}'});

  String _localizedExamType(String raw) {
    switch (raw) {
      case _english:
        return 'tests.language.english'.tr;
      case _german:
        return 'tests.language.german'.tr;
      case _arabic:
        return 'tests.language.arabic'.tr;
      case _french:
        return 'tests.language.french'.tr;
      case _russian:
        return 'tests.language.russian'.tr;
      case _associate:
        return 'past_questions.exam_type.associate'.tr;
      case _undergraduate:
        return 'past_questions.exam_type.undergraduate'.tr;
      case _generalAbilityCulture:
        return 'past_questions.branch.general_ability_culture'.tr;
      case _aGroup:
        return 'past_questions.branch.group_a'.tr;
      case _educationSciences:
        return 'past_questions.branch.education_sciences'.tr;
      case _fieldKnowledge:
        return 'past_questions.branch.field_knowledge'.tr;
      default:
        return raw;
    }
  }

  bool _isLanguageOrDirectBranch(String raw) {
    switch (raw) {
      case _ttbt:
      case _ktbt:
      case _ales:
      case _german:
      case _english:
      case _french:
      case _russian:
      case _arabic:
        return true;
      default:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  void getData() {
    _repository
        .distinctValues(
      where: (doc) {
        if ((doc['anaBaslik'] ?? '').toString() != widget.anaBaslik ||
            (doc['sinavTuru'] ?? '').toString() != widget.sinavTuru) {
          return false;
        }
        if (_isLanguageOrDirectBranch(widget.baslik2)) {
          return true;
        }
        if (widget.baslik3.isNotEmpty) {
          return (doc['baslik3'] ?? '').toString() == widget.baslik3 &&
              (doc['baslik2'] ?? '').toString() == widget.baslik2;
        }
        if (widget.baslik2.isNotEmpty) {
          return (doc['baslik2'] ?? '').toString() == widget.baslik2;
        }
        return true;
      },
      field: 'yil',
      descendingNumeric: true,
    )
        .then((items) {
      if (mounted) {
        setState(() {
          yillar = items;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
