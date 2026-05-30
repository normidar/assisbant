import 'dart:convert';

import 'package:assibant/src/data/database/app_database.dart';
import 'package:assibant/src/state/exec_notifier.dart';

// ─── Message types (server → client) ────────────────────────────────────────

class RemoteMsg {
  static const state = 'state';
  static const promptList = 'promptList';
  static const output = 'output';
  static const error = 'error';
  static const notification = 'notification';
}

// ─── Command types (client → server) ────────────────────────────────────────

class RemoteCmd {
  static const start = 'start';
  static const stop = 'stop';
  static const resume = 'resume';
  static const createPrompt = 'createPrompt';
  static const updatePrompt = 'updatePrompt';
  static const deletePrompt = 'deletePrompt';
  static const skipPrompt = 'skipPrompt';
  static const duplicatePrompt = 'duplicatePrompt';
  static const resetPrompt = 'resetPrompt';
}

// ─── Builders ────────────────────────────────────────────────────────────────

Map<String, dynamic> buildStateMsg(ExecState s) => {
      'type': RemoteMsg.state,
      'data': {
        'status': s.status.name,
        'currentPromptId': s.currentPromptId,
        'completedCount': s.completedCount,
        'totalCount': s.totalCount,
        'pendingQuestion': s.pendingQuestion,
      },
    };

Map<String, dynamic> buildPromptListMsg(List<PromptEntry> prompts) => {
      'type': RemoteMsg.promptList,
      'data': prompts.map(_promptToJson).toList(),
    };

Map<String, dynamic> buildOutputMsg(String promptId, String chunk) => {
      'type': RemoteMsg.output,
      'promptId': promptId,
      'chunk': chunk,
    };

Map<String, dynamic> buildErrorMsg(String message) => {
      'type': RemoteMsg.error,
      'message': message,
    };

Map<String, dynamic> buildNotificationMsg(String title, String body) => {
      'type': RemoteMsg.notification,
      'title': title,
      'body': body,
    };

Map<String, dynamic> _promptToJson(PromptEntry p) => {
      'id': p.id,
      'content': p.content,
      'branch': p.branch,
      'priority': p.priority,
      'status': p.status.name,
      'isSkipped': p.isSkipped,
      'output': p.output,
      'projectPath': p.projectPath,
      'sessionId': p.sessionId,
      'claudeModel': p.claudeModel,
      'imagePaths': p.imagePaths,
      'commitAfterRun': p.commitAfterRun,
      'startedAt': p.startedAt?.toIso8601String(),
      'createdAt': p.createdAt.toIso8601String(),
      'updatedAt': p.updatedAt.toIso8601String(),
    };

String encodeMsg(Map<String, dynamic> msg) => jsonEncode(msg);

Map<String, dynamic>? decodeMsg(String raw) {
  try {
    return jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}
