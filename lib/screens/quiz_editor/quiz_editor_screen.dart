import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/quiz.dart';
import '../../models/question.dart';
import '../../models/quiz_settings.dart';
import '../../providers/quiz_provider.dart';
import '../../services/csv_service.dart';
import '../../theme/app_theme.dart';

class QuizEditorScreen extends ConsumerStatefulWidget {
  final String? quizId;
  const QuizEditorScreen({super.key, this.quizId});

  @override
  ConsumerState<QuizEditorScreen> createState() => _QuizEditorScreenState();
}

class _QuizEditorScreenState extends ConsumerState<QuizEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late Quiz _quiz;
  bool _isNew = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initQuiz() {
    if (widget.quizId != null) {
      final existing = ref
          .read(quizListProvider.notifier)
          .getQuiz(widget.quizId!);
      if (existing != null) {
        _quiz = existing;
        _isNew = false;
        _titleController.text = _quiz.title;
        _descriptionController.text = _quiz.description ?? '';
        return;
      }
    }
    _quiz = Quiz(title: '');
    _isNew = true;
  }

  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _initQuiz();
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New Quiz' : 'Edit Quiz'),
        actions: [
          TextButton.icon(
            onPressed: _saveQuiz,
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Title ───
            TextField(
              controller: _titleController,
              style: Theme.of(context).textTheme.headlineMedium,
              decoration: const InputDecoration(
                hintText: 'Quiz Title',
                border: InputBorder.none,
                fillColor: Colors.transparent,
                filled: false,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textMuted),
              decoration: const InputDecoration(
                hintText: 'Add a description (optional)',
                border: InputBorder.none,
                fillColor: Colors.transparent,
                filled: false,
              ),
              maxLines: 2,
            ),
            const Divider(height: 32),

            // ─── Settings ───
            Text('Settings', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _SettingsPanel(
              settings: _quiz.settings,
              onChanged: (settings) {
                setState(() {
                  _quiz = _quiz.copyWith(settings: settings);
                });
              },
            ),
            const Divider(height: 32),

            // ─── Questions ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Questions (${_quiz.questions.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _importQuestions,
                      icon: const Icon(Icons.file_upload_outlined),
                      tooltip: 'Import from CSV',
                    ),
                    if (_quiz.questions.isNotEmpty)
                      IconButton(
                        onPressed: _exportQuestions,
                        icon: const Icon(Icons.file_download_outlined),
                        tooltip: 'Export to CSV',
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_quiz.questions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: AppTheme.surfaceLight,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 48,
                      color: AppTheme.textDim,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No questions yet',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addQuestion,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Question'),
                    ),
                  ],
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _quiz.questions.length,
                onReorder: _reorderQuestions,
                itemBuilder: (context, index) {
                  final question = _quiz.questions[index];
                  return _QuestionTile(
                    key: ValueKey(question.id),
                    index: index,
                    question: question,
                    onTap: () => _editQuestion(question),
                    onDelete: () => _deleteQuestion(index),
                  );
                },
              ),
            if (_quiz.questions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Question'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _saveQuiz() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a quiz title')),
      );
      return;
    }

    _quiz = _quiz.copyWith(
      title: title,
      description: _descriptionController.text.trim(),
    );

    if (_isNew) {
      ref.read(quizListProvider.notifier).addQuiz(_quiz);
    } else {
      ref.read(quizListProvider.notifier).updateQuiz(_quiz);
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Quiz saved!')));

    if (_isNew) {
      context.pop();
    }
  }

  void _addQuestion() async {
    _saveQuizLocally();
    final result = await context.push<Question>('/quiz/${_quiz.id}/question');
    if (result != null) {
      setState(() {
        final questions = List<Question>.from(_quiz.questions)..add(result);
        _quiz = _quiz.copyWith(questions: questions);
      });
      _saveQuizSilently();
    }
  }

  void _editQuestion(Question question) async {
    _saveQuizLocally();
    final result = await context.push<Question>(
      '/quiz/${_quiz.id}/question/${question.id}',
    );
    if (result != null) {
      setState(() {
        final questions = List<Question>.from(_quiz.questions);
        final index = questions.indexWhere((q) => q.id == result.id);
        if (index >= 0) questions[index] = result;
        _quiz = _quiz.copyWith(questions: questions);
      });
      _saveQuizSilently();
    }
  }

  void _deleteQuestion(int index) {
    setState(() {
      final questions = List<Question>.from(_quiz.questions)..removeAt(index);
      _quiz = _quiz.copyWith(questions: questions);
    });
    _saveQuizSilently();
  }

  void _reorderQuestions(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final questions = List<Question>.from(_quiz.questions);
      final item = questions.removeAt(oldIndex);
      questions.insert(newIndex, item);
      _quiz = _quiz.copyWith(questions: questions);
    });
    _saveQuizSilently();
  }

  void _saveQuizLocally() {
    _quiz = _quiz.copyWith(
      title: _titleController.text.trim().isEmpty
          ? 'Untitled Quiz'
          : _titleController.text.trim(),
      description: _descriptionController.text.trim(),
    );
    ref.read(quizListProvider.notifier).addQuiz(_quiz);
    _isNew = false;
  }

  void _saveQuizSilently() {
    ref.read(quizListProvider.notifier).updateQuiz(_quiz);
  }

  Future<void> _importQuestions() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final ext = result.files.single.extension?.toLowerCase();

      List<Question> imported;
      if (ext == 'json') {
        final quiz = CsvService.importQuizFromJson(content);
        imported = quiz.questions;
      } else {
        imported = CsvService.importQuestionsFromCsv(content);
      }

      if (imported.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No valid questions found in file')),
          );
        }
        return;
      }

      setState(() {
        _quiz = _quiz.copyWith(questions: [..._quiz.questions, ...imported]);
      });
      _saveQuizSilently();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported ${imported.length} questions'),
            backgroundColor: AppTheme.correct,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _exportQuestions() async {
    if (_quiz.questions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No questions to export')));
      return;
    }

    try {
      // Show format chooser
      final format = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Export Format'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'csv'),
              child: const ListTile(
                leading: Icon(Icons.table_chart_rounded),
                title: Text('CSV'),
                subtitle: Text('Spreadsheet compatible'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'json'),
              child: const ListTile(
                leading: Icon(Icons.data_object_rounded),
                title: Text('JSON'),
                subtitle: Text('Full quiz data with settings'),
              ),
            ),
          ],
        ),
      );
      if (format == null) return;

      final String content;
      final String fileName;
      if (format == 'json') {
        content = CsvService.exportQuizToJson(_quiz);
        fileName =
            '${_quiz.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.json';
      } else {
        content = CsvService.exportQuizToCsv(_quiz);
        fileName =
            '${_quiz.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.csv';
      }

      // Write to temp file and share
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(content);

      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Export: ${_quiz.title}');
    } catch (e) {
      if (mounted) {
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

// ─── Settings Panel ───
class _SettingsPanel extends StatelessWidget {
  final QuizSettings settings;
  final ValueChanged<QuizSettings> onChanged;

  const _SettingsPanel({required this.settings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          // Timer mode
          _SettingsRow(
            icon: Icons.timer_outlined,
            label: 'Timer Mode',
            child: SegmentedButton<TimerMode>(
              segments: const [
                ButtonSegment(
                  value: TimerMode.perQuestion,
                  label: Text('Per Question'),
                ),
                ButtonSegment(value: TimerMode.totalQuiz, label: Text('Total')),
              ],
              selected: {settings.timerMode},
              onSelectionChanged: (value) {
                onChanged(settings.copyWith(timerMode: value.first));
              },
              style: ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          ),
          const SizedBox(height: 16),
          // Time limit
          _SettingsRow(
            icon: Icons.hourglass_bottom_rounded,
            label: 'Time Limit',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_rounded),
                  onPressed: settings.defaultTimeLimitSec > 5
                      ? () => onChanged(
                          settings.copyWith(
                            defaultTimeLimitSec:
                                settings.defaultTimeLimitSec - 5,
                          ),
                        )
                      : null,
                  iconSize: 18,
                ),
                Text(
                  '${settings.defaultTimeLimitSec}s',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppTheme.gold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => onChanged(
                    settings.copyWith(
                      defaultTimeLimitSec: settings.defaultTimeLimitSec + 5,
                    ),
                  ),
                  iconSize: 18,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Scoring mode
          _SettingsRow(
            icon: Icons.emoji_events_outlined,
            label: 'Scoring',
            child: DropdownButton<ScoringMode>(
              value: settings.scoringMode,
              underline: const SizedBox(),
              dropdownColor: AppTheme.surfaceLight,
              items: const [
                DropdownMenuItem(
                  value: ScoringMode.standard,
                  child: Text('Standard'),
                ),
                DropdownMenuItem(
                  value: ScoringMode.speedBonus,
                  child: Text('Speed Bonus'),
                ),
                DropdownMenuItem(
                  value: ScoringMode.streakMultiplier,
                  child: Text('Streak + Speed'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onChanged(settings.copyWith(scoringMode: value));
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          // Shuffle toggles
          SwitchListTile(
            title: const Text('Shuffle Questions'),
            value: settings.shuffleQuestions,
            onChanged: (v) => onChanged(settings.copyWith(shuffleQuestions: v)),
            dense: true,
            activeThumbColor: AppTheme.gold,
          ),
          SwitchListTile(
            title: const Text('Shuffle Options'),
            value: settings.shuffleOptions,
            onChanged: (v) => onChanged(settings.copyWith(shuffleOptions: v)),
            dense: true,
            activeThumbColor: AppTheme.gold,
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        child,
      ],
    );
  }
}

// ─── Question Tile ───
class _QuestionTile extends StatelessWidget {
  final int index;
  final Question question;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _QuestionTile({
    super.key,
    required this.index,
    required this.question,
    required this.onTap,
    required this.onDelete,
  });

  String get _typeLabel {
    switch (question.type) {
      case QuestionType.singleChoice:
        return 'MCQ';
      case QuestionType.multipleChoice:
        return 'Multi';
      case QuestionType.trueFalse:
        return 'T/F';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.gold.withValues(alpha: 0.15),
          foregroundColor: AppTheme.gold,
          child: Text('${index + 1}'),
        ),
        title: Text(
          question.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$_typeLabel · ${question.options.length} options',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
          onPressed: onDelete,
          color: AppTheme.error.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
