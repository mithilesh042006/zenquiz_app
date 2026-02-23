import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for server state.
final serverProvider = StateNotifierProvider<ServerNotifier, ServerState>((
  ref,
) {
  return ServerNotifier();
});

/// Holds server status information.
class ServerState {
  final bool isRunning;
  final String? ipAddress;
  final int port;
  final String? joinUrl;
  final String? error;

  const ServerState({
    this.isRunning = false,
    this.ipAddress,
    this.port = 8080,
    this.joinUrl,
    this.error,
  });

  ServerState copyWith({
    bool? isRunning,
    String? ipAddress,
    int? port,
    String? joinUrl,
    String? error,
  }) {
    return ServerState(
      isRunning: isRunning ?? this.isRunning,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      joinUrl: joinUrl ?? this.joinUrl,
      error: error,
    );
  }
}

/// Manages server start/stop state.
class ServerNotifier extends StateNotifier<ServerState> {
  ServerNotifier() : super(const ServerState());

  void setRunning(String ip, int port) {
    state = ServerState(
      isRunning: true,
      ipAddress: ip,
      port: port,
      joinUrl: 'http://$ip:$port',
    );
  }

  void setStopped() {
    state = const ServerState(isRunning: false);
  }

  void setError(String error) {
    state = state.copyWith(isRunning: false, error: error);
  }
}
