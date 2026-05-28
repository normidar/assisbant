import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterapptemp/src/remote/client/remote_discovery_service.dart';
import 'package:flutterapptemp/src/remote/client/remote_client_service.dart';
import 'package:flutterapptemp/src/state/mobile/remote_connection_notifier.dart';

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '8765');
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(remoteConnectionProvider.notifier).startScan();
    });
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  Future<void> _connectTo(DiscoveredHost host) async {
    setState(() => _connecting = true);
    final ok =
        await ref.read(remoteConnectionProvider.notifier).connect(host);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection failed')),
      );
    }
    if (mounted) setState(() => _connecting = false);
  }

  Future<void> _connectManual() async {
    final host = _hostCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim()) ?? 8765;
    if (host.isEmpty) return;
    setState(() => _connecting = true);
    final ok = await ref
        .read(remoteConnectionProvider.notifier)
        .connectManual(host, port);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection failed')),
      );
    }
    if (mounted) setState(() => _connecting = false);
  }

  @override
  Widget build(BuildContext context) {
    final connState = ref.watch(remoteConnectionProvider);
    final isConnecting = connState.status == ConnectionStatus.connecting;
    final busy = _connecting || isConnecting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Mac'),
        actions: [
          if (connState.isScanning)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () =>
                  ref.read(remoteConnectionProvider.notifier).startScan(),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Discovered hosts
          if (connState.discoveredHosts.isNotEmpty) ...[
            const _SectionHeader(title: 'Discovered on network'),
            ...connState.discoveredHosts.map(
              (host) => _HostTile(
                host: host,
                onTap: busy ? null : () => _connectTo(host),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Manual entry
          const _SectionHeader(title: 'Manual connection'),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _hostCtrl,
                    decoration: const InputDecoration(
                      labelText: 'IP address',
                      hintText: '192.168.1.100',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _portCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => busy ? null : _connectManual(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: busy ? null : _connectManual,
                      child: busy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Connect'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          Text(
            'Make sure the Mac app has "Remote Connection" enabled in Settings, and both devices are on the same WiFi.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: Colors.grey.shade600),
      ),
    );
  }
}

class _HostTile extends StatelessWidget {
  const _HostTile({required this.host, required this.onTap});
  final DiscoveredHost host;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.computer_rounded),
        title: Text(host.name),
        subtitle: Text('${host.host}:${host.port}'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
