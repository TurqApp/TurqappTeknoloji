import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/external.dart';
import 'cikmis_sorular_yil_sectirme.dart';

class CikmisSorularBransSectirme extends StatefulWidget {
  final String anaBaslik;
  final String sinavTuru;
  final String baslik2;
  final String baslik3;

  const CikmisSorularBransSectirme({
    super.key,
    required this.anaBaslik,
    required this.sinavTuru,
    required this.baslik2,
    required this.baslik3,
  });

  @override
  State<CikmisSorularBransSectirme> createState() =>
      _CikmisSorularBransSectirmeState();
}

class _CikmisSorularBransSectirmeState
    extends State<CikmisSorularBransSectirme> {
  List<Map<String, dynamic>> ogretmenlikler = [
    {"name": "Almanca öğretmenliği", "icon": Icons.language_outlined},
    {
      "name": "Beden eğitim öğretmenliği",
      "icon": Icons.fitness_center_outlined,
    },
    {"name": "Biyoloji öğretmenliği", "icon": Icons.biotech_outlined},
    {"name": "Coğrafya öğretmenliği", "icon": Icons.public_outlined},
    {
      "name": "Din kültürü öğretmenliği",
      "icon": Icons.self_improvement_outlined,
    },
    {"name": "Edebiyat öğretmenliği", "icon": Icons.menu_book_outlined},
    {"name": "Fen bilimleri öğretmenliği", "icon": Icons.science_outlined},
    {"name": "Fizik öğretmenliği", "icon": Icons.speed_outlined},
    {"name": "Kimya öğretmenliği", "icon": Icons.medical_information_outlined},
    {"name": "Lise matematik", "icon": Icons.calculate_outlined},
    {"name": "Okul öncesi", "icon": Icons.child_care_outlined},
    {"name": "Rehberlik", "icon": Icons.psychology_outlined},
    {"name": "Sosyal bilgiler öğretmenliği", "icon": Icons.people_outlined},
    {"name": "Sınıf öğretmenliği", "icon": Icons.chair_alt_outlined},
    {"name": "Tarih öğretmenliği", "icon": Icons.timeline_outlined},
    {"name": "Türkçe öğretmenliği", "icon": Icons.book_outlined},
    {"name": "İlköğretim matematik", "icon": Icons.functions_outlined},
    {"name": "İmam hatip", "icon": Icons.mosque_outlined},
    {"name": "İngilizce öğretmenliği", "icon": Icons.translate_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Öğretmenlikler"),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        physics:
                            NeverScrollableScrollPhysics(), // ListView kaydırmasını korumak için
                        shrinkWrap:
                            true, // GridView'un boyutunu içeriğe göre ayarlamak için
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10.0, // Yatay boşluk
                          mainAxisSpacing: 10.0, // Dikey boşluk
                          childAspectRatio: 1 / 1.2, // En-boy oranı 3:4
                        ),
                        itemCount:
                            ogretmenlikler.length, // Verilerinizin uzunluğu
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CikmisSorularYilSectirme(
                                    anaBaslik: widget.anaBaslik,
                                    sinavTuru: widget.sinavTuru,
                                    baslik2: widget.baslik2,
                                    baslik3: ogretmenlikler[index]['name'],
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.pink,
                                          Colors.black.withValues(alpha: 0.9),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey
                                              .withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      ogretmenlikler[index]['icon'],
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  ogretmenlikler[index]["name"] ==
                                          "İlköğretim matematik"
                                      ? "İ. Matematik"
                                      : ogretmenlikler[index]["name"] ==
                                              "Lise matematik"
                                          ? "L. Matematik"
                                          : capitalizeEachWord(
                                              ogretmenlikler[index]['name']
                                                  .replaceAll(
                                                      "öğretmenliği", ""),
                                            ),
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontFamily: "MontserratMedium",
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
