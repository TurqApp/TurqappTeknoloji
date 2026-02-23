import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/Slider/education_slider.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_soru_sonuclar.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_cover_model.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_grid.dart';
import 'package:turqappv2/Modules/TypeWriter/type_writer.dart';
import 'package:turqappv2/Themes/app_assets.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class CikmisSorular extends StatefulWidget {
  const CikmisSorular({super.key});

  @override
  State<CikmisSorular> createState() => _CikmisSorularState();
}

class _CikmisSorularState extends State<CikmisSorular> {
  bool showButons = false;
  List<CikmisSorularCoverModel> list = [];
  @override
  void initState() {
    super.initState();
    getData();
    scrolControlcu();
  }

  void getData() {
    List<String> baslikSirasi = [
      "LGS",
      "YKS",
      "KPSS",
      "ALES",
      "YDS",
      "DGS",
      "TUS",
      "DUS",
    ];

    FirebaseFirestore.instance
        .collection("CikmisSorular")
        .orderBy("sira", descending: false)
        .get()
        .then((QuerySnapshot snapshot) {
      List<CikmisSorularCoverModel> tempList = [];

      for (var doc in snapshot.docs) {
        String anaBaslik = doc.get("anaBaslik");
        String sinavTuru = doc.get("sinavTuru");

        if (!tempList.any((baslik) => baslik.anaBaslik == anaBaslik) &&
            mounted) {
          tempList.add(
            CikmisSorularCoverModel(
              anaBaslik: anaBaslik,
              docID: doc.id,
              sinavTuru: sinavTuru,
            ),
          );
        }
      }

      // Sıralama işlemi
      tempList.sort((a, b) {
        int indexA = baslikSirasi.indexOf(a.anaBaslik);
        int indexB = baslikSirasi.indexOf(b.anaBaslik);

        if (indexA == -1) indexA = baslikSirasi.length;
        if (indexB == -1) indexB = baslikSirasi.length;

        return indexA.compareTo(indexB);
      });

      if (mounted) {
        setState(() {
          list = tempList;
        });
      }
    });
  }

  double _previousOffset = 0.0;

  final ScrollController _scrollController = ScrollController();

  void scrolControlcu() {
    _scrollController.addListener(() {
      double currentOffset = _scrollController.position.pixels;

      if (currentOffset > _previousOffset) {
        if (mounted && showButons) {
          setState(() {
            showButons = false;
          });
        }
      } else if (currentOffset < _previousOffset) {
        if (mounted && showButons) {
          setState(() {
            showButons = false;
          });
        }
      }

      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {}

      _previousOffset = currentOffset;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = [
      Colors.deepPurple,
      Colors.indigo,
      Colors.teal,
      Colors.deepOrange,
      Colors.pink,
      Colors.cyan.shade700,
      Colors.blueGrey,
      Colors.pink.shade900,
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Get.back();
                      },
                      icon: Icon(
                        AppIcons.arrowLeft,
                        color: Colors.black,
                        size: 25,
                      ),
                    ),
                    TypewriterText(
                      text: "Çıkmış Sorular",
                    ),
                  ],
                ),
                Expanded(
                  child: showButons || list.isEmpty
                      ? Center(child: CupertinoActivityIndicator())
                      : Container(
                          color: Colors.white,
                          child: ListView(
                            controller: _scrollController,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  EducationSlider(
                                    imageList: [
                                      AppAssets.previous1,
                                      AppAssets.practice2,
                                      AppAssets.previous3,
                                      AppAssets.previous4,
                                    ],
                                  ),
                                  15.ph,
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: GridView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 10.0,
                                        mainAxisSpacing: 10.0,
                                        childAspectRatio: 3 / 4,
                                      ),
                                      itemCount: list.length,
                                      itemBuilder: (context, index) {
                                        final color =
                                            colors[index % colors.length];
                                        return CikmisSorularGrid(
                                          anaBaslik: list[index].anaBaslik,
                                          color: color,
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 30),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: ActionButton(
        context: context,
        menuItems: [
          PullDownMenuItem(
            icon: Icons.history,
            title: 'Sonuçlarım',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CikmisSoruSonuclar()),
              );
            },
          ),
        ],
      ),
    );
  }
}
