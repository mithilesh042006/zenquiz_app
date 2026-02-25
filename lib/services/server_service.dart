import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';

/// Callback types for server events.
typedef OnParticipantJoin =
    void Function(String participantId, String teamName);
typedef OnParticipantLeave = void Function(String participantId);
typedef OnAnswerReceived =
    void Function(
      String participantId,
      String questionId,
      List<int> selectedIndices,
      int responseTimeMs,
    );

/// Manages the local HTTP + WebSocket server.
class ServerService {
  HttpServer? _server;
  final Map<String, WebSocketChannel> _clients = {};
  final Map<String, String> _participantNames = {}; // id -> teamName
  final int port;

  /// Stores the last broadcast state so reconnecting clients get caught up.
  Map<String, dynamic>? _lastBroadcastState;

  // Event callbacks
  OnParticipantJoin? onParticipantJoin;
  OnParticipantLeave? onParticipantLeave;
  OnAnswerReceived? onAnswerReceived;

  ServerService({this.port = 8080});

  bool get isRunning => _server != null;

  /// Start the server.
  Future<void> start() async {
    final wsHandler = webSocketHandler((WebSocketChannel ws) {
      String? participantId;

      ws.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String) as Map<String, dynamic>;
            final type = data['type'] as String?;

            switch (type) {
              case 'join':
                final teamName = data['teamName'] as String? ?? 'Unknown';
                final existingId = data['participantId'] as String?;

                // Check if this is a reconnection
                if (existingId != null &&
                    _participantNames.containsKey(existingId)) {
                  // Rejoin: reuse existing ID
                  participantId = existingId;
                  _clients[participantId!] = ws;

                  // Send back confirmation
                  ws.sink.add(
                    jsonEncode({
                      'type': 'joined',
                      'participantId': participantId,
                      'reconnected': true,
                    }),
                  );

                  // Send current state so participant catches up
                  if (_lastBroadcastState != null) {
                    ws.sink.add(jsonEncode(_lastBroadcastState!));
                  }
                } else {
                  // New participant
                  participantId = const Uuid().v4();
                  _clients[participantId!] = ws;
                  _participantNames[participantId!] = teamName;
                  onParticipantJoin?.call(participantId!, teamName);

                  // Send back the participant ID
                  ws.sink.add(
                    jsonEncode({
                      'type': 'joined',
                      'participantId': participantId,
                      'reconnected': false,
                    }),
                  );
                }
                break;

              case 'answer':
                if (participantId != null) {
                  final questionId = data['questionId'] as String;
                  final selectedIndices = (data['selectedIndices'] as List)
                      .map((e) => e as int)
                      .toList();
                  final responseTimeMs = data['responseTimeMs'] as int;
                  onAnswerReceived?.call(
                    participantId!,
                    questionId,
                    selectedIndices,
                    responseTimeMs,
                  );
                }
                break;
            }
          } catch (e) {
            // Ignore malformed messages
          }
        },
        onDone: () {
          if (participantId != null) {
            _clients.remove(participantId);
            // Don't remove from _participantNames — they might reconnect
            // Don't call onParticipantLeave — keep them in the session
          }
        },
        onError: (error) {
          if (participantId != null) {
            _clients.remove(participantId);
          }
        },
      );
    });

    // Build handler pipeline
    final handler = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addHandler((shelf.Request request) {
          // WebSocket upgrade
          if (request.url.path == 'ws') {
            return wsHandler(request);
          }

          // API endpoints
          if (request.url.path == 'api/health') {
            return shelf.Response.ok(
              jsonEncode({'status': 'ok'}),
              headers: {'Content-Type': 'application/json'},
            );
          }

          // Serve the web client
          return _serveWebClient(request);
        });

    try {
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
    } catch (_) {
      // Fallback: try binding to specific interface (needed on some Android devices)
      try {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
        );
        InternetAddress? bindAddress;
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            if (!addr.isLoopback) {
              bindAddress = addr;
              break;
            }
          }
          if (bindAddress != null) break;
        }
        _server = await shelf_io.serve(
          handler,
          bindAddress ?? InternetAddress.loopbackIPv4,
          port,
        );
      } catch (e) {
        rethrow;
      }
    }
    _server!.autoCompress = true;
  }

  /// Serve the participant web client files.
  shelf.Response _serveWebClient(shelf.Request request) {
    final path = request.url.path;

    if (path.isEmpty || path == '/' || path == 'index.html') {
      return shelf.Response.ok(
        _webClientHtml,
        headers: {'Content-Type': 'text/html'},
      );
    }
    if (path == 'style.css') {
      return shelf.Response.ok(
        _webClientCss,
        headers: {'Content-Type': 'text/css'},
      );
    }
    if (path == 'app.js') {
      return shelf.Response.ok(
        _webClientJs,
        headers: {'Content-Type': 'application/javascript'},
      );
    }

    return shelf.Response.notFound('Not found');
  }

  /// Stop the server.
  Future<void> stop() async {
    for (final client in _clients.values) {
      await client.sink.close();
    }
    _clients.clear();
    _participantNames.clear();
    _lastBroadcastState = null;
    await _server?.close(force: true);
    _server = null;
  }

  /// Broadcast a message to all connected clients.
  /// Also stores the message as current state for reconnecting clients.
  void broadcast(Map<String, dynamic> message) {
    // Store the last broadcast state for reconnection
    _lastBroadcastState = Map.from(message);

    final encoded = jsonEncode(message);
    for (final client in _clients.values) {
      try {
        client.sink.add(encoded);
      } catch (_) {}
    }
  }

  /// Send a message to a specific client.
  void sendTo(String participantId, Map<String, dynamic> message) {
    final client = _clients[participantId];
    if (client != null) {
      try {
        client.sink.add(jsonEncode(message));
      } catch (_) {}
    }
  }

  /// Get the number of connected clients.
  int get connectedCount => _clients.length;

  // ─── Embedded Web Client ───

  static const String _webClientHtml = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ZenQuiz</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <div id="app">
    <div id="join-screen" class="screen active">
      <div class="logo">⚡ ZenQuiz</div>
      <p class="subtitle">Enter your team name to join</p>
      <input type="text" id="team-name" placeholder="Team Name" maxlength="30" autocomplete="off">
      <button id="join-btn" onclick="joinGame()">Join Quiz</button>
    </div>
    <div id="lobby-screen" class="screen">
      <div class="logo">⚡ ZenQuiz</div>
      <p class="subtitle">Waiting for the host to start...</p>
      <div class="loader"></div>
      <p id="team-display" class="team-name"></p>
    </div>
    <div id="question-screen" class="screen">
      <div class="timer-bar"><div id="timer-fill" class="timer-fill"></div></div>
      <div id="question-number" class="q-number"></div>
      <div id="question-text" class="q-text"></div>
      <img id="question-image" class="q-image" style="display:none" />
      <div id="options" class="options"></div>
    </div>
    <div id="feedback-screen" class="screen">
      <div id="feedback-icon" class="feedback-icon"></div>
      <div id="feedback-text" class="feedback-text"></div>
      <div id="points-earned" class="points"></div>
      <p class="subtitle">Waiting for next question...</p>
    </div>
    <div id="leaderboard-screen" class="screen">
      <h2>🏆 Leaderboard</h2>
      <div id="leaderboard-list" class="leaderboard-list"></div>
    </div>
    <div id="final-screen" class="screen">
      <h2>🎉 Quiz Complete!</h2>
      <div id="final-rank" class="final-rank"></div>
      <div id="final-score" class="final-score"></div>
    </div>
    <div id="disconnected-screen" class="screen">
      <div class="logo">⚡ ZenQuiz</div>
      <p class="subtitle">Connection lost. Reconnecting...</p>
      <div class="loader"></div>
    </div>
  </div>
  <script src="app.js"></script>
</body>
</html>
''';

  static const String _webClientCss = '''
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
  font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
  background: #0A0A0A;
  color: #FFFFFF;
  min-height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
}
#app { width: 100%; max-width: 500px; padding: 20px; }
.screen { display: none; flex-direction: column; align-items: center; gap: 16px; }
.screen.active { display: flex; }
.logo { font-size: 2.5rem; font-weight: 700; color: #FFD700; }
.subtitle { color: #B0B0B0; font-size: 1rem; }
input {
  width: 100%; padding: 14px 18px; border-radius: 12px;
  border: 2px solid #2A2A2A; background: #1A1A1A; color: #FFF;
  font-size: 1.1rem; outline: none; transition: border-color 0.2s;
}
input:focus { border-color: #FFD700; }
button {
  width: 100%; padding: 14px; border-radius: 12px;
  background: #FFD700; color: #0A0A0A; font-weight: 700;
  font-size: 1.1rem; border: none; cursor: pointer;
  transition: transform 0.15s, opacity 0.15s;
}
button:active { transform: scale(0.97); }
button:disabled { opacity: 0.5; cursor: not-allowed; }
.team-name { color: #FFD700; font-size: 1.2rem; font-weight: 600; }
.loader {
  width: 40px; height: 40px; border: 3px solid #2A2A2A;
  border-top-color: #FFD700; border-radius: 50%;
  animation: spin 0.8s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }
.timer-bar { width: 100%; height: 6px; background: #2A2A2A; border-radius: 3px; overflow: hidden; }
.timer-fill { height: 100%; background: #FFD700; border-radius: 3px; transition: width 0.1s linear; width: 100%; }
.q-number { color: #B0B0B0; font-size: 0.9rem; }
.q-text { font-size: 1.3rem; font-weight: 600; text-align: center; padding: 16px 0; }
.q-image { max-width: 100%; max-height: 220px; border-radius: 12px; object-fit: contain; margin-bottom: 8px; }
.options { width: 100%; display: flex; flex-direction: column; gap: 10px; }
.option-btn {
  width: 100%; padding: 14px 18px; border-radius: 12px;
  background: #1A1A1A; border: 2px solid #2A2A2A; color: #FFF;
  font-size: 1rem; cursor: pointer; text-align: left;
  transition: all 0.2s;
}
.option-btn:hover { border-color: #FFD700; background: #222; }
.option-btn.selected { border-color: #FFD700; background: rgba(255,215,0,0.15); }
.option-btn.correct { border-color: #00E676; background: rgba(0,230,118,0.15); }
.option-btn.incorrect { border-color: #FF5252; background: rgba(255,82,82,0.15); }
.feedback-icon { font-size: 4rem; }
.feedback-text { font-size: 1.5rem; font-weight: 600; }
.points { color: #FFD700; font-size: 1.2rem; }
.leaderboard-list { width: 100%; }
.lb-entry {
  display: flex; align-items: center; padding: 12px 16px;
  background: #1A1A1A; border-radius: 12px; margin-bottom: 8px;
}
.lb-rank { width: 30px; font-weight: 700; color: #FFD700; }
.lb-name { flex: 1; }
.lb-score { font-weight: 700; color: #FFD700; }
.final-rank { font-size: 3rem; font-weight: 700; color: #FFD700; }
.final-score { font-size: 1.2rem; color: #B0B0B0; }
''';

  static const String _webClientJs = r'''
let ws;
let participantId = null;
let currentQuestionId = null;
let timerInterval = null;
let startTime = null;
let teamName = null;
let reconnectAttempts = 0;
let intentionalClose = false;
let currentScreen = 'join-screen';

// ─── Session Persistence ───
function saveSession() {
  if (participantId && teamName) {
    localStorage.setItem('zenquiz_session', JSON.stringify({
      participantId,
      teamName,
      host: location.host,
    }));
  }
}

function loadSession() {
  try {
    const saved = localStorage.getItem('zenquiz_session');
    if (!saved) return null;
    const session = JSON.parse(saved);
    // Only restore if same host
    if (session.host === location.host) return session;
    localStorage.removeItem('zenquiz_session');
  } catch (_) {}
  return null;
}

function clearSession() {
  localStorage.removeItem('zenquiz_session');
  participantId = null;
  teamName = null;
}

// ─── Screen Management ───
function showScreen(id) {
  currentScreen = id;
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  document.getElementById(id).classList.add('active');
}

// ─── Connection ───
function connect() {
  if (ws && ws.readyState === WebSocket.OPEN) return;

  const proto = location.protocol === 'https:' ? 'wss:' : 'ws:';
  ws = new WebSocket(`${proto}//${location.host}/ws`);

  ws.onopen = () => {
    reconnectAttempts = 0;
    // Send join with existing participantId for reconnection
    ws.send(JSON.stringify({
      type: 'join',
      teamName: teamName,
      participantId: participantId,
    }));
  };

  ws.onmessage = (event) => {
    try {
      const msg = JSON.parse(event.data);
      handleMessage(msg);
    } catch (_) {}
  };

  ws.onclose = () => {
    if (intentionalClose) return;
    // Show disconnected screen only if we were in an active session
    if (participantId && currentScreen !== 'join-screen') {
      showScreen('disconnected-screen');
    }
    // Auto-reconnect with exponential backoff
    const delay = Math.min(1000 * Math.pow(2, reconnectAttempts), 10000);
    reconnectAttempts++;
    setTimeout(() => {
      if (participantId) connect();
    }, delay);
  };

  ws.onerror = () => {};
}

// ─── Join ───
function joinGame() {
  const nameInput = document.getElementById('team-name').value.trim();
  if (!nameInput) return;

  teamName = nameInput;
  document.getElementById('team-display').textContent = teamName;
  showScreen('lobby-screen');
  connect();
}

// ─── Message Handling ───
function handleMessage(msg) {
  switch (msg.type) {
    case 'joined':
      participantId = msg.participantId;
      saveSession();
      if (!msg.reconnected) {
        // Fresh join — show lobby
        document.getElementById('team-display').textContent = teamName;
        showScreen('lobby-screen');
      }
      // If reconnected, server will send current state next
      break;

    case 'question':
      showQuestion(msg);
      break;

    case 'answer_result':
      showFeedback(msg);
      break;

    case 'leaderboard':
      showLeaderboard(msg);
      break;

    case 'quiz_end':
      showFinalResults(msg);
      break;
  }
}

// ─── Question ───
function showQuestion(msg) {
  currentQuestionId = msg.questionId;
  startTime = Date.now();

  document.getElementById('question-number').textContent =
    `Question ${msg.questionNumber} of ${msg.totalQuestions}`;
  document.getElementById('question-text').textContent = msg.text;

  // Show image if present
  const img = document.getElementById('question-image');
  if (msg.imageBase64) {
    img.src = 'data:image/jpeg;base64,' + msg.imageBase64;
    img.style.display = 'block';
  } else {
    img.src = '';
    img.style.display = 'none';
  }

  const optionsDiv = document.getElementById('options');
  optionsDiv.innerHTML = '';
  msg.options.forEach((opt, i) => {
    const btn = document.createElement('button');
    btn.className = 'option-btn';
    btn.textContent = opt;
    btn.onclick = () => submitAnswer(i);
    optionsDiv.appendChild(btn);
  });

  // Start timer
  const timeLimit = msg.timeLimitMs;
  const fill = document.getElementById('timer-fill');
  fill.style.width = '100%';
  clearInterval(timerInterval);
  timerInterval = setInterval(() => {
    const elapsed = Date.now() - startTime;
    const pct = Math.max(0, 1 - elapsed / timeLimit) * 100;
    fill.style.width = pct + '%';
    if (pct <= 0) {
      clearInterval(timerInterval);
      submitAnswer(-1); // timeout
    }
  }, 50);

  showScreen('question-screen');
}

// ─── Submit Answer ───
function submitAnswer(index) {
  clearInterval(timerInterval);
  const responseTimeMs = Date.now() - startTime;

  // Highlight selected
  const btns = document.querySelectorAll('.option-btn');
  btns.forEach((btn, i) => {
    btn.onclick = null;
    if (i === index) btn.classList.add('selected');
  });

  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify({
      type: 'answer',
      questionId: currentQuestionId,
      selectedIndices: index >= 0 ? [index] : [],
      responseTimeMs: responseTimeMs,
    }));
  }
}

// ─── Feedback ───
function showFeedback(msg) {
  const icon = document.getElementById('feedback-icon');
  const text = document.getElementById('feedback-text');
  const points = document.getElementById('points-earned');

  if (msg.isCorrect) {
    icon.textContent = '✅';
    text.textContent = 'Correct!';
    text.style.color = '#00E676';
  } else {
    icon.textContent = '❌';
    text.textContent = 'Wrong!';
    text.style.color = '#FF5252';
  }
  points.textContent = msg.points > 0 ? `+${msg.points} points` : '';

  showScreen('feedback-screen');
}

// ─── Leaderboard ───
function showLeaderboard(msg) {
  const list = document.getElementById('leaderboard-list');
  list.innerHTML = '';
  msg.entries.forEach((entry, i) => {
    const div = document.createElement('div');
    div.className = 'lb-entry';
    const isMe = entry.id === participantId;
    if (isMe) div.style.border = '1px solid #FFD700';
    div.innerHTML = `
      <span class="lb-rank">${i + 1}</span>
      <span class="lb-name">${entry.teamName}${isMe ? ' (You)' : ''}</span>
      <span class="lb-score">${entry.score}</span>
    `;
    list.appendChild(div);
  });
  showScreen('leaderboard-screen');
}

// ─── Final Results ───
function showFinalResults(msg) {
  document.getElementById('final-rank').textContent = `#${msg.rank}`;
  document.getElementById('final-score').textContent = `Score: ${msg.score}`;
  clearSession();
  showScreen('final-screen');
}

// ─── Enter key to join ───
document.getElementById('team-name').addEventListener('keypress', (e) => {
  if (e.key === 'Enter') joinGame();
});

// ─── Auto-reconnect on page load ───
(function init() {
  const session = loadSession();
  if (session) {
    participantId = session.participantId;
    teamName = session.teamName;
    document.getElementById('team-display').textContent = teamName;
    showScreen('lobby-screen');
    connect();
  }
})();
''';
}
