import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_theme.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    if (session == null) {
      return const Scaffold(body: Center(child: Text('No active session')));
    }

    final ranked = session.leaderboard;

    return Scaffold(
      appBar: AppBar(title: const Text('🏆 Leaderboard')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ─── Podium (Top 3) ───
            if (ranked.length >= 3)
              SizedBox(
                height: 200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _PodiumEntry(
                      rank: 2,
                      name: ranked[1].teamName,
                      score: ranked[1].totalScore,
                      height: 120,
                    ),
                    const SizedBox(width: 8),
                    _PodiumEntry(
                      rank: 1,
                      name: ranked[0].teamName,
                      score: ranked[0].totalScore,
                      height: 160,
                    ),
                    const SizedBox(width: 8),
                    _PodiumEntry(
                      rank: 3,
                      name: ranked[2].teamName,
                      score: ranked[2].totalScore,
                      height: 90,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            // ─── Full List ───
            Expanded(
              child: ListView.builder(
                itemCount: ranked.length,
                itemBuilder: (context, index) {
                  final p = ranked[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: index < 3
                                  ? AppTheme.gold
                                  : AppTheme.textMuted,
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
                            fontSize: 18,
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
    );
  }
}

class _PodiumEntry extends StatelessWidget {
  final int rank;
  final String name;
  final int score;
  final double height;

  const _PodiumEntry({
    required this.rank,
    required this.name,
    required this.score,
    required this.height,
  });

  String get _medal {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(_medal, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '$score',
            style: const TextStyle(
              color: AppTheme.gold,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: rank == 1
                  ? AppTheme.gold.withValues(alpha: 0.3)
                  : AppTheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              border: rank == 1
                  ? Border.all(color: AppTheme.gold.withValues(alpha: 0.5))
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
