import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/quiz_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/quiz.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzes = ref.watch(quizListProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ─── Header ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: AppTheme.gold,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'InnoQuiz',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Host interactive quizzes on your local network',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            // ─── Stats Row ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    _StatChip(
                      icon: Icons.quiz_rounded,
                      label: '${quizzes.length}',
                      subtitle: 'Quizzes',
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      icon: Icons.help_outline_rounded,
                      label:
                          '${quizzes.fold<int>(0, (sum, q) => sum + q.questionCount)}',
                      subtitle: 'Questions',
                    ),
                  ],
                ),
              ),
            ),
            // ─── Section Title ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Quizzes',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/history'),
                      icon: const Icon(Icons.history_rounded, size: 18),
                      label: const Text('Session History'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ─── Quiz List or Empty State ───
            if (quizzes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 64,
                        color: AppTheme.textDim,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No quizzes yet',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first quiz to get started',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/quiz/new'),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create Quiz'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final quiz = quizzes[index];
                    return _QuizCard(quiz: quiz);
                  }, childCount: quizzes.length),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: quizzes.isNotEmpty
    ? Padding(
        padding: const EdgeInsets.only(bottom: 28.0), // ← adjust value
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/quiz/new'),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Quiz'),
        ),
      )
    : null,
    );
  }
}

// ─── Stat Chip Widget ───
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: AppTheme.surfaceLight.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.gold, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quiz Card Widget ───
class _QuizCard extends ConsumerWidget {
  final Quiz quiz;
  const _QuizCard({required this.quiz});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => context.push('/quiz/${quiz.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quiz.title,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteDialog(context, ref);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_rounded,
                              size: 18,
                              color: AppTheme.error,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: AppTheme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (quiz.description != null && quiz.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  quiz.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.help_outline_rounded,
                    text: '${quiz.questionCount} questions',
                  ),
                  const SizedBox(width: 12),
                  _InfoChip(
                    icon: Icons.timer_outlined,
                    text: '${quiz.settings.defaultTimeLimitSec}s',
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: quiz.questionCount > 0
                        ? () => context.push('/session/${quiz.id}/lobby')
                        : null,
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Host'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.gold.withValues(alpha: 0.15),
                      foregroundColor: AppTheme.gold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text('Are you sure you want to delete "${quiz.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(quizListProvider.notifier).deleteQuiz(quiz.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textDim),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
