import 'dart:async';

import 'package:bonsoir/bonsoir.dart';

class DiscoveredHost {
  const DiscoveredHost({
    required this.name,
    required this.host,
    required this.port,
  });

  final String name;
  final String host;
  final int port;

  @override
  bool operator ==(Object other) =>
      other is DiscoveredHost && other.host == host && other.port == port;

  @override
  int get hashCode => Object.hash(host, port);
}

class RemoteDiscoveryService {
  BonsoirDiscovery? _discovery;
  final _hosts = <DiscoveredHost>{};
  final _controller = StreamController<List<DiscoveredHost>>.broadcast();

  Stream<List<DiscoveredHost>> get hostsStream => _controller.stream;
  List<DiscoveredHost> get currentHosts => List.unmodifiable(_hosts);

  Future<void> start() async {
    _discovery = BonsoirDiscovery(type: '_assisbant._tcp');
    await _discovery!.ready;

    _discovery!.eventStream!.listen((event) {
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
        event.service?.resolve(_discovery!.serviceResolver);
      } else if (event.type ==
          BonsoirDiscoveryEventType.discoveryServiceResolved) {
        final svc = event.service as ResolvedBonsoirService?;
        if (svc != null && svc.host != null) {
          _hosts.add(
            DiscoveredHost(
              name: svc.name,
              host: svc.host!,
              port: svc.port,
            ),
          );
          _controller.add(currentHosts);
        }
      } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
        final svc = event.service;
        if (svc != null) {
          _hosts.removeWhere((h) => h.name == svc.name);
          _controller.add(currentHosts);
        }
      }
    });

    await _discovery!.start();
  }

  Future<void> stop() async {
    await _discovery?.stop();
    _discovery = null;
    _hosts.clear();
    _controller.add(currentHosts);
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
