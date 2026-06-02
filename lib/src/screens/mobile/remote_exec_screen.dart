import 'package:assibant/src/remote/remote_protocol.dart';
import 'package:assibant/src/state/mobile/remote_connection_notifier.dart';
import 'package:assibant/src/state/mobile/remote_exec_notifier.dart';
import 'package:assibant/src/state/mobile/remote_prompt_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RemoteExecScreen extends ConsumerWidget {
  const RemoteExecScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(remoteExecProvider);
    final prompts = ref.watch(remotePromptProvider);

    void send(Map<String, dynamic> cmd) =>
        ref.read(remoteConnectionProvider.notifier).sendCommand(cmd);

    final currentPrompt = execState.currentPromptId != null
        ? prompts.where((p) => p.id == execState.currentPromptId).firstOrNull
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Execution')),
      body: Column(
        children: [
          // Status card
          _StatusCard(execState: execState, currentPrompt: currentPrompt),

          // Control buttons
          _ControlBar(execState: execState, send: send),

          // Output
          Expanded(
            child: _OutputView(output: execState.output),
          ),

          // Question input (when Claude asks)
          if (execState.pendingQuestion != null)
            _QuestionPanel(
              question: execState.pendingQuestion!,
              onAnswer: (answer) => send(buildAnswerQuestionCmd(answer)),
            ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.execState,
    required this.currentPrompt,
  });
  final RemoteExecState execState;
  final RemotePromptItem? currentPrompt;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    switch (execState.status) {
      case 'running':
        statusColor = Colors.blue;
        statusLabel = 'Running';
      case 'paused':
        statusColor = Colors.orange;
        statusLabel = 'Paused';
      default:
        statusColor = Colors.grey;
        statusLabel = 'Idle';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (execState.totalCount > 0) ...[
                const Spacer(),
                Text(
                  '${execState.completedCount} / ${execState.totalCount}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
          if (execState.totalCount > 0) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: execState.progress,
              backgroundColor: Colors.grey.shade300,
            ),
          ],
          if (currentPrompt != null) ...[
            const SizedBox(height: 8),
            Text(
              currentPrompt!.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({required this.execState, required this.send});
  final RemoteExecState execState;
  final void Function(Map<String, dynamic>) send;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (execState.isIdle)
            Expanded(
              child: FilledButton.icon(
                onPressed: () => send(buildStartCmd()),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start'),
              ),
            )
          else if (execState.isRunning) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => send(buildStopCmd()),
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Stop'),
              ),
            ),
          ] else if (execState.isPaused) ...[
            Expanded(
              child: FilledButton.icon(
                onPressed: () => send(buildResumeCmd()),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Resume'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => send(buildStopCmd()),
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Stop'),
            ),
          ],
        ],
      ),
    );
  }
}

class _OutputView extends StatefulWidget {
  const _OutputView({required this.output});
  final String output;

  @override
  State<_OutputView> createState() => _OutputViewState();
}

class _OutputViewState extends State<_OutputView> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(_OutputView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.output != oldWidget.output) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.output.isEmpty) {
      return const Center(
        child: Text('No output yet', style: TextStyle(color: Colors.grey)),
      );
    }
    return ColoredBox(
      color: const Color(0xFF1C1A17),
      child: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.all(12),
        child: SelectableText(
          widget.output,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _QuestionPanel extends StatefulWidget {
  const _QuestionPanel({required this.question, required this.onAnswer});
  final String question;
  final ValueChanged<String> onAnswer;

  @override
  State<_QuestionPanel> createState() => _QuestionPanelState();
}

class _QuestionPanelState extends State<_QuestionPanel> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.orange.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.question,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(
                    hintText: 'Type your answer...',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (v) {
                    widget.onAnswer(v);
                    _ctrl.clear();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send_rounded),
                onPressed: () {
                  widget.onAnswer(_ctrl.text);
                  _ctrl.clear();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
