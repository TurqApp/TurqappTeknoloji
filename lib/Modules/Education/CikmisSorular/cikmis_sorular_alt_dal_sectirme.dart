import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_yil_sectirme.dart';
import 'cikmis_sorular_brans_sectirme.dart';

class CikmisSorularAltDalSectirme extends StatefulWidget {
  final String anaBaslik;
  final String sinavTuru;

  const CikmisSorularAltDalSectirme({
    super.key,
    required this.anaBaslik,
    required this.sinavTuru,
  });
  @override
  State<CikmisSorularAltDalSectirme> createState() =>
      _CikmisSorularAltDalSectirmeState();
}

class _CikmisSorularAltDalSectirmeState
    extends State<CikmisSorularAltDalSectirme> {
  List<String> dallar = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    FirebaseFirestore.instance
        .collection("questions")
        .where("anaBaslik", isEqualTo: widget.anaBaslik)
        .where("sinavTuru", isEqualTo: widget.sinavTuru)
        .get()
        .then((QuerySnapshot snapshot) {
      List<String> dallarList = [];

      for (var doc in snapshot.docs) {
        String baslik2 = doc.get("baslik2");

        if (!dallarList.contains(baslik2)) {
          dallarList.add(baslik2);
        }
      }

      // Özel sıralama: GK - GY, A Grubu, Eğitim Bilimleri, Alan Bilgisi
      List<String> baslik2Order = [
        "GK - GY",
        "A Grubu",
        "Eğitim Bilimleri",
        "Alan Bilgisi",
      ];

      // Sıralama işlemi
      dallarList.sort((a, b) {
        int indexA = baslik2Order.indexOf(a);
        int indexB = baslik2Order.indexOf(b);

        // Eğer baslik2 sıralama listesinde yoksa, sona eklenir
        if (indexA == -1) indexA = baslik2Order.length;
        if (indexB == -1) indexB = baslik2Order.length;

        return indexA.compareTo(indexB);
      });

      // Listeyi UI'ye yansıtmak için setState kullan
      if (mounted) {
        setState(() {
          dallar = dallarList;
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
            BackButtons(text: "Sınav Seç"),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                          childAspectRatio: 3 / 4,
                        ),
                        itemCount: dallar.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              if (dallar[index] == "Alan Bilgisi") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CikmisSorularBransSectirme(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: widget.sinavTuru,
                                      baslik2: dallar[index],
                                      baslik3: widget.sinavTuru,
                                    ),
                                  ),
                                );
                              } else if (dallar[index] == "Eğitim Bilimleri") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CikmisSorularYilSectirme(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: widget.sinavTuru,
                                      baslik2: dallar[index],
                                      baslik3: widget.sinavTuru,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CikmisSorularYilSectirme(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: widget.sinavTuru,
                                      baslik2: dallar[index],
                                      baslik3: "",
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
                                        Colors.deepOrange,
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
                                                dallar[index] == "Alan Bilgisi"
                                                    ? "ÖABT"
                                                    : dallar[index],
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 35,
                                                  fontFamily: "MontserratBold",
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Spacer(),
                                        SizedBox(height: 4),
                                        Text(
                                          widget.sinavTuru,
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
