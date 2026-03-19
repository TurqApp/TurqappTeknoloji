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

  String _denemeLabel(int index) =>
      'past_questions.mock_label'.trParams({'index': '${index + 1}'});

  String _localizedExamType(String raw) {
    switch (raw) {
      case 'İngilizce':
        return 'tests.language.english'.tr;
      case 'Almanca':
        return 'tests.language.german'.tr;
      case 'Arapça':
        return 'tests.language.arabic'.tr;
      case 'Fransızca':
        return 'tests.language.french'.tr;
      case 'Rusça':
        return 'tests.language.russian'.tr;
      case 'Ön Lisans':
        return 'past_questions.exam_type.associate'.tr;
      case 'Lisans':
        return 'past_questions.exam_type.undergraduate'.tr;
      case 'GK - GY':
        return 'past_questions.branch.general_ability_culture'.tr;
      case 'A Grubu':
        return 'past_questions.branch.group_a'.tr;
      case 'Eğitim Bilimleri':
        return 'past_questions.branch.education_sciences'.tr;
      case 'Alan Bilgisi':
        return 'past_questions.branch.field_knowledge'.tr;
      default:
        return raw;
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
            if (widget.baslik2 == "TTBT" ||
                widget.baslik2 == "KTBT" ||
                widget.baslik2 == "ALES" ||
                widget.baslik2 == "Almanca" ||
                widget.baslik2 == "İngilizce" ||
                widget.baslik2 == "Fransızca" ||
                widget.baslik2 == "Rusça" ||
                widget.baslik2 == "Arapça") {
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
                              if (widget.sinavTuru == "KTBT" ||
                                  widget.sinavTuru == "TTBT" ||
                                  widget.sinavTuru == "İngilizce" ||
                                  widget.sinavTuru == "Fransızca" ||
                                  widget.sinavTuru == "Arapça" ||
                                  widget.sinavTuru == "Almanca" ||
                                  widget.sinavTuru == "Rusça" ||
                                  widget.sinavTuru == "ALES") {
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
                              } else if (widget.sinavTuru == "Lisans" &&
                                  widget.baslik2 == "A Grubu") {
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
                              } else if (widget.sinavTuru == "Lisans" &&
                                  widget.baslik2 == "Alan Bilgisi") {
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
                              } else if (widget.sinavTuru == "Lisans" &&
                                  widget.baslik2 == "Eğitim Bilimleri") {
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
                              } else if (widget.sinavTuru == "Lisans" &&
                                  widget.baslik2 == "GK - GY") {
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
                              } else if (widget.anaBaslik == "YKS" &&
                                  widget.sinavTuru == "YDT") {
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
                              } else if (widget.anaBaslik == "YKS" &&
                                  widget.sinavTuru == "TYT") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CikmisSorularPreview(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: widget.sinavTuru,
                                      yil: yillar[index],
                                      baslik2: "TYT",
                                      baslik3: "TYT",
                                    ),
                                  ),
                                );
                              } else if (widget.anaBaslik == "YKS" &&
                                  widget.sinavTuru == "AYT") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CikmisSorularPreview(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: widget.sinavTuru,
                                      yil: yillar[index],
                                      baslik2: "AYT",
                                      baslik3: "AYT",
                                    ),
                                  ),
                                );
                              } else if (widget.anaBaslik == "DGS" &&
                                  widget.sinavTuru == "DGS") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CikmisSorularPreview(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: widget.sinavTuru,
                                      yil: yillar[index],
                                      baslik2: "DGS",
                                      baslik3: "DGS",
                                    ),
                                  ),
                                );
                              } else if (widget.anaBaslik == "LGS" &&
                                  widget.sinavTuru == "LGS") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CikmisSorularPreview(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: widget.sinavTuru,
                                      yil: yillar[index],
                                      baslik2: "LGS",
                                      baslik3: "LGS",
                                    ),
                                  ),
                                );
                              } else if (widget.anaBaslik == "KPSS" &&
                                  widget.sinavTuru == "Ön Lisans") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CikmisSorularPreview(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: widget.sinavTuru,
                                      yil: yillar[index],
                                      baslik2: "Ön Lisans",
                                      baslik3: "Ön Lisans",
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
