import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/question.dart';
import '../../providers/quiz_provider.dart';
import '../../theme/app_theme.dart';

class QuestionEditorScreen extends ConsumerStatefulWidget {
  final String quizId;
  final String? questionId;

  const QuestionEditorScreen({
    super.key,
    required this.quizId,
    this.questionId,
  });

  @override
  ConsumerState<QuestionEditorScreen> createState() =>
      _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends ConsumerState<QuestionEditorScreen> {
  late TextEditingController _questionController;
  late List<TextEditingController> _optionControllers;
  QuestionType _type = QuestionType.singleChoice;
  List<int> _correctIndices = [0];
  int _timeLimitSeconds = 0;
  bool _isNew = true;
  String? _questionId;
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController();
    _optionControllers = List.generate(4, (_) => TextEditingController());
    _loadExisting();
  }

  void _loadExisting() {
    if (widget.questionId != null) {
      final quiz = ref.read(quizListProvider.notifier).getQuiz(widget.quizId);
      if (quiz != null) {
        try {
          final question = quiz.questions.firstWhere(
            (q) => q.id == widget.questionId,
          );
          _questionId = question.id;
          _questionController.text = question.text;
          _type = question.type;
          _correctIndices = List.from(question.correctIndices);
          _timeLimitSeconds = question.timeLimitSeconds;
          _imageBase64 = question.imageBase64;
          _isNew = false;

          // Set up option controllers
          _optionControllers = List.generate(
            question.options.length < 2 ? 4 : question.options.length,
            (i) => TextEditingController(
              text: i < question.options.length ? question.options[i] : '',
            ),
          );
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Add Question' : 'Edit Question'),
        actions: [
          TextButton.icon(
            onPressed: _saveQuestion,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Done'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Question Type ───
            Text(
              'Question Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<QuestionType>(
              segments: const [
                ButtonSegment(
                  value: QuestionType.singleChoice,
                  label: Text('Single'),
                  icon: Icon(Icons.radio_button_checked, size: 16),
                ),
                ButtonSegment(
                  value: QuestionType.multipleChoice,
                  label: Text('Multiple'),
                  icon: Icon(Icons.check_box, size: 16),
                ),
                ButtonSegment(
                  value: QuestionType.trueFalse,
                  label: Text('T/F'),
                  icon: Icon(Icons.swap_horiz, size: 16),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (value) {
                setState(() {
                  _type = value.first;
                  if (_type == QuestionType.trueFalse) {
                    _optionControllers = [
                      TextEditingController(text: 'True'),
                      TextEditingController(text: 'False'),
                    ];
                    _correctIndices = [0];
                  } else if (_optionControllers.length < 4) {
                    while (_optionControllers.length < 4) {
                      _optionControllers.add(TextEditingController());
                    }
                  }
                });
              },
            ),
            const SizedBox(height: 24),

            // ─── Question Text ───
            Text('Question', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _questionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter your question...',
              ),
            ),
            const SizedBox(height: 24),

            // ─── Question Image (optional) ───
            Text(
              'Image (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_imageBase64 != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: Image.memory(
                      base64Decode(_imageBase64!),
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _imageBase64 = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ] else ...[
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.surfaceLight),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_rounded,
                        size: 32,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap to add image',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),

            // ─── Options ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Options', style: Theme.of(context).textTheme.titleMedium),
                if (_type != QuestionType.trueFalse &&
                    _optionControllers.length < 6)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _optionControllers.add(TextEditingController());
                      });
                    },
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Add option',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_optionControllers.length, (index) {
              final isCorrect = _correctIndices.contains(index);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    // Correct answer toggle
                    GestureDetector(
                      onTap: () => _toggleCorrect(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? AppTheme.correct.withValues(alpha: 0.2)
                              : AppTheme.surfaceLight,
                          shape: _type == QuestionType.multipleChoice
                              ? BoxShape.rectangle
                              : BoxShape.circle,
                          borderRadius: _type == QuestionType.multipleChoice
                              ? BorderRadius.circular(6)
                              : null,
                          border: Border.all(
                            color: isCorrect
                                ? AppTheme.correct
                                : AppTheme.textDim,
                            width: 2,
                          ),
                        ),
                        child: isCorrect
                            ? const Icon(
                                Icons.check,
                                size: 18,
                                color: AppTheme.correct,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Option text
                    Expanded(
                      child: TextField(
                        controller: _optionControllers[index],
                        enabled: _type != QuestionType.trueFalse,
                        decoration: InputDecoration(
                          hintText: 'Option ${String.fromCharCode(65 + index)}',
                        ),
                      ),
                    ),
                    // Remove option button
                    if (_type != QuestionType.trueFalse &&
                        _optionControllers.length > 2)
                      IconButton(
                        onPressed: () => _removeOption(index),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: AppTheme.textDim,
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // ─── Time Limit ───
            Text(
              'Per-Question Timer Override',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Set to 0 to use the quiz default',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: _timeLimitSeconds > 0
                      ? () => setState(() => _timeLimitSeconds -= 5)
                      : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                Text(
                  _timeLimitSeconds == 0 ? 'Default' : '${_timeLimitSeconds}s',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppTheme.gold),
                ),
                IconButton(
                  onPressed: () => setState(() => _timeLimitSeconds += 5),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleCorrect(int index) {
    setState(() {
      if (_type == QuestionType.multipleChoice) {
        if (_correctIndices.contains(index)) {
          if (_correctIndices.length > 1) {
            _correctIndices.remove(index);
          }
        } else {
          _correctIndices.add(index);
        }
      } else {
        _correctIndices = [index];
      }
    });
  }

  void _removeOption(int index) {
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
      _correctIndices.remove(index);
      _correctIndices = _correctIndices
          .map((i) => i > index ? i - 1 : i)
          .toList();
      if (_correctIndices.isEmpty) _correctIndices = [0];
    });
  }

  void _saveQuestion() {
    final text = _questionController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a question')));
      return;
    }

    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 2 options are required')),
      );
      return;
    }

    // Validate correct indices
    final validIndices = _correctIndices
        .where((i) => i < options.length)
        .toList();
    if (validIndices.isEmpty) validIndices.add(0);

    final question = Question(
      id: _questionId,
      text: text,
      options: options,
      correctIndices: validIndices,
      type: _type,
      timeLimitSeconds: _timeLimitSeconds,
      imageBase64: _imageBase64,
    );

    context.pop(question);
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.textDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: AppTheme.gold,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppTheme.gold,
              ),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 70,
    );

    if (picked == null) return;

    final bytes = await File(picked.path).readAsBytes();
    setState(() {
      _imageBase64 = base64Encode(bytes);
    });
  }
}
