import 'package:hive/hive.dart';

part 'quiz_model.g.dart';

@HiveType(typeId: 0)
class QuizModel extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  List<QuestionModel> questions;

  @HiveField(2)
  int timePerQuestion; // Time limit per question

  QuizModel({
    required this.title,
    required this.questions,
    required this.timePerQuestion,
  });
}

@HiveType(typeId: 1)
class QuestionModel {
  @HiveField(0)
  String question;

  @HiveField(1)
  String? answer; // Used for single-answer questions

  @HiveField(2)
  List<String>? options; // Used for MCQs (2 or 4 choices)

  @HiveField(3)
  int? correctChoiceIndex; // Stores the correct answer's index for MCQs

  QuestionModel({
    required this.question,
    this.answer,
    this.options,
    this.correctChoiceIndex,
  });
}
