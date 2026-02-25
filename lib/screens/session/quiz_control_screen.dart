import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/question.dart';
import '../../models/session.dart';
import '../../models/participant.dart';
import '../../models/quiz_settings.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/session_provider.dart';

import '../../services/server_service.dart';
import '../../services/scoring_service.dart';
import '../../theme/app_theme.dart';

/// Global reference so lobby's server service can be accessed.
/// In a production app this would be a proper provider.
ServerService? activeServerService;

class QuizControlScreen extends ConsumerStatefulWidget {
  const QuizControlScreen({super.key});

  @override
  ConsumerState<QuizControlScreen> createState() => _QuizControlScreenState();
}

class _QuizControlScreenState extends ConsumerState<QuizControlScreen> {
  Timer? _timer;
  int _timeRemainingMs = 0;
  int _totalTimeMs = 0;
  List<Question> _questions = [];
  Map<String, bool> _answeredMap = {};

  @override
  void initState() {
    super.initState();
    _setupQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setupQuiz() {
    final session = ref.read(sessionProvider);
    if (session == null) return;

    final quiz = ref.read(quizListProvider.notifier).getQuiz(session.quizId);
    if (quiz == null) return;

    _questions = List.from(quiz.questions);
    if (quiz.settings.shuffleQuestions) _questions.shuffle();

    // Wire up answer handler
    activeServerService?.onAnswerReceived = _onAnswerReceived;

    // Start first question
    _nextQuestion();
  }

  void _onAnswerReceived(
    String participantId,
    String questionId,
    List<int> selectedIndices,
    int responseTimeMs,
  ) {
    if (_answeredMap[participantId] == true) return;
    _answeredMap[participantId] = true;

    final session = ref.read(sessionProvider);
    if (session == null) return;

    final currentIndex = session.currentQuestionIndex;
    if (currentIndex < 0 || currentIndex >= _questions.length) return;

    final question = _questions[currentIndex];
    if (question.id != questionId) return;

    final isCorrect = question.isCorrect(selectedIndices);
    final participant = session.findParticipant(participantId);
    if (participant == null) return;

    final quiz = ref.read(quizListProvider.notifier).getQuiz(session.quizId);
    final scoringMode = quiz?.settings.scoringMode ?? ScoringMode.speedBonus;

    final points = ScoringService.calculateScore(
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
      timeLimitMs: _totalTimeMs,
      currentStreak: participant.currentStreak,
      scoringMode: scoringMode,
    );

    final answer = ParticipantAnswer(
      questionId: questionId,
      selectedIndices: selectedIndices,
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
      pointsEarned: points,
    );

    ref.read(sessionProvider.notifier).recordAnswer(participantId, answer);

    // Send feedback to participant
    activeServerService?.sendTo(participantId, {
      'type': 'answer_result',
      'isCorrect': isCorrect,
      'points': points,
    });

    setState(() {});
  }

  void _nextQuestion() {
    ref.read(sessionProvider.notifier).nextQuestion();
    final session = ref.read(sessionProvider);
    if (session == null) return;

    final currentIndex = session.currentQuestionIndex;
    if (currentIndex >= _questions.length) {
      _endQuiz();
      return;
    }

    final question = _questions[currentIndex];
    final quiz = ref.read(quizListProvider.notifier).getQuiz(session.quizId);
    final timeLimitSec = question.timeLimitSeconds > 0
        ? question.timeLimitSeconds
        : (quiz?.settings.defaultTimeLimitSec ?? 30);

    _totalTimeMs = timeLimitSec * 1000;
    _timeRemainingMs = _totalTimeMs;
    _answeredMap = {};

    // Broadcast question to participants
    activeServerService?.broadcast({
      'type': 'question',
      'questionId': question.id,
      'questionNumber': currentIndex + 1,
      'totalQuestions': _questions.length,
      'text': question.text,
      'options': question.options,
      'timeLimitMs': _totalTimeMs,
      if (question.imageBase64 != null) 'imageBase64': question.imageBase64,
    });

    // Start countdown
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _timeRemainingMs -= 100;
        if (_timeRemainingMs <= 0) {
          _timer?.cancel();
          _showResults();
        }
      });
    });
  }

  void _showResults() {
    _timer?.cancel();
    ref.read(sessionProvider.notifier).showQuestionResults();
    setState(() {});

    // Auto-advance to leaderboard after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _showLeaderboard();
    });
  }

  void _showLeaderboard() {
    ref.read(sessionProvider.notifier).showLeaderboard();
    final session = ref.read(sessionProvider);
    if (session == null) return;

    // Broadcast leaderboard
    final entries = session.leaderboard
        .map((p) => {'id': p.id, 'teamName': p.teamName, 'score': p.totalScore})
        .toList();

    activeServerService?.broadcast({'type': 'leaderboard', 'entries': entries});

    setState(() {});
  }

  void _endQuiz() {
    _timer?.cancel();
    ref.read(sessionProvider.notifier).endSession();
    final session = ref.read(sessionProvider);
    if (session == null) return;

    // Send final results to each participant
    final ranked = session.leaderboard;
    for (int i = 0; i < ranked.length; i++) {
      activeServerService?.sendTo(ranked[i].id, {
        'type': 'quiz_end',
        'rank': i + 1,
        'score': ranked[i].totalScore,
      });
    }

    // Save completed session to history
    ref.read(storageServiceProvider).saveSession(session);

    // Stop the server and release the port for next session
    activeServerService?.stop();
    activeServerService = null;

    context.go('/results');
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    if (session == null) {
      return const Scaffold(body: Center(child: Text('No active session')));
    }

    final currentIndex = session.currentQuestionIndex;
    final question = currentIndex >= 0 && currentIndex < _questions.length
        ? _questions[currentIndex]
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Q${currentIndex + 1}/${_questions.length}'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _endQuiz,
            child: const Text(
              'End Quiz',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ─── Timer bar ───
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _totalTimeMs > 0 ? _timeRemainingMs / _totalTimeMs : 0,
                backgroundColor: AppTheme.surfaceLight,
                color: _timeRemainingMs > _totalTimeMs * 0.25
                    ? AppTheme.gold
                    : AppTheme.error,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_timeRemainingMs / 1000).ceil()}s',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppTheme.gold),
            ),
            const SizedBox(height: 24),

            if (session.status == SessionStatus.playing &&
                question != null) ...[
              // ─── Question ───
              Expanded(
                child: Column(
                  children: [
                    Text(
                      question.text,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Answer distribution
                    Text(
                      '${_answeredMap.length}/${session.participantCount} answered',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    // Options preview
                    ...question.options.asMap().entries.map((entry) {
                      final isCorrect = question.correctIndices.contains(
                        entry.key,
                      );
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          border: Border.all(
                            color: isCorrect
                                ? AppTheme.correct.withValues(alpha: 0.3)
                                : AppTheme.surfaceLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: isCorrect
                                  ? AppTheme.correct.withValues(alpha: 0.2)
                                  : AppTheme.surfaceLight,
                              child: Text(
                                String.fromCharCode(65 + entry.key),
                                style: TextStyle(
                                  color: isCorrect
                                      ? AppTheme.correct
                                      : AppTheme.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(entry.value)),
                            if (isCorrect)
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: AppTheme.correct,
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // Skip button
              OutlinedButton.icon(
                onPressed: () {
                  _timer?.cancel();
                  _showResults();
                },
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('Skip to Results'),
              ),
            ],

            if (session.status == SessionStatus.questionResults) ...[
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        size: 64,
                        color: AppTheme.gold,
                      ),
                      SizedBox(height: 16),
                      Text('Question Results', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                ),
              ),
            ],

            if (session.status == SessionStatus.leaderboard) ...[
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '🏆 Leaderboard',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: session.leaderboard.length,
                        itemBuilder: (context, index) {
                          final p = session.leaderboard[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: index < 3
                                  ? AppTheme.gold.withValues(
                                      alpha: 0.1 - index * 0.02,
                                    )
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                              border: index == 0
                                  ? Border.all(
                                      color: AppTheme.gold.withValues(
                                        alpha: 0.3,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: index < 3
                                          ? AppTheme.gold
                                          : AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                                Expanded(child: Text(p.teamName)),
                                Text(
                                  '${p.totalScore}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.gold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: session.isLastQuestion ? _endQuiz : _nextQuestion,
                  icon: Icon(
                    session.isLastQuestion
                        ? Icons.flag_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    session.isLastQuestion ? 'Finish Quiz' : 'Next Question',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
