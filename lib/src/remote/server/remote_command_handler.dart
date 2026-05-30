import 'package:assibant/src/remote/remote_protocol.dart';
import 'package:assibant/src/state/exec_notifier.dart';
import 'package:assibant/src/state/prompt_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RemoteCommandHandler {
  static Future<void> handle(Ref ref, Map<String, dynamic> cmd) async {
    final type = cmd['cmd'] as String?;
    if (type == null) return;

    final exec = ref.read(execNotifierProvider.notifier);
    final prompts = ref.read(promptListNotifierProvider.notifier);

    switch (type) {
      case RemoteCmd.start:
        await exec.start();
      case RemoteCmd.stop:
        exec.stop();
      case RemoteCmd.resume:
        exec.resume();
      case RemoteCmd.createPrompt:
        await prompts.add(
          content: cmd['content'] as String? ?? '',
          branch: cmd['branch'] as String? ?? '',
          projectPath: cmd['projectPath'] as String? ?? '',
          priority: cmd['priority'] as int?,
          sessionId: cmd['sessionId'] as String? ?? '',
          claudeModel: cmd['claudeModel'] as String? ?? '',
          imagePaths: cmd['imagePaths'] as String? ?? '',
          commitAfterRun: cmd['commitAfterRun'] as bool? ?? false,
        );
      case RemoteCmd.updatePrompt:
        await prompts.save(
          id: cmd['id'] as String,
          content: cmd['content'] as String? ?? '',
          branch: cmd['branch'] as String? ?? '',
          projectPath: cmd['projectPath'] as String? ?? '',
          priority: cmd['priority'] as int? ?? 0,
          isSkipped: cmd['isSkipped'] as bool? ?? false,
          sessionId: cmd['sessionId'] as String? ?? '',
          claudeModel: cmd['claudeModel'] as String? ?? '',
          imagePaths: cmd['imagePaths'] as String? ?? '',
          commitAfterRun: cmd['commitAfterRun'] as bool? ?? false,
        );
      case RemoteCmd.deletePrompt:
        await prompts.remove(cmd['id'] as String);
      case RemoteCmd.skipPrompt:
        await prompts.toggleSkip(cmd['id'] as String);
      case RemoteCmd.duplicatePrompt:
        await prompts.duplicate(cmd['id'] as String);
      case RemoteCmd.resetPrompt:
        await prompts.reset(cmd['id'] as String);
    }
  }
}
