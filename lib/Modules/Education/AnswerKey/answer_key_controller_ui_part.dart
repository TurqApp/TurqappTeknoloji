part of 'answer_key_controller.dart';

final List<String> _answerKeyLessons = <String>[
  'LGS',
  'TYT',
  'AYT',
  'YDT',
  'YDS',
  'ALES',
  'DGS',
  'KPSS',
  'DUS',
  'TUS',
  'Dil',
  'Yazılım',
  'Spor',
  'Tasarım',
];

final List<Color> _answerKeyColors = <Color>[
  Colors.deepPurple,
  Colors.indigo,
  Colors.teal,
  Colors.deepOrange,
  Colors.pink,
  Colors.cyan.shade700,
  Colors.blueGrey,
  Colors.pink.shade900,
];

final List<Color> _answerKeyLessonsColors = <Color>[
  Colors.lightBlue.shade700,
  Colors.pink.shade600,
  Colors.green.shade700,
  Colors.orange.shade700,
  Colors.red.shade800,
  Colors.indigo.shade800,
  Colors.lime.shade700,
  Colors.brown.shade800,
  Colors.blue.shade800,
  Colors.cyan.shade800,
  Colors.purple.shade700,
  Colors.teal.shade700,
  Colors.red.shade700,
  Colors.deepOrange.shade700,
];

const List<IconData> _answerKeyLessonIcons = <IconData>[
  Icons.psychology,
  Icons.school,
  Icons.library_books,
  Icons.translate,
  Icons.language,
  Icons.book_online,
  Icons.calculate,
  Icons.assignment,
  Icons.health_and_safety,
  Icons.medical_services,
  Icons.translate,
  Icons.code,
  Icons.sports_basketball,
  Icons.design_services,
];

extension AnswerKeyControllerUiPart on AnswerKeyController {
  List<String> get lessons => _answerKeyLessons;

  List<Color> get colors => _answerKeyColors;

  List<Color> get lessonsColors => _answerKeyLessonsColors;

  List<IconData> get lessonsIcons => _answerKeyLessonIcons;
}
