import 'package:uuid/uuid.dart';

/// The type of question.
enum QuestionType { singleChoice, multipleChoice, trueFalse }

/// A single quiz question with options and correct answers.
class Question {
  final String id;
  final String text;
  final List<String> options;
  final List<int> correctIndices;
  final QuestionType type;
  final int timeLimitSeconds; // 0 means use quiz default

  Question({
    String? id,
    required this.text,
    required this.options,
    required this.correctIndices,
    this.type = QuestionType.singleChoice,
    this.timeLimitSeconds = 0,
  }) : id = id ?? const Uuid().v4();

  Question copyWith({
    String? id,
    String? text,
    List<String>? options,
    List<int>? correctIndices,
    QuestionType? type,
    int? timeLimitSeconds,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      options: options ?? List.from(this.options),
      correctIndices: correctIndices ?? List.from(this.correctIndices),
      type: type ?? this.type,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
    );
  }

  /// Check if the given answer indices are correct.
  bool isCorrect(List<int> answerIndices) {
    if (answerIndices.length != correctIndices.length) return false;
    final sortedAnswer = List<int>.from(answerIndices)..sort();
    final sortedCorrect = List<int>.from(correctIndices)..sort();
    for (int i = 0; i < sortedAnswer.length; i++) {
      if (sortedAnswer[i] != sortedCorrect[i]) return false;
    }
    return true;
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String?,
      text: json['text'] as String,
      options: (json['options'] as List).cast<String>(),
      correctIndices: (json['correctIndices'] as List).cast<int>(),
      type: QuestionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => QuestionType.singleChoice,
      ),
      timeLimitSeconds: json['timeLimitSeconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'options': options,
    'correctIndices': correctIndices,
    'type': type.name,
    'timeLimitSeconds': timeLimitSeconds,
  };
}
