/// Represents a participant's answer to a single question.
class ParticipantAnswer {
  final String questionId;
  final List<int> selectedIndices;
  final bool isCorrect;
  final int responseTimeMs;
  final int pointsEarned;

  const ParticipantAnswer({
    required this.questionId,
    required this.selectedIndices,
    required this.isCorrect,
    required this.responseTimeMs,
    this.pointsEarned = 0,
  });

  factory ParticipantAnswer.fromJson(Map<String, dynamic> json) {
    return ParticipantAnswer(
      questionId: json['questionId'] as String,
      selectedIndices: (json['selectedIndices'] as List).cast<int>(),
      isCorrect: json['isCorrect'] as bool,
      responseTimeMs: json['responseTimeMs'] as int,
      pointsEarned: json['pointsEarned'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'selectedIndices': selectedIndices,
    'isCorrect': isCorrect,
    'responseTimeMs': responseTimeMs,
    'pointsEarned': pointsEarned,
  };
}

/// A participant in a quiz session.
class Participant {
  final String id;
  final String teamName;
  int totalScore;
  int currentStreak;
  final List<ParticipantAnswer> answers;
  bool isConnected;

  Participant({
    required this.id,
    required this.teamName,
    this.totalScore = 0,
    this.currentStreak = 0,
    List<ParticipantAnswer>? answers,
    this.isConnected = true,
  }) : answers = answers ?? [];

  double get accuracy {
    if (answers.isEmpty) return 0.0;
    final correct = answers.where((a) => a.isCorrect).length;
    return correct / answers.length;
  }

  double get avgResponseTimeMs {
    if (answers.isEmpty) return 0.0;
    final total = answers.fold<int>(0, (sum, a) => sum + a.responseTimeMs);
    return total / answers.length;
  }

  void addAnswer(ParticipantAnswer answer) {
    answers.add(answer);
    totalScore += answer.pointsEarned;
    if (answer.isCorrect) {
      currentStreak++;
    } else {
      currentStreak = 0;
    }
  }

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] as String,
      teamName: json['teamName'] as String,
      totalScore: json['totalScore'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      answers: (json['answers'] as List?)
          ?.map((e) => ParticipantAnswer.fromJson(e as Map<String, dynamic>))
          .toList(),
      isConnected: json['isConnected'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'teamName': teamName,
    'totalScore': totalScore,
    'currentStreak': currentStreak,
    'answers': answers.map((a) => a.toJson()).toList(),
    'isConnected': isConnected,
  };
}
