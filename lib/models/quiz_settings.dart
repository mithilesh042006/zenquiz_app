/// How the timer operates.
enum TimerMode { perQuestion, totalQuiz }

/// The scoring mode for the quiz.
enum ScoringMode {
  standard, // correctness only
  speedBonus, // correctness + speed bonus
  streakMultiplier, // correctness + speed bonus + streak multiplier
}

/// Configuration settings for a quiz.
class QuizSettings {
  final TimerMode timerMode;
  final int defaultTimeLimitSec;
  final ScoringMode scoringMode;
  final bool shuffleQuestions;
  final bool shuffleOptions;

  const QuizSettings({
    this.timerMode = TimerMode.perQuestion,
    this.defaultTimeLimitSec = 30,
    this.scoringMode = ScoringMode.speedBonus,
    this.shuffleQuestions = false,
    this.shuffleOptions = false,
  });

  QuizSettings copyWith({
    TimerMode? timerMode,
    int? defaultTimeLimitSec,
    ScoringMode? scoringMode,
    bool? shuffleQuestions,
    bool? shuffleOptions,
  }) {
    return QuizSettings(
      timerMode: timerMode ?? this.timerMode,
      defaultTimeLimitSec: defaultTimeLimitSec ?? this.defaultTimeLimitSec,
      scoringMode: scoringMode ?? this.scoringMode,
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      shuffleOptions: shuffleOptions ?? this.shuffleOptions,
    );
  }

  factory QuizSettings.fromJson(Map<String, dynamic> json) {
    return QuizSettings(
      timerMode: TimerMode.values.firstWhere(
        (e) => e.name == json['timerMode'],
        orElse: () => TimerMode.perQuestion,
      ),
      defaultTimeLimitSec: json['defaultTimeLimitSec'] as int? ?? 30,
      scoringMode: ScoringMode.values.firstWhere(
        (e) => e.name == json['scoringMode'],
        orElse: () => ScoringMode.speedBonus,
      ),
      shuffleQuestions: json['shuffleQuestions'] as bool? ?? false,
      shuffleOptions: json['shuffleOptions'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'timerMode': timerMode.name,
    'defaultTimeLimitSec': defaultTimeLimitSec,
    'scoringMode': scoringMode.name,
    'shuffleQuestions': shuffleQuestions,
    'shuffleOptions': shuffleOptions,
  };
}
