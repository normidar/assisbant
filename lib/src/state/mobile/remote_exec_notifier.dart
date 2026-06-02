import 'package:flutter_riverpod/flutter_riverpod.dart';

class RemoteExecState {
  const RemoteExecState({
    this.status = 'idle',
    this.currentPromptId,
    this.completedCount = 0,
    this.totalCount = 0,
    this.pendingQuestion,
    this.output = '',
  });

  final String status;
  final String? currentPromptId;
  final int completedCount;
  final int totalCount;
  final String? pendingQuestion;
  final String output;

  bool get isRunning => status == 'running';
  bool get isPaused => status == 'paused';
  bool get isIdle => status == 'idle';

  double get progress => totalCount > 0 ? completedCount / totalCount : 0;

  RemoteExecState copyWith({
    String? status,
    String? currentPromptId,
    int? completedCount,
    int? totalCount,
    String? pendingQuestion,
    String? output,
    bool clearQuestion = false,
    bool clearCurrentId = false,
  }) => RemoteExecState(
    status: status ?? this.status,
    currentPromptId: clearCurrentId
        ? null
        : (currentPromptId ?? this.currentPromptId),
    completedCount: completedCount ?? this.completedCount,
    totalCount: totalCount ?? this.totalCount,
    pendingQuestion: clearQuestion
        ? null
        : (pendingQuestion ?? this.pendingQuestion),
    output: output ?? this.output,
  );
}

final remoteExecProvider =
    NotifierProvider<RemoteExecNotifier, RemoteExecState>(
      RemoteExecNotifier.new,
    );

class RemoteExecNotifier extends Notifier<RemoteExecState> {
  @override
  RemoteExecState build() => const RemoteExecState();

  void update(Map<String, dynamic> data) {
    state = RemoteExecState(
      status: data['status'] as String? ?? 'idle',
      currentPromptId: data['currentPromptId'] as String?,
      completedCount: data['completedCount'] as int? ?? 0,
      totalCount: data['totalCount'] as int? ?? 0,
      pendingQuestion: data['pendingQuestion'] as String?,
      output: state.currentPromptId != data['currentPromptId']
          ? ''
          : state.output,
    );
  }

  void appendOutput(String promptId, String chunk) {
    if (state.currentPromptId == promptId) {
      state = state.copyWith(output: '${state.output}$chunk');
    }
  }

  void reset() => state = const RemoteExecState();
}
