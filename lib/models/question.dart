// lib/models/question.dart
enum QuestionType { multipleChoice, trueFalse, fillInTheBlank, translation }

class Question {
  final QuestionType type;
  final String text;
  final List<String>? options;
  final String correctAnswer;
  final String level;

  Question({
    required this.type,
    required this.text,
    this.options,
    required this.correctAnswer,
    required this.level,
  });
}
