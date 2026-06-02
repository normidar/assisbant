import 'package:assibant/src/remote/remote_protocol.dart';
import 'package:assibant/src/screens/mobile/remote_prompt_form.dart';
import 'package:assibant/src/state/mobile/remote_connection_notifier.dart';
import 'package:assibant/src/state/mobile/remote_exec_notifier.dart';
import 'package:assibant/src/state/mobile/remote_prompt_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RemotePromptsScreen extends ConsumerWidget {
  const RemotePromptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompts = ref.watch(remotePromptProvider);
    final execState = ref.watch(remoteExecProvider);

    void send(Map<String, dynamic> cmd) =>
        ref.read(remoteConnectionProvider.notifier).sendCommand(cmd);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prompts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showForm(context, ref, null),
          ),
        ],
      ),
      body: prompts.isEmpty
          ? const Center(child: Text('No prompts'))
          : ListView.builder(
              itemCount: prompts.length,
              itemBuilder: (ctx, i) {
                final p = prompts[i];
                return _PromptTile(
                  prompt: p,
                  isCurrentlyRunning: execState.currentPromptId == p.id,
                  onEdit: () => _showForm(context, ref, p),
                  onDelete: () =>
                      send(buildPromptActionCmd(RemoteCmd.deletePrompt, p.id)),
                  onSkip: () =>
                      send(buildPromptActionCmd(RemoteCmd.skipPrompt, p.id)),
                  onDuplicate: () => send(
                      buildPromptActionCmd(RemoteCmd.duplicatePrompt, p.id)),
                  onReset: () =>
                      send(buildPromptActionCmd(RemoteCmd.resetPrompt, p.id)),
                );
              },
            ),
    );
  }

  Future<void> _showForm(
    BuildContext context,
    WidgetRef ref,
    RemotePromptItem? existing,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RemotePromptForm(existing: existing),
    );
  }
}

class _PromptTile extends StatelessWidget {
  const _PromptTile({
    required this.prompt,
    required this.isCurrentlyRunning,
    required this.onEdit,
    required this.onDelete,
    required this.onSkip,
    required this.onDuplicate,
    required this.onReset,
  });

  final RemotePromptItem prompt;
  final bool isCurrentlyRunning;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSkip;
  final VoidCallback onDuplicate;
  final VoidCallback onReset;

  Color _statusColor(String status, bool isSkipped) {
    if (isSkipped) return Colors.grey;
    return switch (status) {
      'running' => Colors.blue,
      'done' => Colors.green,
      'failed' => Colors.red,
      _ => Colors.orange,
    };
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(prompt.status, prompt.isSkipped);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: isCurrentlyRunning ? Colors.blue : statusColor,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          prompt.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: prompt.isSkipped ? Colors.grey : null,
            decoration:
                prompt.isSkipped ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${prompt.branch} · p${prompt.priority}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case 'edit':
                onEdit();
              case 'skip':
                onSkip();
              case 'duplicate':
                onDuplicate();
              case 'reset':
                onReset();
              case 'delete':
                onDelete();
            }
          },
          itemBuilder: (_) => [
            if (prompt.status == 'pending' || prompt.isSkipped)
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
            if (prompt.status != 'running' && prompt.status != 'done')
              PopupMenuItem(
                value: 'skip',
                child: Text(prompt.isSkipped ? 'Unskip' : 'Skip'),
              ),
            const PopupMenuItem(
                value: 'duplicate', child: Text('Duplicate')),
            if (prompt.status == 'done' || prompt.status == 'failed')
              const PopupMenuItem(
                  value: 'reset', child: Text('Reset to pending')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
