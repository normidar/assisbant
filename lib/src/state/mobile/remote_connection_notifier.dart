import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:assibant/src/data/services/notification_service.dart';
import 'package:assibant/src/remote/client/remote_client_service.dart';
import 'package:assibant/src/remote/client/remote_discovery_service.dart';
import 'package:assibant/src/remote/remote_protocol.dart';
import 'package:assibant/src/state/mobile/remote_exec_notifier.dart';
import 'package:assibant/src/state/mobile/remote_prompt_notifier.dart';

class RemoteConnectionState {
  const RemoteConnectionState({
    this.status = ConnectionStatus.disconnected,
    this.discoveredHosts = const [],
    this.connectedHost,
    this.isScanning = false,
  });

  final ConnectionStatus status;
  final List<DiscoveredHost> discoveredHosts;
  final DiscoveredHost? connectedHost;
  final bool isScanning;

  bool get isConnected => status == ConnectionStatus.connected;

  RemoteConnectionState copyWith({
    ConnectionStatus? status,
    List<DiscoveredHost>? discoveredHosts,
    DiscoveredHost? connectedHost,
    bool? isScanning,
    bool clearHost = false,
  }) =>
      RemoteConnectionState(
        status: status ?? this.status,
        discoveredHosts: discoveredHosts ?? this.discoveredHosts,
        connectedHost: clearHost ? null : (connectedHost ?? this.connectedHost),
        isScanning: isScanning ?? this.isScanning,
      );
}

final remoteConnectionProvider =
    NotifierProvider<RemoteConnectionNotifier, RemoteConnectionState>(
  RemoteConnectionNotifier.new,
);

class RemoteConnectionNotifier extends Notifier<RemoteConnectionState> {
  final _client = RemoteClientService();
  final _discovery = RemoteDiscoveryService();
  StreamSubscription<dynamic>? _statusSub;
  StreamSubscription<dynamic>? _messageSub;
  StreamSubscription<dynamic>? _discoverySub;

  @override
  RemoteConnectionState build() {
    ref.onDispose(() {
      _statusSub?.cancel();
      _messageSub?.cancel();
      _discoverySub?.cancel();
      _client.dispose();
      _discovery.dispose();
    });
    return const RemoteConnectionState();
  }

  Future<void> startScan() async {
    if (state.isScanning) return;
    state = state.copyWith(isScanning: true, discoveredHosts: []);
    _discoverySub?.cancel();
    _discoverySub = _discovery.hostsStream.listen((hosts) {
      state = state.copyWith(discoveredHosts: hosts);
    });
    await _discovery.start();
  }

  Future<void> stopScan() async {
    await _discovery.stop();
    _discoverySub?.cancel();
    _discoverySub = null;
    state = state.copyWith(isScanning: false);
  }

  Future<bool> connect(DiscoveredHost host) async {
    state = state.copyWith(status: ConnectionStatus.connecting);
    final ok = await _client.connect(host.host, host.port);
    if (!ok) {
      state = state.copyWith(status: ConnectionStatus.disconnected);
      return false;
    }

    state = state.copyWith(
      status: ConnectionStatus.connected,
      connectedHost: host,
    );

    _statusSub?.cancel();
    _statusSub = _client.statusStream.listen((s) {
      if (s == ConnectionStatus.disconnected) {
        state = state.copyWith(
          status: ConnectionStatus.disconnected,
          clearHost: true,
        );
      }
    });

    _messageSub?.cancel();
    _messageSub = _client.messageStream.listen(_onMessage);

    return true;
  }

  Future<bool> connectManual(String host, int port) async {
    return connect(DiscoveredHost(name: host, host: host, port: port));
  }

  Future<void> disconnect() async {
    await _client.disconnect();
    state = state.copyWith(
      status: ConnectionStatus.disconnected,
      clearHost: true,
    );
  }

  void sendCommand(Map<String, dynamic> cmd) => _client.send(cmd);

  void _onMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    switch (type) {
      case RemoteMsg.state:
        final data = msg['data'] as Map<String, dynamic>?;
        if (data != null) {
          ref.read(remoteExecProvider.notifier).update(data);
        }
      case RemoteMsg.promptList:
        final data = msg['data'] as List<dynamic>?;
        if (data != null) {
          ref.read(remotePromptProvider.notifier).update(
                data.cast<Map<String, dynamic>>(),
              );
        }
      case RemoteMsg.output:
        final promptId = msg['promptId'] as String?;
        final chunk = msg['chunk'] as String?;
        if (promptId != null && chunk != null) {
          ref.read(remoteExecProvider.notifier).appendOutput(promptId, chunk);
        }
      case RemoteMsg.notification:
        final title = msg['title'] as String?;
        final body = msg['body'] as String?;
        if (title != null && body != null) {
          final plugin = ref.read(localNotificationsProvider);
          showTaskCompletedNotification(plugin, title, body);
        }
    }
  }
}
