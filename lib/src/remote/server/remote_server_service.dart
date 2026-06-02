import 'dart:async';
import 'dart:io';

import 'package:assibant/src/data/database/prompt_status.dart';
import 'package:assibant/src/remote/remote_protocol.dart';
import 'package:assibant/src/remote/server/remote_command_handler.dart';
import 'package:assibant/src/state/exec_notifier.dart';
import 'package:assibant/src/state/prompt_notifier.dart';
import 'package:assibant/src/state/ui_providers.dart';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RemoteServerState {
  const RemoteServerState({
    this.isRunning = false,
    this.port = 8765,
    this.clientCount = 0,
    this.errorMessage,
  });

  final bool isRunning;
  final int port;
  final int clientCount;
  final String? errorMessage;

  RemoteServerState copyWith({
    bool? isRunning,
    int? port,
    int? clientCount,
    String? errorMessage,
    bool clearError = false,
  }) =>
      RemoteServerState(
        isRunning: isRunning ?? this.isRunning,
        port: port ?? this.port,
        clientCount: clientCount ?? this.clientCount,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

final remoteServerProvider =
    NotifierProvider<RemoteServerNotifier, RemoteServerState>(
  RemoteServerNotifier.new,
);

class RemoteServerNotifier extends Notifier<RemoteServerState> {
  HttpServer? _server;
  BonsoirBroadcast? _bonsoirBroadcast;
  final Set<WebSocketChannel> _clients = {};

  @override
  RemoteServerState build() {
    // Broadcast exec state changes to all connected clients
    ref.listen(execNotifierProvider, (prev, next) {
      _broadcast(buildStateMsg(next));

      // Stream incremental output to clients. ExecState accumulates the
      // running prompt's output, so broadcast only the newly-appended delta.
      // Skip when the prompt changed (the buffer still holds the previous
      // prompt's text) or when it was reset (next shorter than prev).
      final id = next.currentPromptId;
      final prevOutput = prev?.currentOutput ?? '';
      if (id != null &&
          prev?.currentPromptId == id &&
          next.currentOutput.length > prevOutput.length) {
        final delta = next.currentOutput.substring(prevOutput.length);
        if (delta.isNotEmpty) _broadcast(buildOutputMsg(id, delta));
      }
    });

    // Broadcast prompt list changes to all connected clients
    ref.listen(promptListNotifierProvider, (prev, next) {
      next.whenData((prompts) {
        _broadcast(buildPromptListMsg(prompts));

        // Detect newly completed prompts and broadcast notification
        final prevPrompts = prev?.value;
        if (prevPrompts != null) {
          final prevById = {for (final p in prevPrompts) p.id: p.status};
          for (final p in prompts) {
            final prevStatus = prevById[p.id];
            if (prevStatus != null &&
                prevStatus != PromptStatus.done &&
                prevStatus != PromptStatus.failed &&
                (p.status == PromptStatus.done ||
                    p.status == PromptStatus.failed)) {
              broadcastNotification(p.content, p.output ?? '');
            }
          }
        }
      });
    });

    // Auto start/stop when setting changes
    ref.listen(settingsStateProvider, (prev, next) {
      final portChanged = prev?.remotePort != next.remotePort;
      final enabledChanged = prev?.remoteEnabled != next.remoteEnabled;
      if (enabledChanged || (next.remoteEnabled && portChanged)) {
        if (next.remoteEnabled) {
          _stop().then((_) => _start(next.remotePort));
        } else {
          _stop();
        }
      }
    });

    ref.onDispose(_stop);

    // Auto-start if enabled in saved settings
    final settings = ref.read(settingsStateProvider);
    if (settings.remoteEnabled) {
      Future.microtask(() => _start(settings.remotePort));
    }

    return const RemoteServerState();
  }

  Future<void> _start(int port) async {
    if (_server != null) return;
    try {
      final handler = webSocketHandler(_onClientConnected);
      _server = await shelf_io.serve(handler, '0.0.0.0', port);

      final service = BonsoirService(
        name: 'assisbant',
        type: '_assisbant._tcp',
        port: port,
      );
      _bonsoirBroadcast = BonsoirBroadcast(service: service);
      await _bonsoirBroadcast!.ready;
      await _bonsoirBroadcast!.start();

      state = state.copyWith(isRunning: true, port: port, clearError: true);
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        errorMessage: 'Failed to start server: $e',
      );
    }
  }

  Future<void> _stop() async {
    for (final client in List.of(_clients)) {
      await client.sink.close();
    }
    _clients.clear();
    await _server?.close(force: true);
    await _bonsoirBroadcast?.stop();
    _server = null;
    _bonsoirBroadcast = null;
    if (state.isRunning) {
      state = state.copyWith(isRunning: false, clientCount: 0);
    }
  }

  void _onClientConnected(WebSocketChannel channel) {
    _clients.add(channel);
    state = state.copyWith(clientCount: _clients.length);

    // Send current state to new client immediately
    _sendTo(channel, buildStateMsg(ref.read(execNotifierProvider)));
    ref.read(promptListNotifierProvider).whenData(
          (prompts) => _sendTo(channel, buildPromptListMsg(prompts)),
        );

    channel.stream.listen(
      (message) {
        final cmd = decodeMsg(message as String);
        if (cmd != null) RemoteCommandHandler.handle(ref, cmd);
      },
      onDone: () {
        _clients.remove(channel);
        state = state.copyWith(clientCount: _clients.length);
      },
      onError: (_) {
        _clients.remove(channel);
        state = state.copyWith(clientCount: _clients.length);
      },
    );
  }

  void _broadcast(Map<String, dynamic> message) {
    final json = encodeMsg(message);
    final dead = <WebSocketChannel>[];
    for (final client in _clients) {
      try {
        client.sink.add(json);
      } catch (_) {
        dead.add(client);
      }
    }
    for (final c in dead) {
      _clients.remove(c);
    }
    if (dead.isNotEmpty) {
      state = state.copyWith(clientCount: _clients.length);
    }
  }

  void _sendTo(WebSocketChannel channel, Map<String, dynamic> message) {
    try {
      channel.sink.add(encodeMsg(message));
    } catch (_) {}
  }

  void broadcastNotification(String title, String body) {
    _broadcast(buildNotificationMsg(title, body));
  }
}
