import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../services/csv_service.dart';
import '../../theme/app_theme.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: const Center(child: Text('No results available')),
      );
    }

    final ranked = session.leaderboard;
    final quiz = ref.read(quizListProvider.notifier).getQuiz(session.quizId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => _exportResults(context, ref),
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Export Results',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Summary row
            Row(
              children: [
                _SummaryCard(
                  Icons.people_rounded,
                  '${ranked.length}',
                  'Players',
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  Icons.help_outline,
                  '${quiz?.questionCount ?? 0}',
                  'Questions',
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  Icons.emoji_events_rounded,
                  ranked.isNotEmpty ? ranked.first.teamName : '-',
                  'Winner',
                  accent: true,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: ranked.length,
                itemBuilder: (context, i) {
                  final p = ranked[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            '#${i + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: i < 3 ? AppTheme.gold : AppTheme.textMuted,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.teamName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${(p.accuracy * 100).toStringAsFixed(0)}% accuracy',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${p.totalScore}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: AppTheme.gold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Export + Back buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exportResults(context, ref),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Export Results'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(sessionProvider.notifier).clearSession();
                      context.go('/');
                    },
                    child: const Text('Back to Home'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportResults(BuildContext context, WidgetRef ref) async {
    final session = ref.read(sessionProvider);
    if (session == null) return;

    final quiz = ref.read(quizListProvider.notifier).getQuiz(session.quizId);
    if (quiz == null) return;

    try {
      final csvContent = CsvService.exportResultsToCsv(
        session.participants,
        quiz.questions,
      );

      final quizTitle = quiz.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final timestamp = DateTime.now().toIso8601String().split('T').first;
      final fileName = '${quizTitle}_results_$timestamp.csv';

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csvContent);

      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Quiz Results: ${quiz.title}');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool accent;

  const _SummaryCard(this.icon, this.value, this.label, {this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accent
              ? AppTheme.gold.withValues(alpha: 0.1)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: accent
              ? Border.all(color: AppTheme.gold.withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: accent ? AppTheme.gold : AppTheme.textMuted,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: accent ? AppTheme.gold : AppTheme.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
