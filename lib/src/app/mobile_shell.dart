import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:assibant/src/screens/mobile/connection_screen.dart';
import 'package:assibant/src/screens/mobile/remote_exec_screen.dart';
import 'package:assibant/src/screens/mobile/remote_prompts_screen.dart';
import 'package:assibant/src/state/mobile/remote_connection_notifier.dart';

class MobileShell extends ConsumerStatefulWidget {
  const MobileShell({super.key});

  @override
  ConsumerState<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends ConsumerState<MobileShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final connState = ref.watch(remoteConnectionProvider);

    if (!connState.isConnected) {
      return const ConnectionScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.computer_rounded, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                connState.connectedHost?.name ?? 'Mac',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.link_off_rounded),
            tooltip: 'Disconnect',
            onPressed: () =>
                ref.read(remoteConnectionProvider.notifier).disconnect(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          RemotePromptsScreen(),
          RemoteExecScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_rounded),
            label: 'Prompts',
          ),
          NavigationDestination(
            icon: Icon(Icons.terminal_rounded),
            label: 'Execution',
          ),
        ],
      ),
    );
  }
}
