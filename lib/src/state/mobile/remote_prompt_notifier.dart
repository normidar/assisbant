import 'package:flutter_riverpod/flutter_riverpod.dart';

class RemotePromptItem {
  const RemotePromptItem({
    required this.id,
    required this.content,
    required this.branch,
    required this.priority,
    required this.status,
    required this.isSkipped,
    required this.projectPath,
    required this.sessionId,
    required this.claudeModel,
    required this.imagePaths,
    required this.commitAfterRun,
    required this.createdAt,
    required this.updatedAt,
    this.output,
    this.startedAt,
  });

  final String id;
  final String content;
  final String branch;
  final int priority;
  final String status;
  final bool isSkipped;
  final String projectPath;
  final String sessionId;
  final String claudeModel;
  final String imagePaths;
  final bool commitAfterRun;
  final String? output;
  final DateTime? startedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => status == 'pending' && !isSkipped;
  bool get isRunning => status == 'running';
  bool get isDone => status == 'done';
  bool get isFailed => status == 'failed';

  factory RemotePromptItem.fromJson(Map<String, dynamic> j) => RemotePromptItem(
    id: j['id'] as String,
    content: j['content'] as String,
    branch: j['branch'] as String,
    priority: j['priority'] as int,
    status: j['status'] as String,
    isSkipped: j['isSkipped'] as bool,
    projectPath: j['projectPath'] as String? ?? '',
    sessionId: j['sessionId'] as String? ?? '',
    claudeModel: j['claudeModel'] as String? ?? '',
    imagePaths: j['imagePaths'] as String? ?? '',
    commitAfterRun: j['commitAfterRun'] as bool? ?? false,
    output: j['output'] as String?,
    startedAt: j['startedAt'] != null
        ? DateTime.tryParse(j['startedAt'] as String)
        : null,
    createdAt: DateTime.parse(j['createdAt'] as String),
    updatedAt: DateTime.parse(j['updatedAt'] as String),
  );

  Map<String, dynamic> toCommandArgs() => {
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

final remotePromptProvider =
    NotifierProvider<RemotePromptNotifier, List<RemotePromptItem>>(
      RemotePromptNotifier.new,
    );

class RemotePromptNotifier extends Notifier<List<RemotePromptItem>> {
  @override
  List<RemotePromptItem> build() => const [];

  void update(List<Map<String, dynamic>> raw) {
    state = raw.map(RemotePromptItem.fromJson).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  void reset() => state = const [];
}
