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
  final List<String> imagesBase64; // optional images as base64 strings

  Question({
    String? id,
    required this.text,
    required this.options,
    required this.correctIndices,
    this.type = QuestionType.singleChoice,
    this.timeLimitSeconds = 0,
    List<String>? imagesBase64,
    // backward compat: accept old single-image field
    String? imageBase64,
  }) : id = id ?? const Uuid().v4(),
       imagesBase64 =
           imagesBase64 ?? (imageBase64 != null ? [imageBase64] : const []);

  Question copyWith({
    String? id,
    String? text,
    List<String>? options,
    List<int>? correctIndices,
    QuestionType? type,
    int? timeLimitSeconds,
    List<String>? imagesBase64,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      options: options ?? List.from(this.options),
      correctIndices: correctIndices ?? List.from(this.correctIndices),
      type: type ?? this.type,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      imagesBase64: imagesBase64 ?? List.from(this.imagesBase64),
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
    // Support both old 'imageBase64' (single) and new 'imagesBase64' (list)
    List<String> images = [];
    if (json['imagesBase64'] != null) {
      images = (json['imagesBase64'] as List).cast<String>();
    } else if (json['imageBase64'] != null) {
      images = [json['imageBase64'] as String];
    }

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
      imagesBase64: images,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'options': options,
    'correctIndices': correctIndices,
    'type': type.name,
    'timeLimitSeconds': timeLimitSeconds,
    if (imagesBase64.isNotEmpty) 'imagesBase64': imagesBase64,
  };
}
