import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/external.dart';

class CikmisSoruOlustur extends StatefulWidget {
  const CikmisSoruOlustur({super.key});

  @override
  State<CikmisSoruOlustur> createState() => _CikmisSoruOlusturState();
}

class _CikmisSoruOlusturState extends State<CikmisSoruOlustur> {
  static const _sinavTuruLgs = 'LGS';
  static const _sinavTuruTyt = 'TYT';
  static const _sinavTuruAyt = 'AYT';
  static const _sinavTuruKpss = 'KPSS';
  static const _sinavTuruAles = 'ALES';
  static const _sinavTuruDgs = 'DGS';
  static const _sinavTuruYds = 'YDS';
  static const _kpssLisansOrtaogretim = 'Ortaöğretim';
  static const _kpssLisansOnLisans = 'Ön Lisans';
  static const _kpssLisansLisans = 'Lisans';
  static const _kpssLisansEgitimBirimleri = 'Eğitim Birimleri';
  static const _kpssLisansAGrubu1 = 'A Grubu 1';
  static const _kpssLisansAGrubu2 = 'A Grubu 2';

  List<String> dersler = [];
  String sinavTuru = _sinavTuruLgs;
  String kpssSecilenLisans = _kpssLisansOrtaogretim;
  List<TextEditingController> soruSayisiTextFields = [];

  bool _isKpssCommonLevel(String value) =>
      value == _kpssLisansOrtaogretim ||
      value == _kpssLisansOnLisans ||
      value == _kpssLisansLisans;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    soruSayisiTextFields = List.generate(
      lgsDersler.length,
      (index) => TextEditingController(text: "40"),
    );
    dersler = lgsDersler;
  }

  @override
  void dispose() {
    // Tüm controller'ları temizle
    for (var controller in soruSayisiTextFields) {
      controller.dispose();
    }
    super.dispose();
  }

  void disposeTextEditingControllers() {
    for (var controller in soruSayisiTextFields) {
      controller.dispose();
    }
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
                        "education.past_exam_create_title".tr,
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
                    sinavTurleri(context),
                    SizedBox(height: 20),
                    Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.indigo),
                      child: Text(
                        "education.start_creating".tr,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
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

  Widget sinavTurleri(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "education.exam_types".tr,
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: "MontserratBold",
            ),
          ),
        ),
        SizedBox(height: 20),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sinavTurleriList.length,
            itemBuilder: (context, index) {
              // Statik renk listesi
              List<Color> renkler = [
                Colors.black,
                Colors.green[500]!,
                Colors.purple[500]!,
                Colors.red[500]!,
                Colors.orange[500]!,
                Colors.teal[500]!,
              ];

              return GestureDetector(
                onTap: () {
                  if (mounted) {
                    setState(() {
                      disposeTextEditingControllers();

                      sinavTuru = sinavTurleriList[index];

                      if (sinavTuru == _sinavTuruLgs) {
                        dersler = lgsDersler;
                      } else if (sinavTuru == _sinavTuruTyt) {
                        dersler = tytDersler;
                      } else if (sinavTuru == _sinavTuruAyt) {
                        dersler = aytDersler;
                      } else if (sinavTuru == _sinavTuruKpss) {
                        kpssSecilenLisans = _kpssLisansOrtaogretim;
                        dersler = kpssDerslerOrtaVeOnLisans;
                      } else if (sinavTuru == _sinavTuruAles ||
                          sinavTuru == _sinavTuruDgs) {
                        dersler = alesVeDgsDersler;
                      } else {
                        dersler = ydsDersler;
                      }

                      soruSayisiTextFields = List.generate(
                        dersler.length,
                        (index) => TextEditingController(),
                      );
                    });
                  }
                },
                child: Padding(
                  padding: EdgeInsets.only(
                    right: 12,
                    left: index == 0 ? 20 : 0,
                  ),
                  child: Container(
                    height: 60,
                    width: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sinavTuru == sinavTurleriList[index]
                          ? renkler[index % renkler.length]
                          : Colors.grey.withValues(
                              alpha: 0.1,
                            ), // Statik renk seçimi
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                    ),
                    child: Text(
                      sinavTurleriList[index],
                      style: TextStyle(
                        color: sinavTuru == sinavTurleriList[index]
                            ? Colors.white
                            : Colors.black, // Her zaman beyaz
                        fontSize: 15,
                        fontFamily: sinavTuru == sinavTurleriList[index]
                            ? "MontserratBold"
                            : "MontserratMedium",
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (sinavTuru == _sinavTuruKpss)
          Column(
            children: [
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: kpssOgretimTipleri.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: GestureDetector(
                          onTap: () {
                            if (mounted) {
                              setState(() {
                                kpssSecilenLisans = kpssOgretimTipleri[index];

                                disposeTextEditingControllers();

                                if (_isKpssCommonLevel(kpssSecilenLisans)) {
                                  dersler = kpssDerslerOrtaVeOnLisans;
                                } else if (kpssSecilenLisans ==
                                    _kpssLisansEgitimBirimleri) {
                                  dersler = kpssDerslerEgitimbirimleri;
                                } else if (kpssSecilenLisans ==
                                    _kpssLisansAGrubu1) {
                                  dersler = kpssDerslerAgrubu1;
                                } else if (kpssSecilenLisans ==
                                    _kpssLisansAGrubu2) {
                                  dersler = kpssDerslerAgrubu2;
                                }

                                soruSayisiTextFields = List.generate(
                                  dersler.length,
                                  (index) => TextEditingController(text: "1"),
                                );
                              });
                            }
                          },
                          child: Container(
                            height: 45,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  kpssSecilenLisans == kpssOgretimTipleri[index]
                                      ? Colors.indigo
                                      : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.all(
                                Radius.circular(50),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                              ),
                              child: Text(
                                kpssOgretimTipleri[index],
                                style: TextStyle(
                                  color: kpssSecilenLisans ==
                                          kpssOgretimTipleri[index]
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        SizedBox(height: 20),
        if (sinavTuru == _sinavTuruLgs)
          Column(
            children: [
              SizedBox(height: 10),
              for (int i = 0; i < lgsDersler.length; i++)
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lgsDersler[i],
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                        SizedBox(
                          width: 100, // TextField genişliği
                          child: TextField(
                            controller: soruSayisiTextFields[i],
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              hintText: "education.question_count_hint".tr,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium",
                              ),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                              height: 1.8,
                            ),
                            onChanged: (val) {
                              if (mounted) {
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        if (sinavTuru == _sinavTuruTyt)
          Column(
            children: [
              SizedBox(height: 10),
              for (int i = 0; i < tytDersler.length; i++)
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tytDersler[i],
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                        SizedBox(
                          width: 100, // TextField genişliği
                          child: TextField(
                            controller: soruSayisiTextFields[i],
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              hintText: "education.question_count_hint".tr,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium",
                              ),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                              height: 1.8,
                            ),
                            onChanged: (val) {
                              if (mounted) {
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        if (sinavTuru == _sinavTuruAyt)
          Column(
            children: [
              SizedBox(height: 10),
              for (int i = 0; i < aytDersler.length; i++)
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          aytDersler[i],
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                        SizedBox(
                          width: 100, // TextField genişliği
                          child: TextField(
                            controller: soruSayisiTextFields[i],
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              hintText: "education.question_count_hint".tr,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium",
                              ),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                              height: 1.8,
                            ),
                            onChanged: (val) {
                              if (mounted) {
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        if (sinavTuru == _sinavTuruKpss && _isKpssCommonLevel(kpssSecilenLisans))
          Column(
            children: [
              SizedBox(height: 10),
              for (int i = 0; i < kpssDerslerOrtaVeOnLisans.length; i++)
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          kpssDerslerOrtaVeOnLisans[i],
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                        SizedBox(
                          width: 100, // TextField genişliği
                          child: TextField(
                            controller: soruSayisiTextFields[i],
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              hintText: "education.question_count_hint".tr,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium",
                              ),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                              height: 1.8,
                            ),
                            onChanged: (val) {
                              if (mounted) {
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        if (sinavTuru == _sinavTuruKpss &&
            kpssSecilenLisans == _kpssLisansEgitimBirimleri)
          Column(
            children: [
              SizedBox(height: 10),
              for (int i = 0; i < kpssDerslerEgitimbirimleri.length; i++)
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          kpssDerslerEgitimbirimleri[i],
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                        SizedBox(
                          width: 100, // TextField genişliği
                          child: TextField(
                            controller: soruSayisiTextFields[i],
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              hintText: "education.question_count_hint".tr,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium",
                              ),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                              height: 1.8,
                            ),
                            onChanged: (val) {
                              if (mounted) {
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        if (sinavTuru == _sinavTuruKpss &&
            kpssSecilenLisans == _kpssLisansAGrubu1)
          Column(
            children: [
              SizedBox(height: 10),
              for (int i = 0; i < kpssDerslerAgrubu1.length; i++)
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          kpssDerslerAgrubu1[i],
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                        SizedBox(
                          width: 100, // TextField genişliği
                          child: TextField(
                            controller: soruSayisiTextFields[i],
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              hintText: "education.question_count_hint".tr,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium",
                              ),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                              height: 1.8,
                            ),
                            onChanged: (val) {
                              if (mounted) {
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        if (sinavTuru == _sinavTuruKpss &&
            kpssSecilenLisans == _kpssLisansAGrubu2)
          Column(
            children: [
              SizedBox(height: 10),
              for (int i = 0; i < kpssDerslerAgrubu2.length; i++)
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          kpssDerslerAgrubu2[i],
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                        SizedBox(
                          width: 100, // TextField genişliği
                          child: TextField(
                            controller: soruSayisiTextFields[i],
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              hintText: "education.question_count_hint".tr,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium",
                              ),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                              height: 1.8,
                            ),
                            onChanged: (val) {
                              if (mounted) {
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        if (sinavTuru == _sinavTuruAles || sinavTuru == _sinavTuruDgs)
          Column(
            children: [
              SizedBox(height: 10),
              for (int i = 0; i < alesVeDgsDersler.length; i++)
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          alesVeDgsDersler[i],
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                        SizedBox(
                          width: 100, // TextField genişliği
                          child: TextField(
                            controller: soruSayisiTextFields[i],
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              hintText: "education.question_count_hint".tr,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium",
                              ),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                              height: 1.8,
                            ),
                            onChanged: (val) {
                              if (mounted) {
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        if (sinavTuru == _sinavTuruYds)
          Column(
            children: [
              SizedBox(height: 10),
              for (int i = 0; i < ydsDersler.length; i++)
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ydsDersler[i],
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                        SizedBox(
                          width: 100, // TextField genişliği
                          child: TextField(
                            controller: soruSayisiTextFields[i],
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              hintText: "education.question_count_hint".tr,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium",
                              ),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                              height: 1.8,
                            ),
                            onChanged: (val) {
                              if (mounted) {
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
