import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionStatus { disconnected, connecting, connected }

class RemoteClientService {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  final _statusCtrl = StreamController<ConnectionStatus>.broadcast();
  final _messageCtrl = StreamController<Map<String, dynamic>>.broadcast();

  Stream<ConnectionStatus> get statusStream => _statusCtrl.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageCtrl.stream;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStatus get status => _status;

  Future<bool> connect(String host, int port) async {
    if (_status == ConnectionStatus.connected) return true;
    _updateStatus(ConnectionStatus.connecting);
    try {
      final uri = Uri.parse('ws://$host:$port');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _sub = _channel!.stream.listen(
        _onData,
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
      );
      _updateStatus(ConnectionStatus.connected);
      return true;
    } catch (_) {
      _updateStatus(ConnectionStatus.disconnected);
      return false;
    }
  }

  void send(Map<String, dynamic> cmd) {
    if (_status != ConnectionStatus.connected) return;
    try {
      _channel!.sink.add(jsonEncode(cmd));
    } catch (_) {}
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    await _channel?.sink.close();
    _sub = null;
    _channel = null;
    _updateStatus(ConnectionStatus.disconnected);
  }

  void _onData(dynamic data) {
    try {
      final msg = jsonDecode(data as String) as Map<String, dynamic>;
      _messageCtrl.add(msg);
    } catch (_) {}
  }

  void _onDisconnected() {
    _sub = null;
    _channel = null;
    _updateStatus(ConnectionStatus.disconnected);
  }

  void _updateStatus(ConnectionStatus s) {
    _status = s;
    _statusCtrl.add(s);
  }

  void dispose() {
    disconnect();
    _statusCtrl.close();
    _messageCtrl.close();
  }
}
