import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
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
  List<String> yillar = [];
  @override
  void initState() {
    super.initState();
    print("DEVELOPER ${widget.anaBaslik}");
    print("DEVELOPER ${widget.baslik2}");
    print("DEVELOPER ${widget.baslik3}");

    getData();
  }

  void getData() {
    if (widget.baslik2 == "TTBT" ||
        widget.baslik2 == "KTBT" ||
        widget.baslik2 == "ALES" ||
        widget.baslik2 == "Almanca" ||
        widget.baslik2 == "İngilizce" ||
        widget.baslik2 == "Fransızca" ||
        widget.baslik2 == "Rusça" ||
        widget.baslik2 == "Arapça") {
      print("DEVELOPER 3");
      FirebaseFirestore.instance
          .collection("CikmisSorular")
          .where("anaBaslik", isEqualTo: widget.anaBaslik)
          .where("sinavTuru", isEqualTo: widget.sinavTuru)
          .get()
          .then((QuerySnapshot snapshot) {
        for (var doc in snapshot.docs) {
          String yil = doc.get("yil");
          String baslik3 = doc.get("baslik3");

          if (!yillar.contains(yil)) {
            print("DEVELOPER $baslik3");
            if (mounted) {
              setState(() {
                yillar.add(yil);
                yillar.sort((a, b) => int.parse(b).compareTo(int.parse(a)));
              });
            }
          }
        }
      });
    } else if (widget.baslik3 != "") {
      print("DEVELOPER 1");
      FirebaseFirestore.instance
          .collection("CikmisSorular")
          .where("anaBaslik", isEqualTo: widget.anaBaslik)
          .where("sinavTuru", isEqualTo: widget.sinavTuru)
          .get()
          .then((QuerySnapshot snapshot) {
        for (var doc in snapshot.docs) {
          String yil = doc.get("yil");
          String baslik3 = doc.get("baslik3");
          String baslik2 = doc.get("baslik2");

          if (!yillar.contains(yil) &&
              baslik3 == widget.baslik3 &&
              baslik2 == widget.baslik2) {
            print("DEVELOPER $baslik3");
            if (mounted) {
              setState(() {
                yillar.add(yil);
                yillar.sort((a, b) => int.parse(b).compareTo(int.parse(a)));
              });
            }
          }
        }
      });
    } else if (widget.baslik2 != "") {
      print("DEVELOPER 2");
      FirebaseFirestore.instance
          .collection("CikmisSorular")
          .where("anaBaslik", isEqualTo: widget.anaBaslik)
          .where("sinavTuru", isEqualTo: widget.sinavTuru)
          .get()
          .then((QuerySnapshot snapshot) {
        for (var doc in snapshot.docs) {
          String yil = doc.get("yil");
          String baslik2 = doc.get("baslik2");

          if (!yillar.contains(yil) && baslik2 == widget.baslik2) {
            if (mounted) {
              setState(() {
                yillar.add(yil);
                yillar.sort((a, b) => int.parse(b).compareTo(int.parse(a)));
              });
            }
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "${widget.sinavTuru} Yılları"),
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
                          crossAxisCount: 4,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 1,
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
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.cyan,
                                            Colors.black.withValues(alpha: 0.9),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withValues(alpha: 0.3),
                                            blurRadius: 6,
                                            offset: Offset(0, 0),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        yillar[index],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 25,
                                          fontFamily: "MontserratBold",
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
