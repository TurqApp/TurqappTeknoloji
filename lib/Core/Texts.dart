import 'package:flutter/material.dart';
import 'package:turqappv2/Core/sizes.dart';
import 'package:turqappv2/Themes/app_fonts.dart';

class Texts {
  static Container colorfulFloodForExplore = Container(
    decoration: BoxDecoration(
        color: Colors.black.withAlpha(50),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12))),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [Colors.white, Colors.blue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
        blendMode: BlendMode.srcIn,
        child: const Text(
          "DİZİ",
          style: TextStyle(
            fontSize: 18,
            fontFamily: "MontserratBold",
            color: Colors.white,
          ),
        ),
      ),
    ),
  );

  static Container colorfulFlood = Container(
    decoration: BoxDecoration(
        color: Colors.black.withAlpha(50),
        borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(12), topLeft: Radius.circular(12))),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [Colors.white, Colors.blue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
        blendMode: BlendMode.srcIn,
        child: const Text(
          "DİZİ",
          style: TextStyle(
            fontSize: 18,
            fontFamily: "MontserratBold",
            color: Colors.white,
          ),
        ),
      ),
    ),
  );

  static Container colorfulFloodLeftSide = Container(
    decoration: BoxDecoration(
        color: Colors.black.withAlpha(50),
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12), topRight: Radius.circular(12))),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [Colors.white, Colors.blue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
        blendMode: BlendMode.srcIn,
        child: const Text(
          "DİZİ",
          style: TextStyle(
            fontSize: 18,
            fontFamily: "MontserratBold",
            color: Colors.white,
          ),
        ),
      ),
    ),
  );

  static Container colorfulFloodTopLeftSide = Container(
    decoration: BoxDecoration(
        color: Colors.black.withAlpha(50),
        borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(12), topLeft: Radius.circular(0))),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [Colors.white, Colors.blue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
        blendMode: BlendMode.srcIn,
        child: const Text(
          "DİZİ",
          style: TextStyle(
            fontSize: 18,
            fontFamily: "MontserratBold",
            color: Colors.white,
          ),
        ),
      ),
    ),
  );

  static Container colorfulFloodForVideo = Container(
    decoration: BoxDecoration(
        color: Colors.black.withAlpha(50),
        borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(0), topRight: Radius.circular(12))),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [Colors.white, Colors.blue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
        blendMode: BlendMode.srcIn,
        child: const Text(
          "DİZİ",
          style: TextStyle(
            fontSize: 20,
            fontFamily: "MontserratBold",
            color: Colors.white,
          ),
        ),
      ),
    ),
  );

  static Container followMeButtonWhite = Container(
    height: 20,
    alignment: Alignment.center,
    decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: Colors.white)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Text(
        "Takip Et",
        style: TextStyle(
            color: Colors.white,
            fontFamily: AppFontFamilies.mmedium,
            fontSize: FontSizes.size12),
      ),
    ),
  );

  static Container followMeButtonBlack = Container(
    height: 20,
    alignment: Alignment.center,
    decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: Colors.black)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Text(
        "Takip Et",
        style: TextStyle(
            color: Colors.black,
            fontFamily: AppFontFamilies.mmedium,
            fontSize: FontSizes.size12),
      ),
    ),
  );
}
