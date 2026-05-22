import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterapptemp/src/data/database/app_database.dart';
import 'package:flutterapptemp/src/data/database/prompt_status.dart';
import 'package:flutterapptemp/src/utils/session_id_generator.dart';
import 'package:flutterapptemp/src/data/repositories/prompt_repository.dart';
import 'package:flutterapptemp/src/data/services/execution_service.dart';
import 'package:flutterapptemp/src/providers/database_providers.dart';
import 'package:flutterapptemp/src/state/prompt_notifier.dart';
import 'package:flutterapptemp/src/state/ui_providers.dart';

enum ExecStatus { idle, running, paused }

class ExecState {
  const ExecState({
    this.status = ExecStatus.idle,
    this.currentPromptId,
    this.completedCount = 0,
    this.totalCount = 0,
    this.currentOutput = '',
    this.pendingQuestion,
  });

  final ExecStatus status;
  final String? currentPromptId;
  final int completedCount;
  final int totalCount;
  final String currentOutput;

  /// Non-null when Claude has asked a question and is awaiting the user's reply.
  final String? pendingQuestion;

  double get progress => totalCount > 0 ? completedCount / totalCount : 0;

  ExecState copyWith({
    ExecStatus? status,
    String? currentPromptId,
    int? completedCount,
    int? totalCount,
    String? currentOutput,
    String? pendingQuestion,
    bool clearQuestion = false,
  }) =>
      ExecState(
        status: status ?? this.status,
        currentPromptId: currentPromptId ?? this.currentPromptId,
        completedCount: completedCount ?? this.completedCount,
        totalCount: totalCount ?? this.totalCount,
        currentOutput: currentOutput ?? this.currentOutput,
        pendingQuestion: clearQuestion ? null : (pendingQuestion ?? this.pendingQuestion),
      );
}

final execNotifierProvider =
    NotifierProvider<ExecNotifier, ExecState>(ExecNotifier.new);

class ExecNotifier extends Notifier<ExecState> {
  Completer<void>? _pauseCompleter;
  Completer<void>? _cancelCurrentRun;
  Completer<String>? _questionCompleter;
  bool _stopRequested = false;

  PromptRepository get _repo => ref.read(promptRepositoryProvider);
  ExecutionService get _svc => ref.read(executionServiceProvider);
  AppSettings get _settings => ref.read(settingsStateProvider);

  @override
  ExecState build() => const ExecState();

  Future<void> start() async {
    if (state.status != ExecStatus.idle) return;
    _stopRequested = false;
    final pending = await _repo.getExecutable();
    if (pending.isEmpty) return;
    state = ExecState(
      status: ExecStatus.running,
      currentPromptId: pending.first.id,
      totalCount: pending.length,
    );
    await _runLoop();
  }

  void pause() {
    if (state.status != ExecStatus.running) return;
    _pauseCompleter = Completer<void>();
    _killCurrentProcess();
    state = state.copyWith(status: ExecStatus.paused);
  }

  void resume() {
    if (state.status != ExecStatus.paused) return;
    state = state.copyWith(status: ExecStatus.running);
    _pauseCompleter?.complete();
    _pauseCompleter = null;
  }

  void stop() {
    _stopRequested = true;
    _killCurrentProcess();
    _pauseCompleter?.complete();
    _pauseCompleter = null;
    // Complete any pending question with an empty answer so the loop can exit
    _questionCompleter?.complete('');
    _questionCompleter = null;
    state = const ExecState();
  }

  /// Called by the UI after the user answers Claude's question.
  void answerQuestion(String answer) {
    _questionCompleter?.complete(answer);
    _questionCompleter = null;
    state = state.copyWith(clearQuestion: true);
  }

  void _killCurrentProcess() {
    final c = _cancelCurrentRun;
    _cancelCurrentRun = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  Future<void> _runLoop() async {
    while (!_stopRequested) {
      if (state.status == ExecStatus.paused) {
        await _pauseCompleter?.future;
        if (_stopRequested) break;
      }

      // Fetch next pending task dynamically so newly added tasks are picked up
      final pending = await _repo.getExecutable();
      if (pending.isEmpty) break;

      var prompt = pending.first;
      state = state.copyWith(
        status: ExecStatus.running,
        currentPromptId: prompt.id,
        totalCount: state.completedCount + pending.length,
      );

      // Auto-assign a random session ID to prompts that have none
      if (prompt.sessionId.isEmpty) {
        final newSessionId = generateSessionId();
        await _repo.updateSessionId(prompt.id, newSessionId);
        prompt = prompt.copyWith(sessionId: newSessionId);
      }

      // Look up the claude session ID from a previous prompt in the same session
      String? resumeSessionId;
      if (prompt.sessionId.isNotEmpty) {
        resumeSessionId =
            await _repo.getLatestClaudeSessionId(prompt.sessionId);
      }

      await _repo.updateStatus(prompt.id, PromptStatus.running);
      await _repo.updateStartedAt(prompt.id);
      ref.invalidate(promptListNotifierProvider);
      state = state.copyWith(currentOutput: '');

      _cancelCurrentRun = Completer<void>();
      final result = await _svc.run(
        prompt,
        _settings,
        onOutput: (chunk) {
          state = state.copyWith(
            currentOutput: '${state.currentOutput}$chunk',
          );
        },
        cancelToken: _cancelCurrentRun!.future,
        resumeSessionId: resumeSessionId,
        onQuestion: _stopRequested ? null : (question) async {
          _questionCompleter = Completer<String>();
          state = state.copyWith(pendingQuestion: question);
          final answer = await _questionCompleter!.future;
          _questionCompleter = null;
          return answer;
        },
      );
      _cancelCurrentRun = null;

      if (_stopRequested) break;

      // Paused mid-run: reset prompt to pending and wait for resume
      if (result.cancelled && state.status == ExecStatus.paused) {
        await _repo.updateStatus(prompt.id, PromptStatus.pending);
        ref.invalidate(promptListNotifierProvider);
        await _pauseCompleter?.future;
        if (_stopRequested) break;
        continue; // re-fetch from DB; this prompt is pending again
      }

      final newStatus = result.success ? PromptStatus.done : PromptStatus.failed;
      final output = result.success
          ? result.output
          : [result.output, if (result.error != null) 'ERROR: ${result.error}']
              .where((s) => s.isNotEmpty)
              .join('\n\n');
      await _repo.updateStatus(prompt.id, newStatus);
      await _repo.updateOutput(prompt.id, output);
      if (result.claudeSessionId.isNotEmpty) {
        await _repo.updateClaudeSessionId(prompt.id, result.claudeSessionId);
      }
      if (result.success && (prompt.commitAfterRun || _settings.commitAfterPrompt)) {
        await _svc.commitChanges(prompt, _settings);
      }
      ref.invalidate(promptListNotifierProvider);

      state = state.copyWith(completedCount: state.completedCount + 1);

      if (!result.success && _settings.pauseOnFail) {
        pause();
        await _pauseCompleter?.future;
        if (_stopRequested) break;
      }
    }

    if (!_stopRequested) {
      state = ExecState(
        completedCount: state.completedCount,
        totalCount: state.totalCount,
      );
    }
  }
}

List<PromptEntry> executableQueue(List<PromptEntry> prompts) =>
    (prompts
            .where((p) => !p.isSkipped && p.status == PromptStatus.pending)
            .toList()
          ..sort((a, b) => a.priority.compareTo(b.priority)));
