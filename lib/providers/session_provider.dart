import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';
import '../models/participant.dart';

/// Provider for the current active session.
final sessionProvider = StateNotifierProvider<SessionNotifier, Session?>((ref) {
  return SessionNotifier();
});

/// Manages the live quiz session state.
class SessionNotifier extends StateNotifier<Session?> {
  SessionNotifier() : super(null);

  /// Start a new session.
  void startSession(Session session) {
    state = session;
  }

  /// End the current session.
  void endSession() {
    if (state == null) return;
    state!.status = SessionStatus.finished;
    state!.endedAt = DateTime.now();
    state = state; // Trigger rebuild
  }

  /// Clear the session.
  void clearSession() {
    state = null;
  }

  /// Add a participant.
  void addParticipant(Participant participant) {
    if (state == null) return;
    state!.participants.add(participant);
    _notify();
  }

  /// Remove a participant.
  void removeParticipant(String participantId) {
    if (state == null) return;
    state!.participants.removeWhere((p) => p.id == participantId);
    _notify();
  }

  /// Mark a participant as disconnected.
  void setParticipantConnected(String participantId, bool connected) {
    if (state == null) return;
    final p = state!.findParticipant(participantId);
    if (p != null) {
      p.isConnected = connected;
      _notify();
    }
  }

  /// Move to the next question.
  void nextQuestion() {
    if (state == null) return;
    state!.currentQuestionIndex++;
    state!.status = SessionStatus.playing;
    _notify();
  }

  /// Show question results.
  void showQuestionResults() {
    if (state == null) return;
    state!.status = SessionStatus.questionResults;
    _notify();
  }

  /// Show leaderboard.
  void showLeaderboard() {
    if (state == null) return;
    state!.status = SessionStatus.leaderboard;
    _notify();
  }

  /// Update session status.
  void setStatus(SessionStatus status) {
    if (state == null) return;
    state!.status = status;
    _notify();
  }

  /// Record an answer for a participant.
  void recordAnswer(String participantId, ParticipantAnswer answer) {
    if (state == null) return;
    final p = state!.findParticipant(participantId);
    if (p != null) {
      p.addAnswer(answer);
      _notify();
    }
  }

  void _notify() {
    state = state; // Trigger rebuild
  }
}
