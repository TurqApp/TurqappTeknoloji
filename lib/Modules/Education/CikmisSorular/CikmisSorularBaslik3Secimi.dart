import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'CikmisSorularPreview.dart';

class CikmisSorularBaslik3Secimi extends StatefulWidget {
  final String anaBaslik;
  final String sinavTuru;
  final String yil;
  final String baslik2;

  CikmisSorularBaslik3Secimi({
    super.key,
    required this.anaBaslik,
    required this.sinavTuru,
    required this.yil,
    required this.baslik2,
  });

  @override
  State<CikmisSorularBaslik3Secimi> createState() =>
      _CikmisSorularBaslik3SecimiState();
}

class _CikmisSorularBaslik3SecimiState
    extends State<CikmisSorularBaslik3Secimi> {
  List<String> basliklar = [];

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection("CikmisSorular")
        .where("anaBaslik", isEqualTo: widget.anaBaslik)
        .where("sinavTuru", isEqualTo: widget.sinavTuru)
        .where("yil", isEqualTo: widget.yil)
        .get()
        .then((QuerySnapshot snapshot) {
      for (var doc in snapshot.docs) {
        String baslik2 = doc.get("baslik2");
        String baslik3 = doc.get("baslik3");

        if (!basliklar.contains(baslik3) && widget.baslik2 == baslik2) {
          if (mounted) {
            setState(() {
              basliklar.add(baslik3);
            });
          }
        }
      }
      // Veri tamamen yüklendikten sonra sıralama
      if (mounted) {
        setState(() {
          basliklar.sort(); // A -> Z sıralaması
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
            Container(
              height: 70,
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(15),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back, color: Colors.black),
                      SizedBox(width: 12),
                      Text(
                        "${widget.yil} Yılı Oturumlar",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 25,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView(
                  children: [
                    SizedBox(height: 20),
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
                        itemCount: basliklar.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CikmisSorularPreview(
                                    anaBaslik: widget.anaBaslik,
                                    sinavTuru: widget.sinavTuru,
                                    yil: widget.yil,
                                    baslik2: widget.baslik2,
                                    baslik3: basliklar[index],
                                  ),
                                ),
                              );
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
                                        Colors.black45,
                                        Colors.black.withOpacity(
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
                                        color: Colors.grey.withOpacity(
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
                                            Expanded(
                                              child: Text(
                                                basliklar[index],
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
