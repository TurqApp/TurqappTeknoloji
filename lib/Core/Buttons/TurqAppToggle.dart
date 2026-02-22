import 'package:flutter/material.dart';

class TurqAppToggle extends StatelessWidget {
  final bool isOn;
  TurqAppToggle({super.key, required this.isOn});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      width: 50,
      alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: isOn ? Colors.black : Colors.grey.shade300,
        borderRadius: BorderRadius.all(Radius.circular(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: Container(
          width: 29,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
