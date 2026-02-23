import 'dart:convert';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/quiz.dart';
import '../models/session.dart';

/// Provides local persistence for quizzes and sessions using Hive.
class StorageService {
  static const String _quizBoxName = 'quizzes';
  static const String _sessionHistoryBoxName = 'session_history';

  late Box<String> _quizBox;
  late Box<String> _sessionHistoryBox;

  /// Initialize Hive and open boxes.
  Future<void> init() async {
    await Hive.initFlutter();
    _quizBox = await Hive.openBox<String>(_quizBoxName);
    _sessionHistoryBox = await Hive.openBox<String>(_sessionHistoryBoxName);
  }

  // ─── Quiz CRUD ───

  /// Get all saved quizzes.
  List<Quiz> getAllQuizzes() {
    return _quizBox.values.map((jsonStr) {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Quiz.fromJson(map);
    }).toList();
  }

  /// Get a single quiz by ID.
  Quiz? getQuiz(String id) {
    final jsonStr = _quizBox.get(id);
    if (jsonStr == null) return null;
    return Quiz.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  /// Save or update a quiz.
  Future<void> saveQuiz(Quiz quiz) async {
    await _quizBox.put(quiz.id, jsonEncode(quiz.toJson()));
  }

  /// Delete a quiz by ID.
  Future<void> deleteQuiz(String id) async {
    await _quizBox.delete(id);
  }

  // ─── Session History ───

  /// Save a completed session.
  Future<void> saveSession(Session session) async {
    await _sessionHistoryBox.put(session.id, jsonEncode(session.toJson()));
  }

  /// Save session results as raw JSON.
  Future<void> saveSessionResult(
    String sessionId,
    Map<String, dynamic> data,
  ) async {
    await _sessionHistoryBox.put(sessionId, jsonEncode(data));
  }

  /// Get all session history as Session objects.
  List<Session> getSessionHistory() {
    return _sessionHistoryBox.values.map((jsonStr) {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Session.fromJson(map);
    }).toList();
  }

  /// Get all session history as raw maps.
  List<Map<String, dynamic>> getAllSessionHistory() {
    return _sessionHistoryBox.values.map((jsonStr) {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    }).toList();
  }

  /// Delete session history by ID.
  Future<void> deleteSessionResult(String sessionId) async {
    await _sessionHistoryBox.delete(sessionId);
  }
}
