import 'package:flutter/material.dart';

class EmptyRow extends StatelessWidget {
  final String text;

  EmptyRow({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.black,
              ),
              SizedBox(height: 7),
              Text(
                text,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "Montserrat",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
