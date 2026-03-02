import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_baslik3_secimi.dart';

import 'cikmis_sorular_preview.dart';

class CikmisSorularBaslik2Secimi extends StatefulWidget {
  final String anaBaslik;
  final String sinavTuru;
  final String yil;

  const CikmisSorularBaslik2Secimi({
    super.key,
    required this.anaBaslik,
    required this.sinavTuru,
    required this.yil,
  });

  @override
  State<CikmisSorularBaslik2Secimi> createState() =>
      _CikmisSorularBaslik2SecimiState();
}

class _CikmisSorularBaslik2SecimiState
    extends State<CikmisSorularBaslik2Secimi> {
  List<String> basliklar = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    FirebaseFirestore.instance
        .collection("questions")
        .where("anaBaslik", isEqualTo: widget.anaBaslik)
        .where("sinavTuru", isEqualTo: widget.sinavTuru)
        .where("yil", isEqualTo: widget.yil)
        .get()
        .then((QuerySnapshot snapshot) {
      List<String> basliklarList = [];

      // Başlıkları topla
      for (var doc in snapshot.docs) {
        String baslik2 = doc.get("baslik2");

        // Eğer baslik2 daha önce eklenmediyse
        if (!basliklarList.contains(baslik2)) {
          basliklarList.add(baslik2);
        }
      }

      // Başlıkları A-Z'ye göre sıralama
      basliklarList.sort();

      // Eğer listeyi UI'ye eklemen gerekiyorsa
      if (mounted) {
        setState(() {
          basliklar = basliklarList;
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
              text: "${widget.sinavTuru} ${widget.yil} Testleri",
            ),
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
                        itemCount: basliklar.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              if (widget.sinavTuru == "Lisans") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CikmisSorularBaslik3Secimi(
                                      anaBaslik: widget.anaBaslik,
                                      sinavTuru: widget.sinavTuru,
                                      yil: widget.yil,
                                      baslik2: basliklar[index],
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
                                      yil: widget.yil,
                                      baslik2: basliklar[index],
                                      baslik3: widget.sinavTuru,
                                    ),
                                  ),
                                );
                              }
                              //sinava git
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
                                        Colors.teal,
                                        Colors.black.withValues(alpha: 
                                          0.9,
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
                                        color: Colors.grey.withValues(alpha: 
                                          0.3,
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
                                            Text(
                                              basliklar[index],
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 35,
                                                fontFamily: "MontserratBold",
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
