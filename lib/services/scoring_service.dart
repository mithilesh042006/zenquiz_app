import '../models/quiz_settings.dart';

/// Calculates scores for quiz answers.
class ScoringService {
  static const int baseScore = 1000;
  static const int maxSpeedBonus = 500;

  /// Returns the streak multiplier for a given streak count.
  static double streakMultiplier(int streak) {
    if (streak <= 1) return 1.0;
    if (streak == 2) return 1.2;
    if (streak == 3) return 1.5;
    return 2.0; // 4+
  }

  /// Calculate points for an answer.
  ///
  /// [isCorrect] — whether the answer was correct.
  /// [responseTimeMs] — how long the participant took to answer.
  /// [timeLimitMs] — the time limit for the question.
  /// [currentStreak] — the participant's current correct-answer streak.
  /// [scoringMode] — the scoring mode from quiz settings.
  static int calculateScore({
    required bool isCorrect,
    required int responseTimeMs,
    required int timeLimitMs,
    required int currentStreak,
    required ScoringMode scoringMode,
  }) {
    if (!isCorrect) return 0;

    int score = baseScore;

    // Speed bonus: linear decay from maxSpeedBonus to 0
    if (scoringMode == ScoringMode.speedBonus ||
        scoringMode == ScoringMode.streakMultiplier) {
      final timeRatio = 1.0 - (responseTimeMs / timeLimitMs).clamp(0.0, 1.0);
      score += (maxSpeedBonus * timeRatio).round();
    }

    // Streak multiplier
    if (scoringMode == ScoringMode.streakMultiplier) {
      final multiplier = streakMultiplier(
        currentStreak + 1,
      ); // +1 for this answer
      score = (score * multiplier).round();
    }

    return score;
  }
}
