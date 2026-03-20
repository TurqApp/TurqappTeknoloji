import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/cikmis_sorular_repository.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_baslik2_secimi.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_baslik3_secimi.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_preview.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(
              text: 'past_questions.tests_by_type'
                  .trParams({'type': _localizedExamType(widget.sinavTuru)}),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: GridView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: yillar.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              if (_isLanguageOrDirectBranch(widget.sinavTuru)) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CikmisSorularBaslik2Secimi(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: widget.sinavTuru,
                                      yil: yillar[index],
                                    ),
                                  ),
                                );
                              } else if (widget.sinavTuru == _undergraduate &&
                                  widget.baslik2 == _aGroup) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CikmisSorularBaslik3Secimi(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: widget.sinavTuru,
                                      yil: yillar[index],
                                      baslik2: widget.baslik2,
                                    ),
                                  ),
                                );
                              } else if (widget.sinavTuru == _undergraduate &&
                                  widget.baslik2 == _fieldKnowledge) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CikmisSorularPreview(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: widget.sinavTuru,
                                      yil: yillar[index],
                                      baslik2: widget.baslik2,
                                      baslik3: widget.baslik3,
                                    ),
                                  ),
                                );
                              } else if (widget.sinavTuru == _undergraduate &&
                                  widget.baslik2 == _educationSciences) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CikmisSorularPreview(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: widget.sinavTuru,
                                      yil: yillar[index],
                                      baslik2: widget.baslik2,
                                      baslik3: widget.baslik3,
                                    ),
                                  ),
                                );
                              } else if (widget.sinavTuru == _undergraduate &&
                                  widget.baslik2 == _generalAbilityCulture) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CikmisSorularPreview(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: widget.sinavTuru,
                                      yil: yillar[index],
                                      baslik2: widget.baslik2,
                                      baslik3: widget.sinavTuru,
                                    ),
                                  ),
                                );
                              } else if (widget.anaBaslik == _yks &&
                                  widget.sinavTuru == _ydt) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CikmisSorularPreview(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: widget.sinavTuru,
                                      yil: yillar[index],
                                      baslik2: widget.baslik2,
                                      baslik3: widget.sinavTuru,
                                    ),
                                  ),
                                );
                              } else if (widget.anaBaslik == _yks &&
                                  widget.sinavTuru == _tyt) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CikmisSorularPreview(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: widget.sinavTuru,
                                      yil: yillar[index],
                                      baslik2: _tyt,
                                      baslik3: _tyt,
                                    ),
                                  ),
                                );
                              } else if (widget.anaBaslik == _yks &&
                                  widget.sinavTuru == _ayt) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CikmisSorularPreview(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: widget.sinavTuru,
                                      yil: yillar[index],
                                      baslik2: _ayt,
                                      baslik3: _ayt,
                                    ),
                                  ),
                                );
                              } else if (widget.anaBaslik == _dgs &&
                                  widget.sinavTuru == _dgs) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CikmisSorularPreview(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: widget.sinavTuru,
                                      yil: yillar[index],
                                      baslik2: _dgs,
                                      baslik3: _dgs,
                                    ),
                                  ),
                                );
                              } else if (widget.anaBaslik == _lgs &&
                                  widget.sinavTuru == _lgs) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CikmisSorularPreview(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: widget.sinavTuru,
                                      yil: yillar[index],
                                      baslik2: _lgs,
                                      baslik3: _lgs,
                                    ),
                                  ),
                                );
                              } else if (widget.anaBaslik == _kpss &&
                                  widget.sinavTuru == _associate) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CikmisSorularPreview(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: widget.sinavTuru,
                                      yil: yillar[index],
                                      baslik2: _associate,
                                      baslik3: _associate,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CikmisSorularPreview(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: widget.sinavTuru,
                                      yil: yillar[index],
                                      baslik2: widget.baslik2,
                                      baslik3: widget.baslik3,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.cyan,
                                          Colors.black.withValues(alpha: 0.9),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(4),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey
                                              .withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final compact =
                                            constraints.maxHeight < 110;
                                        return Padding(
                                          padding: EdgeInsets.all(
                                            compact ? 12 : 16,
                                          ),
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: Center(
                                                  child: SizedBox(
                                                    width: double.infinity,
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: Text(
                                                        _localizedExamType(
                                                          widget.sinavTuru,
                                                        ),
                                                        textScaler: TextScaler
                                                            .noScaling,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 22,
                                                          fontFamily:
                                                              "MontserratBold",
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: compact ? 4 : 6,
                                              ),
                                              SizedBox(
                                                width: double.infinity,
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    _denemeLabel(index),
                                                    textScaler: TextScaler
                                                        .noScaling,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 16,
                                                      fontFamily:
                                                          "MontserratBold",
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
