import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_road.dart';

import 'cikmis_sorular_yil_sectirme.dart';

class CikmisSorularGrid extends StatefulWidget {
  final String anaBaslik;
  final Color color;

  const CikmisSorularGrid(
      {super.key, required this.anaBaslik, required this.color});
  @override
  State<CikmisSorularGrid> createState() => _CikmisSorularGridState();
}

class _CikmisSorularGridState extends State<CikmisSorularGrid> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.anaBaslik == "YKS" ||
            widget.anaBaslik == "TUS" ||
            widget.anaBaslik == "YDS" ||
            widget.anaBaslik == "KPSS") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CikmisSorularRoad(anaBaslik: widget.anaBaslik),
            ),
          );
        } else if (widget.anaBaslik == "DGS" ||
            widget.anaBaslik == "LGS" ||
            widget.anaBaslik == "DUS") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CikmisSorularYilSectirme(
                anaBaslik: widget.anaBaslik,
                sinavTuru: widget.anaBaslik,
                baslik2: widget.anaBaslik,
                baslik3: widget.anaBaslik,
              ),
            ),
          );
        } else if (widget.anaBaslik == "ALES") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CikmisSorularYilSectirme(
                anaBaslik: widget.anaBaslik,
                sinavTuru: widget.anaBaslik,
                baslik2: "ALES",
                baslik3: "ALES",
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
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
          Container(
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.color, Colors.black.withValues(alpha: 0.9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 210;
                final titleSize = compact ? 32.0 : 35.0;
                final subtitleSize = compact ? 18.0 : 20.0;
                return Padding(
                  padding: EdgeInsets.all(compact ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.anaBaslik,
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: titleSize,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'education.previous_questions'.tr,
                            textScaler: TextScaler.noScaling,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: subtitleSize,
                              fontFamily: "MontserratBold",
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
                border: Border.all(color: Colors.white, width: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
