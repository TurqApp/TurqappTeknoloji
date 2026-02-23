import 'package:flutter/material.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class Infomessage extends StatelessWidget {
  final String infoMessage;
  const Infomessage({required this.infoMessage, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(AppIcons.info, color: Colors.grey, size: 40),
          8.ph,
          Text(
            infoMessage,
            style: TextStyle(
              fontSize: 15,
              fontFamily: "MontserratMedium",
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
