import 'package:assibant/src/remote/remote_protocol.dart';
import 'package:assibant/src/state/mobile/remote_connection_notifier.dart';
import 'package:assibant/src/state/mobile/remote_prompt_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RemotePromptForm extends ConsumerStatefulWidget {
  const RemotePromptForm({this.existing, super.key});
  final RemotePromptItem? existing;

  @override
  ConsumerState<RemotePromptForm> createState() => _RemotePromptFormState();
}

class _RemotePromptFormState extends ConsumerState<RemotePromptForm> {
  late TextEditingController _contentCtrl;
  late TextEditingController _branchCtrl;
  late TextEditingController _projectCtrl;
  late TextEditingController _priorityCtrl;
  late TextEditingController _sessionCtrl;
  bool _isSkipped = false;
  bool _commitAfterRun = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _contentCtrl = TextEditingController(text: p?.content ?? '');
    _branchCtrl = TextEditingController(text: p?.branch ?? '');
    _projectCtrl = TextEditingController(text: p?.projectPath ?? '');
    _priorityCtrl = TextEditingController(text: p?.priority.toString() ?? '0');
    _sessionCtrl = TextEditingController(text: p?.sessionId ?? '');
    _isSkipped = p?.isSkipped ?? false;
    _commitAfterRun = p?.commitAfterRun ?? false;
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _branchCtrl.dispose();
    _projectCtrl.dispose();
    _priorityCtrl.dispose();
    _sessionCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) return;

    final send = ref.read(remoteConnectionProvider.notifier).sendCommand;
    final existing = widget.existing;

    if (existing == null) {
      send(
        buildCreatePromptCmd(
          content: content,
          branch: _branchCtrl.text.trim(),
          projectPath: _projectCtrl.text.trim(),
          priority: int.tryParse(_priorityCtrl.text) ?? 0,
          sessionId: _sessionCtrl.text.trim(),
          commitAfterRun: _commitAfterRun,
        ),
      );
    } else {
      send(
        buildUpdatePromptCmd(
          id: existing.id,
          content: content,
          branch: _branchCtrl.text.trim(),
          projectPath: _projectCtrl.text.trim(),
          priority: int.tryParse(_priorityCtrl.text) ?? existing.priority,
          isSkipped: _isSkipped,
          sessionId: _sessionCtrl.text.trim(),
          claudeModel: existing.claudeModel,
          imagePaths: existing.imagePaths,
          commitAfterRun: _commitAfterRun,
        ),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                isNew ? 'New Prompt' : 'Edit Prompt',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentCtrl,
            decoration: const InputDecoration(
              labelText: 'Prompt content *',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            autofocus: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _branchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Branch',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _priorityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _projectCtrl,
            decoration: const InputDecoration(
              labelText: 'Project path (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _sessionCtrl,
            decoration: const InputDecoration(
              labelText: 'Session ID (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _commitAfterRun,
                onChanged: (v) => setState(() => _commitAfterRun = v ?? false),
              ),
              const Text('Commit after run', style: TextStyle(fontSize: 13)),
              if (!isNew) ...[
                const SizedBox(width: 16),
                Checkbox(
                  value: _isSkipped,
                  onChanged: (v) => setState(() => _isSkipped = v ?? false),
                ),
                const Text('Skip', style: TextStyle(fontSize: 13)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _submit,
            child: Text(isNew ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }
}
