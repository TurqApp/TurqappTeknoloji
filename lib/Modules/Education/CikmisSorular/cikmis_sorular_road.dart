import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/cikmis_sorular_repository.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_alt_dal_sectirme.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_dil_sectirme_y_d_t.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_yil_sectirme.dart';

class CikmisSorularRoad extends StatefulWidget {
  final String anaBaslik;

  const CikmisSorularRoad({super.key, required this.anaBaslik});
  @override
  State<CikmisSorularRoad> createState() => _CikmisSorularRoadState();
}

class _CikmisSorularRoadState extends State<CikmisSorularRoad> {
  final CikmisSorularRepository _repository = ensureCikmisSorularRepository();
  List<String> sinavTurleri = [];
  static const _english = 'İngilizce';
  static const _german = 'Almanca';
  static const _arabic = 'Arapça';
  static const _french = 'Fransızca';
  static const _russian = 'Rusça';
  static const _associate = 'Ön Lisans';
  static const _undergraduate = 'Lisans';
  static const _legacyMiddleSchool = 'Orta Öğretim';
  static const _middleSchool = 'Ortaöğretim';
  static const _tyt = 'TYT';
  static const _ayt = 'AYT';
  static const _ydt = 'YDT';
  static const _ktbt = 'KTBT';
  static const _ttbt = 'TTBT';
  static const _ales = 'ALES';
  static const _yks = 'YKS';
  static const _kpss = 'KPSS';

  String _localizedExamType(String raw) {
    switch (_normalizedExamType(raw)) {
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
      case _middleSchool:
        return 'past_questions.exam_type.middle_school'.tr;
      default:
        return raw;
    }
  }

  String _normalizedExamType(String raw) {
    if (raw == _legacyMiddleSchool) return _middleSchool;
    return raw;
  }

  bool _isLanguageExam(String raw) {
    switch (_normalizedExamType(raw)) {
      case _english:
      case _german:
      case _arabic:
      case _french:
      case _russian:
        return true;
      default:
        return false;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _repository
        .distinctValues(
      where: (doc) => (doc['anaBaslik'] ?? '').toString() == widget.anaBaslik,
      field: 'sinavTuru',
    )
        .then((sinavTurleriList) {
      final normalized = <String>[];
      for (final sinavTuru in sinavTurleriList) {
        if (normalized.contains(sinavTuru)) continue;
        if (_normalizedExamType(sinavTuru) != _english) {
          normalized.add(sinavTuru);
        } else {
          normalized.insert(0, sinavTuru);
        }
      }

      // Eğer widget.anaBaslik YKS ise, özel sıralama yap
      if (widget.anaBaslik == _yks) {
        normalized.sort((a, b) {
          const tytAytdytOrder = [_tyt, _ayt, _ydt];
          return tytAytdytOrder
              .indexOf(_normalizedExamType(a))
              .compareTo(tytAytdytOrder.indexOf(_normalizedExamType(b)));
        });
      } else if (widget.anaBaslik == _kpss) {
        normalized.sort((a, b) {
          const kpssOrder = [_undergraduate, _associate, _middleSchool];
          return kpssOrder
              .indexOf(_normalizedExamType(a))
              .compareTo(kpssOrder.indexOf(_normalizedExamType(b)));
        });
      } else {}

      // Listeyi UI'ye yansıtmak için setState kullan
      if (mounted) {
        setState(() {
          sinavTurleri = normalized;
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
            BackButtons(text: widget.anaBaslik),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics:
                            NeverScrollableScrollPhysics(), // İç GridView'da kaydırma devre dışı
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // Yan yana 2 eleman
                          crossAxisSpacing: 10.0, // Yatay boşluk
                          mainAxisSpacing: 10.0, // Dikey boşluk
                          childAspectRatio: 3 / 4, // En-boy oranı 3:4
                        ),
                        itemCount: sinavTurleri.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              final selectedExamType =
                                  _normalizedExamType(sinavTurleri[index]);
                              if (selectedExamType == _tyt ||
                                  selectedExamType == _ayt ||
                                  _isLanguageExam(selectedExamType) ||
                                  selectedExamType == _associate) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CikmisSorularYilSectirme(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: sinavTurleri[index],
                                      baslik2: sinavTurleri[index],
                                      baslik3: sinavTurleri[index],
                                    ),
                                  ),
                                );
                              } else if (selectedExamType == _ktbt ||
                                  selectedExamType == _ttbt ||
                                  selectedExamType == _ales) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CikmisSorularYilSectirme(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: sinavTurleri[index],
                                      baslik2: sinavTurleri[index],
                                      baslik3: sinavTurleri[index],
                                    ),
                                  ),
                                );
                              } else if (selectedExamType == _middleSchool) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CikmisSorularYilSectirme(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: sinavTurleri[index],
                                      baslik2: sinavTurleri[index],
                                      baslik3: sinavTurleri[index],
                                    ),
                                  ),
                                );
                              } else if (selectedExamType == _ydt) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CikmisSorularDilSectirmeYDT(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: sinavTurleri[index],
                                    ),
                                  ),
                                );
                              }
                              // else if (sinavTurleri[index] == "DGS" || sinavTurleri[index] == "LGS" || sinavTurleri[index] == "ALES"){
                              //   ///DIREKT YONLENDIRME //Navigator.push(context, MaterialPageRoute(builder: (context) => CikmisSorularYilSectirme(anaBaslik: widget.anaBaslik, sinavTuru: sinavTurleri[index])));
                              // }
                              else if (selectedExamType == _undergraduate) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CikmisSorularAltDalSectirme(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: sinavTurleri[index],
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Stack(
                              children: [
                                Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.black, // Başlangıç rengi,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(4),
                                    ),
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.indigo,
                                        Colors.black.withValues(
                                          alpha: 0.9,
                                        ), // Alt renk
                                      ],
                                      begin: Alignment
                                          .topCenter, // Gradyan başlangıç noktası (yukarı)
                                      end: Alignment
                                          .bottomCenter, // Gradyan bitiş noktası (aşağı)
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(4),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withValues(
                                          alpha: 0.3,
                                        ), // Gölge rengi ve opaklık
                                        blurRadius: 6, // Gölge bulanıklık
                                        offset: Offset(
                                          0,
                                          0,
                                        ), // Gölgenin konumu (x,y)
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _localizedExamType(
                                                  sinavTurleri[index],
                                                ),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 30,
                                                  fontFamily: "MontserratBold",
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Spacer(),
                                        SizedBox(height: 4),
                                        Text(
                                          widget.anaBaslik,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 20,
                                            fontFamily: "MontserratBold",
                                          ),
                                        ),
                                      ],
                                    ),
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
