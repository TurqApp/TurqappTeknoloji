part of 'scholarships_controller.dart';

class InformationModel {
  final String title;
  final Color color;
  final IconData icon;

  InformationModel({
    required this.title,
    required this.color,
    required this.icon,
  });
}

List<Color> colors = [
  Colors.blueGrey,
  Colors.teal,
  Colors.deepOrange,
  Colors.indigo,
];

List<IconData> icons = [
  CupertinoIcons.person,
  CupertinoIcons.building_2_fill,
  CupertinoIcons.person_2,
  CupertinoIcons.house_fill,
];
