import 'package:uuid/uuid.dart';
import 'quiz.dart';
import 'participant.dart';

/// The state of a quiz session.
enum SessionStatus {
  lobby, // Waiting for participants
  playing, // Quiz in progress
  questionResults, // Showing results for current question
  leaderboard, // Showing leaderboard between questions
  finished, // Quiz completed
}

/// A live quiz session.
class Session {
  final String id;
  final String quizId;
  final String quizTitle;
  final int totalQuestions;
  SessionStatus status;
  int currentQuestionIndex;
  final List<Participant> participants;
  final DateTime? startedAt;
  DateTime? endedAt;

  Session({
    String? id,
    required this.quizId,
    required this.quizTitle,
    required this.totalQuestions,
    this.status = SessionStatus.lobby,
    this.currentQuestionIndex = -1,
    List<Participant>? participants,
    DateTime? startedAt,
    this.endedAt,
  }) : id = id ?? const Uuid().v4(),
       participants = participants ?? [],
       startedAt = startedAt ?? DateTime.now();

  /// Create a new session from a quiz.
  factory Session.fromQuiz(Quiz quiz) {
    return Session(
      quizId: quiz.id,
      quizTitle: quiz.title,
      totalQuestions: quiz.questionCount,
    );
  }

  int get participantCount => participants.length;
  int get connectedCount => participants.where((p) => p.isConnected).length;

  bool get isLastQuestion => currentQuestionIndex >= totalQuestions - 1;

  /// Get participants sorted by score (descending).
  List<Participant> get leaderboard {
    final sorted = List<Participant>.from(participants);
    sorted.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return sorted;
  }

  Participant? findParticipant(String participantId) {
    try {
      return participants.firstWhere((p) => p.id == participantId);
    } catch (_) {
      return null;
    }
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String?,
      quizId: json['quizId'] as String,
      quizTitle: json['quizTitle'] as String,
      totalQuestions: json['totalQuestions'] as int,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SessionStatus.lobby,
      ),
      currentQuestionIndex: json['currentQuestionIndex'] as int? ?? -1,
      participants: (json['participants'] as List?)
          ?.map((e) => Participant.fromJson(e as Map<String, dynamic>))
          .toList(),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'quizId': quizId,
    'quizTitle': quizTitle,
    'totalQuestions': totalQuestions,
    'status': status.name,
    'currentQuestionIndex': currentQuestionIndex,
    'participants': participants.map((p) => p.toJson()).toList(),
    'startedAt': startedAt?.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
  };
}
