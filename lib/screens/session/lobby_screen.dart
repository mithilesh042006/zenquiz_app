import 'dart:async'; // ignore: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/session.dart';
import '../../models/participant.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/server_provider.dart';
import '../../services/server_service.dart';
import '../../services/network_service.dart';
import '../../theme/app_theme.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  final String quizId;
  const LobbyScreen({super.key, required this.quizId});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen>
    with SingleTickerProviderStateMixin {
  ServerService? _serverService;
  final NetworkService _networkService = NetworkService();
  bool _isLoading = true;
  String? _error;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startServer());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _serverService?.stop();
    super.dispose();
  }

  Future<void> _startServer() async {
    try {
      final quiz = ref.read(quizListProvider.notifier).getQuiz(widget.quizId);
      if (quiz == null) {
        setState(() {
          _error = 'Quiz not found';
          _isLoading = false;
        });
        return;
      }

      // Create session
      final session = Session.fromQuiz(quiz);
      ref.read(sessionProvider.notifier).startSession(session);

      // Detect IP
      final ip = await _networkService.getWifiIP();
      if (ip == null) {
        setState(() {
          _error =
              'Could not detect network IP. Ensure you are connected to Wi-Fi.';
          _isLoading = false;
        });
        return;
      }

      // Start server
      _serverService = ServerService(port: 8080);
      _serverService!.onParticipantJoin = _onParticipantJoin;
      _serverService!.onParticipantLeave = _onParticipantLeave;
      await _serverService!.start();

      ref.read(serverProvider.notifier).setRunning(ip, 8080);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to start server: $e';
        _isLoading = false;
      });
    }
  }

  void _onParticipantJoin(String participantId, String teamName) {
    ref
        .read(sessionProvider.notifier)
        .addParticipant(Participant(id: participantId, teamName: teamName));
    setState(() {});
  }

  void _onParticipantLeave(String participantId) {
    ref
        .read(sessionProvider.notifier)
        .setParticipantConnected(participantId, false);
    setState(() {});
  }

  void _startQuiz() {
    final session = ref.read(sessionProvider);
    if (session == null || session.participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wait for at least one participant')),
      );
      return;
    }
    context.go('/session/control');
  }

  @override
  Widget build(BuildContext context) {
    final serverState = ref.watch(serverProvider);
    final session = ref.watch(sessionProvider);

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.gold),
              const SizedBox(height: 16),
              Text(
                'Starting server...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppTheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(session?.quizTitle ?? 'Lobby'),
        actions: [
          TextButton(
            onPressed: () {
              _serverService?.stop();
              ref.read(serverProvider.notifier).setStopped();
              ref.read(sessionProvider.notifier).clearSession();
              context.pop();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // ─── QR Code ───
              Expanded(
                flex: 3,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    child: QrImageView(
                      data: serverState.joinUrl ?? '',
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF0A0A0A),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // ─── Join URL ───
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.surfaceLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      color: AppTheme.gold,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      serverState.joinUrl ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.gold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // ─── Participant Counter ───
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(
                        alpha: 0.05 + (_pulseController.value * 0.05),
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: AppTheme.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_rounded, color: AppTheme.gold),
                        const SizedBox(width: 12),
                        Text(
                          '${session?.participantCount ?? 0} participants joined',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              // ─── Participant Names ───
              if (session != null && session.participants.isNotEmpty)
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    itemCount: session.participants.length,
                    itemBuilder: (context, index) {
                      final p = session.participants[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.gold.withValues(
                            alpha: 0.15,
                          ),
                          foregroundColor: AppTheme.gold,
                          radius: 16,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        title: Text(p.teamName),
                        trailing: Icon(
                          Icons.circle,
                          size: 10,
                          color: p.isConnected
                              ? AppTheme.correct
                              : AppTheme.textDim,
                        ),
                        dense: true,
                      );
                    },
                  ),
                )
              else
                const Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'Scan the QR code to join...',
                      style: TextStyle(color: AppTheme.textDim),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // ─── Start Button ───
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (session?.participantCount ?? 0) > 0
                      ? _startQuiz
                      : null,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Quiz'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
