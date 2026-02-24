import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/session.dart';
import '../../models/participant.dart';
import '../../providers/quiz_provider.dart';
import '../../services/csv_service.dart';
import '../../theme/app_theme.dart';

class SessionDetailScreen extends ConsumerWidget {
  final String sessionId;
  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.read(storageServiceProvider);
    final sessions = storage.getSessionHistory();
    final session = sessions.cast<Session?>().firstWhere(
      (s) => s!.id == sessionId,
      orElse: () => null,
    );

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session Details')),
        body: const Center(child: Text('Session not found')),
      );
    }

    final ranked = session.leaderboard;
    final quiz = ref.read(quizListProvider.notifier).getQuiz(session.quizId);
    final dateStr = session.startedAt != null
        ? DateFormat('EEEE, MMM d, y – h:mm a').format(session.startedAt!)
        : 'Unknown date';

    // Calculate duration
    String durationStr = '–';
    if (session.startedAt != null && session.endedAt != null) {
      final duration = session.endedAt!.difference(session.startedAt!);
      if (duration.inMinutes > 0) {
        durationStr = '${duration.inMinutes}m ${duration.inSeconds % 60}s';
      } else {
        durationStr = '${duration.inSeconds}s';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(session.quizTitle),
        actions: [
          IconButton(
            onPressed: () =>
                _exportResults(context, session, quiz?.questions ?? []),
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Export Results',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Session Info Card ───
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.gold.withValues(alpha: 0.12),
                  AppTheme.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.quizTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatChip(
                      Icons.people_rounded,
                      '${ranked.length}',
                      'Players',
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      Icons.help_outline_rounded,
                      '${session.totalQuestions}',
                      'Questions',
                    ),
                    const SizedBox(width: 12),
                    _StatChip(Icons.timer_rounded, durationStr, 'Duration'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Podium (top 3) ───
          if (ranked.isNotEmpty) ...[
            const Text(
              '🏆  Podium',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.white,
              ),
            ),
            const SizedBox(height: 12),
            _PodiumSection(ranked: ranked),
            const SizedBox(height: 24),
          ],

          // ─── Full Leaderboard ───
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Full Leaderboard',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.white,
                  ),
                ),
              ),
              Text(
                '${ranked.length} players',
                style: const TextStyle(color: AppTheme.textDim, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusMd),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    '#',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Team',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    'Score',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    'Accuracy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    'Streak',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table rows
          ...List.generate(ranked.length, (i) {
            final p = ranked[i];
            final isTop3 = i < 3;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isTop3
                    ? AppTheme.gold.withValues(alpha: 0.04 * (3 - i))
                    : AppTheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.surfaceLight.withValues(alpha: 0.5),
                  ),
                ),
                borderRadius: i == ranked.length - 1
                    ? BorderRadius.vertical(
                        bottom: Radius.circular(AppTheme.radiusMd),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      _rankLabel(i),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isTop3 ? AppTheme.gold : AppTheme.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      p.teamName,
                      style: TextStyle(
                        fontWeight: isTop3 ? FontWeight.w600 : FontWeight.w400,
                        color: AppTheme.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${p.totalScore}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isTop3 ? AppTheme.gold : AppTheme.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      '${(p.accuracy * 100).toStringAsFixed(0)}%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _accuracyColor(p.accuracy),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${p.currentStreak}🔥',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // ─── Export Button ───
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  _exportResults(context, session, quiz?.questions ?? []),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Export Results as CSV'),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _rankLabel(int index) {
    switch (index) {
      case 0:
        return '🥇';
      case 1:
        return '🥈';
      case 2:
        return '🥉';
      default:
        return '${index + 1}';
    }
  }

  Color _accuracyColor(double accuracy) {
    if (accuracy >= 0.8) return AppTheme.correct;
    if (accuracy >= 0.5) return AppTheme.gold;
    return AppTheme.incorrect;
  }

  Future<void> _exportResults(
    BuildContext context,
    Session session,
    List questions,
  ) async {
    try {
      final quiz = ProviderScope.containerOf(
        context,
      ).read(quizListProvider.notifier).getQuiz(session.quizId);

      final csvContent = CsvService.exportResultsToCsv(
        session.participants,
        quiz?.questions ?? [],
      );

      final quizTitle = session.quizTitle.replaceAll(
        RegExp(r'[^a-zA-Z0-9]'),
        '_',
      );
      final timestamp =
          session.startedAt?.toIso8601String().split('T').first ?? 'unknown';
      final fileName = '${quizTitle}_results_$timestamp.csv';

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csvContent);

      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Quiz Results: ${session.quizTitle}');
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

// ─── Stat Chip ───
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatChip(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppTheme.gold),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppTheme.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textDim),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Podium Section ───
class _PodiumSection extends StatelessWidget {
  final List<Participant> ranked;
  const _PodiumSection({required this.ranked});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd place
        if (ranked.length > 1)
          Expanded(child: _PodiumTile(ranked[1], 2, 100))
        else
          const Expanded(child: SizedBox()),
        const SizedBox(width: 8),
        // 1st place
        if (ranked.isNotEmpty) Expanded(child: _PodiumTile(ranked[0], 1, 130)),
        const SizedBox(width: 8),
        // 3rd place
        if (ranked.length > 2)
          Expanded(child: _PodiumTile(ranked[2], 3, 80))
        else
          const Expanded(child: SizedBox()),
      ],
    );
  }
}

class _PodiumTile extends StatelessWidget {
  final Participant participant;
  final int rank;
  final double height;
  const _PodiumTile(this.participant, this.rank, this.height);

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppTheme.gold,
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];
    final color = colors[rank - 1];
    final medals = ['🥇', '🥈', '🥉'];

    return Column(
      children: [
        Text(medals[rank - 1], style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          participant.teamName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppTheme.white,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${participant.totalScore} pts',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(
              top: BorderSide(color: color.withValues(alpha: 0.5), width: 2),
              left: BorderSide(color: color.withValues(alpha: 0.2)),
              right: BorderSide(color: color.withValues(alpha: 0.2)),
            ),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
