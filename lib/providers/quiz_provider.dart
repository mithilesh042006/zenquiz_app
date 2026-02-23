import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz.dart';
import '../services/storage_service.dart';

/// Provider for the storage service (singleton).
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Provider for the list of all quizzes.
final quizListProvider = StateNotifierProvider<QuizListNotifier, List<Quiz>>((
  ref,
) {
  final storage = ref.watch(storageServiceProvider);
  return QuizListNotifier(storage);
});

/// Manages the list of quizzes with CRUD operations.
class QuizListNotifier extends StateNotifier<List<Quiz>> {
  final StorageService _storage;

  QuizListNotifier(this._storage) : super([]) {
    _loadQuizzes();
  }

  void _loadQuizzes() {
    state = _storage.getAllQuizzes();
    // Sort by updatedAt descending (most recent first)
    state.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> addQuiz(Quiz quiz) async {
    await _storage.saveQuiz(quiz);
    _loadQuizzes();
  }

  Future<void> updateQuiz(Quiz quiz) async {
    await _storage.saveQuiz(quiz);
    _loadQuizzes();
  }

  Future<void> deleteQuiz(String id) async {
    await _storage.deleteQuiz(id);
    _loadQuizzes();
  }

  Quiz? getQuiz(String id) {
    try {
      return state.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async {
    _loadQuizzes();
  }
}
