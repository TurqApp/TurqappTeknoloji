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
  final CikmisSorularRepository _repository = CikmisSorularRepository.ensure();
  List<String> sinavTurleri = [];

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
      case 'Orta Öğretim':
        return 'past_questions.exam_type.middle_school'.tr;
      default:
        return raw;
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
        if (sinavTuru != "İngilizce") {
          normalized.add(sinavTuru);
        } else {
          normalized.insert(0, sinavTuru);
        }
      }

      // Eğer widget.anaBaslik YKS ise, özel sıralama yap
      if (widget.anaBaslik == "YKS") {
        normalized.sort((a, b) {
          // Özel sıralama için TYT, AYT, YDT sırasını kullan
          List<String> tytAytdytOrder = ["TYT", "AYT", "YDT"];
          return tytAytdytOrder.indexOf(a).compareTo(tytAytdytOrder.indexOf(b));
        });
      } else if (widget.anaBaslik == "KPSS") {
        // KPSS için özel sıralama: Lisans, Ön Lisans, Orta Öğretim
        normalized.sort((a, b) {
          List<String> kpssOrder = ["Lisans", "Ön Lisans", "Orta Öğretim"];
          return kpssOrder.indexOf(a).compareTo(kpssOrder.indexOf(b));
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
                              if (sinavTurleri[index] == "TYT" ||
                                  sinavTurleri[index] == "AYT" ||
                                  (sinavTurleri[index] == "İngilizce" ||
                                      sinavTurleri[index] == "Almanca" ||
                                      sinavTurleri[index] == "Arapça" ||
                                      sinavTurleri[index] == "Fransızca" ||
                                      sinavTurleri[index] == "Rusça") ||
                                  sinavTurleri[index] == "Ön Lisans") {
                                // diger dilleri eklemeyi unutma yds
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
                              } else if (sinavTurleri[index] == "KTBT" ||
                                  sinavTurleri[index] == "TTBT" ||
                                  sinavTurleri[index] == "ALES") {
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
                              } else if (sinavTurleri[index] ==
                                  "Orta Öğretim") {
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
                              } else if (sinavTurleri[index] == "YDT") {
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
                              else if (sinavTurleri[index] == "Lisans") {
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
