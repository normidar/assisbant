import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:assibant/src/data/database/app_database.dart';
import 'package:assibant/src/state/ui_providers.dart';

class ExecutionResult {
  const ExecutionResult({
    required this.success,
    required this.output,
    this.error,
    this.cancelled = false,
    this.claudeSessionId = '',
  });

  final bool success;
  final String output;
  final String? error;
  final bool cancelled;
  final String claudeSessionId;
}

class ExecutionService {
  const ExecutionService();

  // ユーザーのデフォルトシェル。GUI アプリ起動時に SHELL が引き継がれるので
  // zsh/fish 等のプロファイルを読ませるためにそちらを優先する。
  static String get _userShell => Platform.environment['SHELL'] ?? '/bin/bash';

  // claude がよくインストールされるパスを PATH の先頭に追加する。
  // GUI アプリは PATH が最小限なため、明示的に補完する必要がある。
  static String get _pathSetup =>
      r'export PATH="/usr/local/bin:/opt/homebrew/bin:$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"; ';

  /// 1つのプロンプトを実行して結果を返す。
  ///
  /// sessionId が設定されているプロンプトは stream-json モードで実行し、
  /// Claude の質問→回答ループや claudeSessionId の取得に対応する。
  /// sessionId が空の場合は従来の --print モードで高速実行する。
  Future<ExecutionResult> run(
    PromptEntry prompt,
    AppSettings settings, {
    void Function(String line)? onOutput,
    Future<void>? cancelToken,
    String? resumeSessionId,
    Future<String> Function(String question)? onQuestion,
  }) async {
    try {
      // prompt 個別の projectPath を優先し、未設定ならグローバル workdir を使う
      final rawWorkdir = prompt.projectPath.isNotEmpty
          ? prompt.projectPath
          : settings.workdir;
      final workdir = _expandHome(rawWorkdir);
      final cliPath = settings.cliPath.isEmpty ? 'claude' : settings.cliPath;

      if (settings.autoCheckout) {
        final checkout = await _runGit(
          ['checkout', prompt.branch],
          workdir,
        );
        if (checkout.exitCode != 0) {
          // ローカルに存在しないブランチは新規作成する
          final create = await _runGit(
            ['checkout', '-b', prompt.branch],
            workdir,
          );
          if (create.exitCode != 0) {
            return ExecutionResult(
              success: false,
              output: '',
              error: 'git checkout: ${create.stderr}',
            );
          }
        }
      }

      // sessionId が設定されている = 会話継続が必要なプロンプト
      // stream-json モードは claudeSessionId を返すため会話の引き継ぎに必須
      final useStreamJson = prompt.sessionId.isNotEmpty;
      final modelArgs = _resolveModelArgs(prompt.claudeModel, settings);

      final env = _buildEnvironment(settings.envOverrides);

      if (useStreamJson) {
        return _executeStreamJsonLoop(
          content: prompt.content,
          cliPath: cliPath,
          workdir: workdir,
          modelArgs: modelArgs,
          environment: env,
          imagePaths: _decodeImagePaths(prompt.imagePaths),
          resumeSessionId: resumeSessionId,
          onOutput: onOutput,
          cancelToken: cancelToken,
          onQuestion: onQuestion,
        );
      }

      final args = _buildClaudeArgs(
        content: prompt.content,
        modelArgs: modelArgs,
        imagePaths: _decodeImagePaths(prompt.imagePaths),
        resumeSessionId: resumeSessionId,
      );

      dev.log('[ExecSvc] args: $args', name: 'ExecutionService');

      final process = await _spawnClaude(cliPath, args, workdir, environment: env);
      unawaited(process.stdin.close());

      var cancelled = false;
      unawaited(cancelToken?.then((_) {
        cancelled = true;
        process.kill();
      }));

      final stdoutBuf = StringBuffer();
      final stderrBuf = StringBuffer();

      await Future.wait([
        process.stdout.transform(utf8.decoder).forEach((chunk) {
          stdoutBuf.write(chunk);
          onOutput?.call(chunk);
        }),
        process.stderr.transform(utf8.decoder).forEach((chunk) {
          stderrBuf.write(chunk);
          onOutput?.call(chunk);
        }),
      ]);

      final exitCode = await process.exitCode;

      if (cancelled) {
        return const ExecutionResult(success: false, output: '', cancelled: true);
      }

      final stdout = stdoutBuf.toString();
      final stderr = stderrBuf.toString();
      final ok = exitCode == 0;

      return ExecutionResult(
        success: ok,
        output: ok ? stdout : '$stdout\n$stderr'.trim(),
        error: ok ? null : (stderr.isNotEmpty ? stderr : 'exit $exitCode'),
      );
    } on Exception catch (e) {
      return ExecutionResult(
        success: false,
        output: '',
        error: e.toString(),
      );
    }
  }

  /// stream-json モードで Claude を実行し、質問→回答ループを処理する。
  ///
  /// Claude が質問を返した場合（_looksLikeQuestion が true）は onQuestion を呼び出し、
  /// ユーザーの回答を次のリクエストの content として再実行する。
  /// 質問でない結果が返るか、onQuestion が null なら即座に終了する。
  Future<ExecutionResult> _executeStreamJsonLoop({
    required String content,
    required String cliPath,
    required String workdir,
    required List<String> modelArgs,
    Map<String, String>? environment,
    List<String> imagePaths = const [],
    String? resumeSessionId,
    void Function(String)? onOutput,
    Future<void>? cancelToken,
    Future<String> Function(String question)? onQuestion,
  }) async {
    String currentContent = content;
    String? currentResumeId = resumeSessionId;

    while (true) {
      final result = await _executeStreamJsonOnce(
        content: currentContent,
        cliPath: cliPath,
        workdir: workdir,
        modelArgs: modelArgs,
        environment: environment,
        imagePaths: imagePaths,
        resumeSessionId: currentResumeId,
        onOutput: onOutput,
        cancelToken: cancelToken,
      );

      if (result.cancelled ||
          !result.success ||
          onQuestion == null ||
          result.claudeSessionId.isEmpty) {
        return result;
      }

      if (!_looksLikeQuestion(result.output)) {
        return result;
      }

      dev.log(
        '[ExecSvc] question detected, waiting for user answer',
        name: 'ExecutionService',
      );
      final answer = await onQuestion(result.output);
      currentContent = answer;
      currentResumeId = result.claudeSessionId;
    }
  }

  /// stream-json を1回実行して結果を返す。質問ループは呼び出し元が担う。
  Future<ExecutionResult> _executeStreamJsonOnce({
    required String content,
    required String cliPath,
    required String workdir,
    required List<String> modelArgs,
    Map<String, String>? environment,
    List<String> imagePaths = const [],
    String? resumeSessionId,
    void Function(String)? onOutput,
    Future<void>? cancelToken,
  }) async {
    final args = _buildClaudeArgs(
      content: content,
      modelArgs: modelArgs,
      imagePaths: imagePaths,
      resumeSessionId: resumeSessionId,
      streamJson: true,
    );

    dev.log('[ExecSvc] args: $args', name: 'ExecutionService');

    final process = await _spawnClaude(cliPath, args, workdir, environment: environment);
    unawaited(process.stdin.close());

    var cancelled = false;
    unawaited(cancelToken?.then((_) {
      cancelled = true;
      process.kill();
    }));

    final stdoutBuf = StringBuffer();
    final stderrBuf = StringBuffer();

    var lineBuffer = '';
    var capturedSessionId = '';
    var capturedResult = '';
    var isStreamError = false;

    await Future.wait([
      process.stdout.transform(utf8.decoder).forEach((chunk) {
        stdoutBuf.write(chunk);
        lineBuffer += chunk;

        // stream-json は1行1JSONイベント形式。改行が来るたびに解析する
        var idx = lineBuffer.indexOf('\n');
        while (idx >= 0) {
          final line = lineBuffer.substring(0, idx).trim();
          lineBuffer = lineBuffer.substring(idx + 1);

          if (line.isNotEmpty) {
            try {
              final event = jsonDecode(line) as Map<String, dynamic>;
              final type = event['type'] as String?;
              dev.log(
                '[ExecSvc] stream-json type=$type',
                name: 'ExecutionService',
              );
              // 'assistant' イベント: Claude のテキスト応答をリアルタイムで UI に流す
              if (type == 'assistant') {
                final msg = event['message'] as Map<String, dynamic>?;
                final contents = msg?['content'];
                if (contents is List) {
                  for (final item in contents) {
                    if (item is Map && item['type'] == 'text') {
                      final text = (item['text'] as String?) ?? '';
                      if (text.isNotEmpty) onOutput?.call(text);
                    }
                  }
                }
              // 'result' イベント: 実行の最終結果と claudeSessionId が含まれる
              } else if (type == 'result') {
                capturedSessionId = (event['session_id'] as String?) ?? '';
                capturedResult = (event['result'] as String?) ?? '';
                isStreamError = (event['is_error'] as bool?) ?? false;
                dev.log(
                  '[ExecSvc] result: sessionId=$capturedSessionId '
                  'isError=$isStreamError '
                  'resultLen=${capturedResult.length}',
                  name: 'ExecutionService',
                );
              }
            } catch (e) {
              dev.log(
                '[ExecSvc] failed to parse line: $line\nerr: $e',
                name: 'ExecutionService',
              );
            }
          }

          idx = lineBuffer.indexOf('\n');
        }
      }),
      process.stderr.transform(utf8.decoder).forEach((chunk) {
        stderrBuf.write(chunk);
      }),
    ]);

    final exitCode = await process.exitCode;
    dev.log(
      '[ExecSvc] process exited: code=$exitCode cancelled=$cancelled',
      name: 'ExecutionService',
    );

    if (cancelled) {
      return const ExecutionResult(success: false, output: '', cancelled: true);
    }

    final ok = exitCode == 0 && !isStreamError;
    final outputText =
        capturedResult.isNotEmpty ? capturedResult : stdoutBuf.toString();
    final stderr = stderrBuf.toString();
    if (stderr.isNotEmpty) {
      dev.log('[ExecSvc] stderr: $stderr', name: 'ExecutionService');
    }

    return ExecutionResult(
      success: ok,
      output: ok ? outputText : '$outputText\n$stderr'.trim(),
      error: ok ? null : (stderr.isNotEmpty ? stderr : 'exit $exitCode'),
      claudeSessionId: capturedSessionId,
    );
  }

  /// Returns true if [text] appears to be a question requiring user input.
  bool _looksLikeQuestion(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return false;
    final last = lines.last.trim();
    if (last.endsWith('?') || last.endsWith('？')) return true;
    final lower = last.toLowerCase();
    if (lower.contains('[y/n]') ||
        lower.contains('[yes/no]') ||
        lower.contains('(y/n)') ||
        lower.contains('(yes/no)')) return true;
    return false;
  }

  /// Stages all changes and commits with [prompt.content] as the message.
  Future<void> commitChanges(
    PromptEntry prompt,
    AppSettings settings,
  ) async {
    final rawWorkdir = prompt.projectPath.isNotEmpty
        ? prompt.projectPath
        : settings.workdir;
    final workdir = _expandHome(rawWorkdir);

    final status = await _runGit(['status', '--porcelain'], workdir);

    if (status.exitCode != 0 || (status.stdout as String).trim().isEmpty) {
      dev.log(
        '[ExecSvc] commit skipped: no changes or not a git repo',
        name: 'ExecutionService',
      );
      return;
    }

    await _runGit(['add', '-A'], workdir);

    final commit = await _runGit(['commit', '-m', prompt.content], workdir);

    if (commit.exitCode == 0) {
      dev.log(
        '[ExecSvc] committed changes for prompt ${prompt.id}',
        name: 'ExecutionService',
      );
    } else {
      dev.log(
        '[ExecSvc] commit failed: ${commit.stderr}',
        name: 'ExecutionService',
      );
    }
  }

  // ─── Platform helpers ────────────────────────────────────────────────────────

  /// Builds Claude CLI args as a proper list (no shell quoting).
  List<String> _buildClaudeArgs({
    required String content,
    required List<String> modelArgs,
    required List<String> imagePaths,
    String? resumeSessionId,
    bool streamJson = false,
  }) {
    return [
      '--dangerously-skip-permissions',
      ...modelArgs,
      '--print', content,
      for (final img in imagePaths) ...['--image', img],
      if (resumeSessionId != null && resumeSessionId.isNotEmpty)
        ...['--resume', resumeSessionId],
      if (streamJson) ...['--output-format', 'stream-json', '--verbose'],
    ];
  }

  /// Spawns the Claude CLI process cross-platform.
  ///
  /// On Windows: runs the executable directly (PATH is inherited from the OS).
  /// On macOS/Linux: wraps in a login shell so ~/.bashrc / /usr/local/bin are
  /// on PATH, and uses `exec` so kill() reaches claude directly.
  Future<Process> _spawnClaude(
    String cliPath,
    List<String> args,
    String workdir, {
    Map<String, String>? environment,
  }) {
    if (Platform.isWindows) {
      final exe = cliPath.isEmpty ? 'claude' : cliPath;
      return Process.start(exe, args, workingDirectory: workdir, environment: environment);
    }
    final buf = StringBuffer('exec ${_shellQuote(cliPath)}');
    for (final a in args) {
      buf.write(' ${_shellQuote(a)}');
    }
    return Process.start(
      '/bin/bash',
      ['-lc', buf.toString()],
      workingDirectory: workdir,
      environment: environment,
    );
  }

  /// Runs a git command cross-platform.
  Future<ProcessResult> _runGit(List<String> args, String workdir) {
    if (Platform.isWindows) {
      return Process.run('git', args, workingDirectory: workdir);
    }
    return Process.run('/usr/bin/git', args, workingDirectory: workdir);
  }

  /// Returns `['--model', name]` args when a model override is active.
  List<String> _resolveModelArgs(String promptModel, AppSettings settings) {
    if (settings.modelMode == ModelMode.claude && promptModel.isNotEmpty) {
      return ['--model', promptModel];
    }
    if (settings.modelMode == ModelMode.local &&
        settings.localModelName.isNotEmpty) {
      return ['--model', settings.localModelName];
    }
    return const [];
  }

  /// Builds a merged environment map with overrides applied.
  /// Keys with value '__UNSET__' are removed from the parent environment.
  Map<String, String>? _buildEnvironment(Map<String, String> overrides) {
    if (overrides.isEmpty) return null;
    final env = Map<String, String>.from(Platform.environment);
    for (final entry in overrides.entries) {
      if (entry.value == '__UNSET__') {
        env.remove(entry.key);
      } else {
        env[entry.key] = entry.value;
      }
    }
    return env;
  }

  List<String> _decodeImagePaths(String raw) {
    if (raw.isEmpty) return const [];
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return const [];
    }
  }

  String _shellQuote(String value) => "'${value.replaceAll("'", r"'\''")}'";

  String _expandHome(String path) {
    if (path.startsWith('~/')) {
      final home = Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '';
      return home + path.substring(1);
    }
    return path;
  }
}
