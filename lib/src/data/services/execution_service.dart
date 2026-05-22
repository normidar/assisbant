import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutterapptemp/src/data/database/app_database.dart';
import 'package:flutterapptemp/src/state/ui_providers.dart';

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
        final checkout = await Process.run(
          '/bin/bash',
          ['-lc', 'git checkout ${_shellQuote(prompt.branch)}'],
          workingDirectory: workdir,
        );
        if (checkout.exitCode != 0) {
          // ローカルに存在しないブランチは新規作成する
          final create = await Process.run(
            '/bin/bash',
            ['-lc', 'git checkout -b ${_shellQuote(prompt.branch)}'],
            workingDirectory: workdir,
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

      final modelFlag = _resolveModelFlag(prompt.claudeModel, settings);

      if (useStreamJson) {
        return _executeStreamJsonLoop(
          content: prompt.content,
          cliPath: cliPath,
          workdir: workdir,
          modelFlag: _resolveModelFlag(prompt.claudeModel, settings),
          imagePaths: _decodeImagePaths(prompt.imagePaths),
          resumeSessionId: resumeSessionId,
          onOutput: onOutput,
          cancelToken: cancelToken,
          onQuestion: onQuestion,
        );
      }

      // sessionId なしの場合はシンプルな --print モード（出力だけ取得）
      final cmdBuf = StringBuffer(
        'exec ${_shellQuote(cliPath)} --dangerously-skip-permissions$modelFlag --print ${_shellQuote(prompt.content)}',
      );
      for (final imgPath in _decodeImagePaths(prompt.imagePaths)) {
        cmdBuf.write(' --image ${_shellQuote(imgPath)}');
      }
      if (resumeSessionId != null && resumeSessionId.isNotEmpty) {
        cmdBuf.write(' --resume ${_shellQuote(resumeSessionId)}');
      }

      dev.log('[ExecSvc] cmd: $cmdBuf', name: 'ExecutionService');

      final process = await Process.start(
        '/bin/bash',
        ['-lc', cmdBuf.toString()],
        workingDirectory: workdir,
      );
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
    required String modelFlag,
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
        modelFlag: modelFlag,
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
    required String modelFlag,
    List<String> imagePaths = const [],
    String? resumeSessionId,
    void Function(String)? onOutput,
    Future<void>? cancelToken,
  }) async {
    final cmdBuf = StringBuffer(
      'exec ${_shellQuote(cliPath)} --dangerously-skip-permissions$modelFlag --print ${_shellQuote(content)} --output-format stream-json --verbose',
    );
    for (final imgPath in imagePaths) {
      cmdBuf.write(' --image ${_shellQuote(imgPath)}');
    }
    if (resumeSessionId != null && resumeSessionId.isNotEmpty) {
      cmdBuf.write(' --resume ${_shellQuote(resumeSessionId)}');
    }

    dev.log('[ExecSvc] cmd: $cmdBuf', name: 'ExecutionService');

    // exec replaces bash with claude directly so kill() reaches the claude process
    final process = await Process.start(
      '/bin/bash',
      ['-lc', cmdBuf.toString()],
      workingDirectory: workdir,
    );
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
    // Ends with a question mark (ASCII or fullwidth)
    if (last.endsWith('?') || last.endsWith('？')) return true;
    // Common yes/no option patterns
    final lower = last.toLowerCase();
    if (lower.contains('[y/n]') ||
        lower.contains('[yes/no]') ||
        lower.contains('(y/n)') ||
        lower.contains('(yes/no)')) return true;
    return false;
  }

  /// Stages all changes and commits with [prompt.content] as the message.
  /// Does nothing if there are no uncommitted changes or the directory is
  /// not a git repository.
  Future<void> commitChanges(
    PromptEntry prompt,
    AppSettings settings,
  ) async {
    final rawWorkdir = prompt.projectPath.isNotEmpty
        ? prompt.projectPath
        : settings.workdir;
    final workdir = _expandHome(rawWorkdir);

    final status = await Process.run(
      '/usr/bin/git',
      ['status', '--porcelain'],
      workingDirectory: workdir,
    );

    if (status.exitCode != 0 || (status.stdout as String).trim().isEmpty) {
      dev.log(
        '[ExecSvc] commit skipped: no changes or not a git repo',
        name: 'ExecutionService',
      );
      return;
    }

    await Process.run('/usr/bin/git', ['add', '-A'],
        workingDirectory: workdir);

    final commit = await Process.run(
      '/usr/bin/git',
      ['commit', '-m', prompt.content],
      workingDirectory: workdir,
    );

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

  /// Returns the `--model <name>` fragment to inject into the CLI command.
  /// Per-prompt model (Claude mode only) takes precedence over the global
  /// local model name.
  String _resolveModelFlag(String promptModel, AppSettings settings) {
    if (settings.modelMode == ModelMode.claude && promptModel.isNotEmpty) {
      return ' --model ${_shellQuote(promptModel)}';
    }
    if (settings.modelMode == ModelMode.local &&
        settings.localModelName.isNotEmpty) {
      return ' --model ${_shellQuote(settings.localModelName)}';
    }
    return '';
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
