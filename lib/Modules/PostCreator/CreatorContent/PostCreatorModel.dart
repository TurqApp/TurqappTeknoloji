class PostCreatorModel {
  final int index;
  final String text;

  PostCreatorModel({required this.index, required this.text});

  PostCreatorModel copyWith({int? index, String? text}) {
    return PostCreatorModel(
      index: index ?? this.index,
      text: text ?? this.text,
    );
  }
}