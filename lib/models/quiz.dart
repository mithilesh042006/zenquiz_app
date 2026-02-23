import 'package:uuid/uuid.dart';
import 'question.dart';
import 'quiz_settings.dart';

/// A quiz containing questions and settings.
class Quiz {
  final String id;
  final String title;
  final String? description;
  final List<Question> questions;
  final QuizSettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  Quiz({
    String? id,
    required this.title,
    this.description,
    List<Question>? questions,
    QuizSettings? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       questions = questions ?? [],
       settings = settings ?? const QuizSettings(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Quiz copyWith({
    String? id,
    String? title,
    String? description,
    List<Question>? questions,
    QuizSettings? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quiz(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      questions: questions ?? List.from(this.questions),
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  int get questionCount => questions.length;

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      questions:
          (json['questions'] as List?)
              ?.map((e) => Question.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      settings: json['settings'] != null
          ? QuizSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : const QuizSettings(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'questions': questions.map((q) => q.toJson()).toList(),
    'settings': settings.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
