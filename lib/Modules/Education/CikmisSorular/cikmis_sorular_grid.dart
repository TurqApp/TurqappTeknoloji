import 'package:flutter/material.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_road.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.anaBaslik,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 35,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  4.ph,
                  Text(
                    "Denemeler",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
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
                border: Border.all(color: Colors.white, width: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
