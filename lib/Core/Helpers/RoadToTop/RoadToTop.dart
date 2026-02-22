import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RoadToTop extends StatelessWidget {
  const RoadToTop({super.key});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          CupertinoIcons.arrow_up,
          color: Colors.black,
        ),
      ),
    );
  }
}
