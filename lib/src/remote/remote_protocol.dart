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
  static const answerQuestion = 'answerQuestion';
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

// ─── Command builders (client → server) ──────────────────────────────────────
//
// All client→server commands are constructed here so the wire format stays in
// one place. Adding a command without a matching handler case (or vice-versa)
// is the bug class that previously broke remote question answering, so keep
// these builders and `RemoteCommandHandler` in sync.

Map<String, dynamic> buildStartCmd() => {'cmd': RemoteCmd.start};

Map<String, dynamic> buildStopCmd() => {'cmd': RemoteCmd.stop};

Map<String, dynamic> buildResumeCmd() => {'cmd': RemoteCmd.resume};

Map<String, dynamic> buildAnswerQuestionCmd(String answer) => {
      'cmd': RemoteCmd.answerQuestion,
      'answer': answer,
    };

Map<String, dynamic> buildCreatePromptCmd({
  required String content,
  required String branch,
  required String projectPath,
  required int priority,
  required String sessionId,
  String claudeModel = '',
  String imagePaths = '',
  bool commitAfterRun = false,
}) {
  return {
    'cmd': RemoteCmd.createPrompt,
    'content': content,
    'branch': branch,
    'projectPath': projectPath,
    'priority': priority,
    'sessionId': sessionId,
    'claudeModel': claudeModel,
    'imagePaths': imagePaths,
    'commitAfterRun': commitAfterRun,
  };
}

Map<String, dynamic> buildUpdatePromptCmd({
  required String id,
  required String content,
  required String branch,
  required String projectPath,
  required int priority,
  required bool isSkipped,
  required String sessionId,
  String claudeModel = '',
  String imagePaths = '',
  bool commitAfterRun = false,
}) {
  return {
    'cmd': RemoteCmd.updatePrompt,
    'id': id,
    'content': content,
    'branch': branch,
    'projectPath': projectPath,
    'priority': priority,
    'isSkipped': isSkipped,
    'sessionId': sessionId,
    'claudeModel': claudeModel,
    'imagePaths': imagePaths,
    'commitAfterRun': commitAfterRun,
  };
}

/// Builds an id-only prompt command (delete / skip / duplicate / reset).
Map<String, dynamic> buildPromptActionCmd(String cmd, String id) => {
      'cmd': cmd,
      'id': id,
    };

String encodeMsg(Map<String, dynamic> msg) => jsonEncode(msg);

Map<String, dynamic>? decodeMsg(String raw) {
  try {
    return jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}
