import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/quiz_editor/quiz_editor_screen.dart';
import '../screens/quiz_editor/question_editor_screen.dart';
import '../screens/session/lobby_screen.dart';
import '../screens/session/quiz_control_screen.dart';
import '../screens/session/leaderboard_screen.dart';
import '../screens/results/results_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/history/session_detail_screen.dart';
import '../theme/app_theme.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/quiz/new',
      builder: (context, state) => const QuizEditorScreen(),
    ),
    GoRoute(
      path: '/quiz/:id',
      builder: (context, state) {
        final quizId = state.pathParameters['id']!;
        return QuizEditorScreen(quizId: quizId);
      },
    ),
    GoRoute(
      path: '/quiz/:quizId/question',
      builder: (context, state) {
        final quizId = state.pathParameters['quizId']!;
        return QuestionEditorScreen(quizId: quizId);
      },
    ),
    GoRoute(
      path: '/quiz/:quizId/question/:questionId',
      builder: (context, state) {
        final quizId = state.pathParameters['quizId']!;
        final questionId = state.pathParameters['questionId']!;
        return QuestionEditorScreen(quizId: quizId, questionId: questionId);
      },
    ),
    GoRoute(
      path: '/session/:quizId/lobby',
      builder: (context, state) {
        final quizId = state.pathParameters['quizId']!;
        return LobbyScreen(quizId: quizId);
      },
    ),
    GoRoute(
      path: '/session/control',
      builder: (context, state) => const QuizControlScreen(),
    ),
    GoRoute(
      path: '/session/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) => const ResultsScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/history/:sessionId',
      builder: (context, state) {
        final sessionId = state.pathParameters['sessionId']!;
        return SessionDetailScreen(sessionId: sessionId);
      },
    ),
  ],
);

class ZenQuizApp extends StatelessWidget {
  const ZenQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ZenQuiz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
