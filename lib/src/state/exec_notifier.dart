import 'dart:async';

import 'package:assibant/src/data/database/app_database.dart';
import 'package:assibant/src/data/database/prompt_status.dart';
import 'package:assibant/src/data/repositories/prompt_repository.dart';
import 'package:assibant/src/data/services/execution_service.dart';
import 'package:assibant/src/providers/database_providers.dart';
import 'package:assibant/src/state/prompt_notifier.dart';
import 'package:assibant/src/state/ui_providers.dart';
import 'package:assibant/src/utils/session_id_generator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ExecStatus { idle, running, paused }

/// プロンプト実行キューの現在状態を保持するイミュータブルなデータクラス。
/// Riverpod の state として管理され、UI はこれを読み取って表示を更新する。
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
  }) => ExecState(
    status: status ?? this.status,
    currentPromptId: currentPromptId ?? this.currentPromptId,
    completedCount: completedCount ?? this.completedCount,
    totalCount: totalCount ?? this.totalCount,
    currentOutput: currentOutput ?? this.currentOutput,
    pendingQuestion: clearQuestion
        ? null
        : (pendingQuestion ?? this.pendingQuestion),
  );
}

final execNotifierProvider = NotifierProvider<ExecNotifier, ExecState>(
  ExecNotifier.new,
);

/// プロンプトキューを順番に実行するメインコントローラー。
///
/// 内部の非同期制御は Completer で行う:
/// - [_pauseCompleter]: pause() で生成し、resume()/stop() が complete() することで
///   _runLoop の待機を解除する。
/// - [_cancelCurrentRun]: 実行中プロセスをキャンセルするためのシグナル。
///   pause() や stop() 時に complete() してプロセスを kill させる。
/// - [_questionCompleter]: Claude が質問を返したとき、UI からの回答を待つ。
class ExecNotifier extends Notifier<ExecState> {
  // pause/resume のハンドシェイク用。pause() 時に生成、resume()/stop() で完了させる
  Completer<void>? _pauseCompleter;
  // 実行中プロセスへのキャンセルシグナル。ExecutionService 側で future を監視している
  Completer<void>? _cancelCurrentRun;
  // Claude が質問を返したとき、ユーザー回答を非同期で受け取るための bridge
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
    // Completer を先に作成してから kill する。_runLoop が即座に await するため
    _pauseCompleter = Completer<void>();
    _killCurrentProcess();
    state = state.copyWith(status: ExecStatus.paused);
  }

  void resume() {
    if (state.status != ExecStatus.paused) return;
    state = state.copyWith(status: ExecStatus.running);
    // complete() で _runLoop の await _pauseCompleter?.future が解除される
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

  /// プロンプトを順番に実行するメインループ。
  /// start() から呼ばれ、キューが空になるか stop() されるまで回り続ける。
  Future<void> _runLoop() async {
    while (!_stopRequested) {
      // pause 中は resume()/stop() が _pauseCompleter を complete するまで待機
      if (state.status == ExecStatus.paused) {
        await _pauseCompleter?.future;
        if (_stopRequested) break;
      }

      // DB から毎回取得することで、実行中に追加されたプロンプトも拾える
      final pending = await _repo.getExecutable();
      if (pending.isEmpty) break;

      var prompt = pending.first;
      state = state.copyWith(
        status: ExecStatus.running,
        currentPromptId: prompt.id,
        totalCount: state.completedCount + pending.length,
        // Clear the output buffer the moment the current prompt switches so the
        // UI (and remote clients) never attribute the previous prompt's output
        // to this one.
        currentOutput: '',
      );

      // sessionId が未設定のプロンプトには自動でランダムIDを割り当てる。
      // sessionId は Claude の会話履歴を引き継ぐためのユーザー定義グループID
      if (prompt.sessionId.isEmpty) {
        final newSessionId = generateSessionId();
        await _repo.updateSessionId(prompt.id, newSessionId);
        prompt = prompt.copyWith(sessionId: newSessionId);
      }

      // 同じ sessionId を持つ直前の完了済みプロンプトから claudeSessionId を取得し、
      // --resume フラグで渡すことで Claude の会話コンテキストを継続する
      String? resumeSessionId;
      if (prompt.sessionId.isNotEmpty) {
        resumeSessionId = await _repo.getLatestClaudeSessionId(
          prompt.sessionId,
        );
      }

      await _repo.updateStatus(prompt.id, PromptStatus.running);
      await _repo.updateStartedAt(prompt.id);
      // UI のリストに running 状態を即時反映させる
      ref.invalidate(promptListNotifierProvider);

      // _cancelCurrentRun を ExecutionService に渡し、pause()/stop() 時に
      // complete() してプロセスを kill できるようにする
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
        // stop() 後は質問ハンドラを渡さない（ループを早期終了させるため）
        onQuestion: _stopRequested
            ? null
            : (question) async {
                _questionCompleter = Completer<String>();
                state = state.copyWith(pendingQuestion: question);
                // answerQuestion() が呼ばれるまで待機
                final answer = await _questionCompleter!.future;
                _questionCompleter = null;
                return answer;
              },
      );
      _cancelCurrentRun = null;

      if (_stopRequested) break;

      // pause() で実行中プロセスを kill した場合: プロンプトを pending に戻して
      // resume を待つ。continue で先頭から再取得するためこのプロンプトが再実行される
      if (result.cancelled && state.status == ExecStatus.paused) {
        await _repo.updateStatus(prompt.id, PromptStatus.pending);
        ref.invalidate(promptListNotifierProvider);
        await _pauseCompleter?.future;
        if (_stopRequested) break;
        continue;
      }

      final newStatus = result.success
          ? PromptStatus.done
          : PromptStatus.failed;
      final output = result.success
          ? result.output
          : [
              result.output,
              if (result.error != null) 'ERROR: ${result.error}',
            ].where((s) => s.isNotEmpty).join('\n\n');
      await _repo.updateStatus(prompt.id, newStatus);
      await _repo.updateOutput(prompt.id, output);
      // Claude が返した内部セッションIDを保存し、次のプロンプトで --resume に使う
      if (result.claudeSessionId.isNotEmpty) {
        await _repo.updateClaudeSessionId(prompt.id, result.claudeSessionId);
      }
      // prompt 個別フラグ OR グローバル設定のどちらかが true なら自動コミット
      if (result.success &&
          (prompt.commitAfterRun || _settings.commitAfterPrompt)) {
        await _svc.commitChanges(prompt, _settings);
      }
      ref.invalidate(promptListNotifierProvider);

      state = state.copyWith(completedCount: state.completedCount + 1);

      // pauseOnFail 設定が有効かつ失敗した場合、ユーザーが確認するまで停止する
      if (!result.success && _settings.pauseOnFail) {
        pause();
        await _pauseCompleter?.future;
        if (_stopRequested) break;
      }
    }

    // stop() 以外でループを抜けた場合（キュー完了）は完了カウントを維持して idle に戻す
    if (!_stopRequested) {
      state = ExecState(
        completedCount: state.completedCount,
        totalCount: state.totalCount,
      );
    }
  }
}

/// 全プロンプトリストから実行可能なプロンプトを priority 昇順で返す純粋関数。
///
/// UI 側が既に読み込んだ [promptListNotifierProvider] の値を再利用して
/// キューの件数表示やプレビューに使うためのヘルパー。
/// DB クエリは行わず、渡されたリストをフィルタ・ソートするだけ。
List<PromptEntry> executableQueue(List<PromptEntry> prompts) =>
    (prompts
        .where((p) => !p.isSkipped && p.status == PromptStatus.pending)
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority)));
