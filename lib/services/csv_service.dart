import 'dart:convert';
import '../models/question.dart';
import '../models/quiz.dart';
import '../models/participant.dart';
import 'package:csv/csv.dart';

/// Handles CSV import/export for quizzes and results.
class CsvService {
  /// Export a quiz's questions to CSV string.
  /// Format: question,optionA,optionB,optionC,optionD,correct,type
  static String exportQuizToCsv(Quiz quiz) {
    final rows = <List<String>>[
      [
        'question',
        'optionA',
        'optionB',
        'optionC',
        'optionD',
        'correct',
        'type',
      ],
    ];

    for (final q in quiz.questions) {
      final options = List<String>.generate(
        4,
        (i) => i < q.options.length ? q.options[i] : '',
      );
      final correctStr = q.correctIndices.join(';');
      rows.add([q.text, ...options, correctStr, q.type.name]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Import questions from a CSV string.
  static List<Question> importQuestionsFromCsv(String csvContent) {
    final rows = const CsvToListConverter().convert(csvContent);
    if (rows.isEmpty) return [];

    // Skip header row
    final dataRows = rows.length > 1 ? rows.sublist(1) : rows;
    final questions = <Question>[];

    for (final row in dataRows) {
      if (row.length < 6) continue;

      final text = row[0].toString().trim();
      if (text.isEmpty) continue;

      final options = <String>[];
      for (int i = 1; i <= 4; i++) {
        final opt = i < row.length ? row[i].toString().trim() : '';
        if (opt.isNotEmpty) options.add(opt);
      }

      // Parse correct indices (could be "0", "0;2", etc.)
      final correctStr = row.length > 5 ? row[5].toString().trim() : '0';
      final correctIndices = correctStr
          .split(';')
          .where((s) => s.isNotEmpty)
          .map((s) => int.tryParse(s.trim()) ?? 0)
          .toList();

      // Parse question type
      final typeStr = row.length > 6 ? row[6].toString().trim() : '';
      QuestionType type;
      switch (typeStr) {
        case 'multipleChoice':
          type = QuestionType.multipleChoice;
          break;
        case 'trueFalse':
          type = QuestionType.trueFalse;
          break;
        default:
          type = QuestionType.singleChoice;
      }

      questions.add(
        Question(
          text: text,
          options: options,
          correctIndices: correctIndices,
          type: type,
        ),
      );
    }

    return questions;
  }

  /// Export session results to CSV.
  static String exportResultsToCsv(
    List<Participant> participants,
    List<Question> questions,
  ) {
    final header = <String>[
      'Rank',
      'Team',
      'Score',
      'Accuracy',
      'Avg Response Time (ms)',
    ];
    // Add question headers
    for (int i = 0; i < questions.length; i++) {
      header.add('Q${i + 1}');
    }

    final rows = <List<String>>[header];

    // Sort by score descending
    final sorted = List<Participant>.from(participants);
    sorted.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    for (int rank = 0; rank < sorted.length; rank++) {
      final p = sorted[rank];
      final row = <String>[
        '${rank + 1}',
        p.teamName,
        '${p.totalScore}',
        '${(p.accuracy * 100).toStringAsFixed(1)}%',
        p.avgResponseTimeMs.toStringAsFixed(0),
      ];

      // Per-question results
      for (final q in questions) {
        final answer = p.answers.where((a) => a.questionId == q.id).firstOrNull;
        if (answer != null) {
          row.add(answer.isCorrect ? '✓' : '✗');
        } else {
          row.add('-');
        }
      }

      rows.add(row);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Export quiz to JSON string.
  static String exportQuizToJson(Quiz quiz) {
    return const JsonEncoder.withIndent('  ').convert(quiz.toJson());
  }

  /// Import quiz from JSON string.
  static Quiz importQuizFromJson(String jsonContent) {
    final map = jsonDecode(jsonContent) as Map<String, dynamic>;
    return Quiz.fromJson(map);
  }
}
