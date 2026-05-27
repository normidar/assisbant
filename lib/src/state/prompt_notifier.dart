import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterapptemp/src/data/database/app_database.dart';
import 'package:flutterapptemp/src/data/database/prompt_status.dart';
import 'package:flutterapptemp/src/data/repositories/prompt_repository.dart';
import 'package:flutterapptemp/src/providers/database_providers.dart';

final promptListNotifierProvider =
    AsyncNotifierProvider<PromptListNotifier, List<PromptEntry>>(
  PromptListNotifier.new,
);

class PromptListNotifier extends AsyncNotifier<List<PromptEntry>> {
  PromptRepository get _repo => ref.read(promptRepositoryProvider);

  @override
  Future<List<PromptEntry>> build() => _repo.getAll();

  Future<void> add({
    required String content,
    required String branch,
    required String projectPath,
    int? priority,
    String sessionId = '',
    String claudeModel = '',
    String imagePaths = '',
    bool commitAfterRun = false,
  }) async {
    await _repo.insert(
      content: content,
      branch: branch,
      projectPath: projectPath,
      priority: priority,
      sessionId: sessionId,
      claudeModel: claudeModel,
      imagePaths: imagePaths,
      commitAfterRun: commitAfterRun,
    );
    ref.invalidateSelf();
  }

  Future<void> addBatch({
    required List<String> contents,
    required String branch,
    required String projectPath,
    int? basePriority,
    String sessionId = '',
    String claudeModel = '',
    String imagePaths = '',
    bool commitAfterRun = false,
  }) async {
    for (var i = 0; i < contents.length; i++) {
      await _repo.insert(
        content: contents[i],
        branch: branch,
        projectPath: projectPath,
        priority: basePriority != null ? basePriority + i : null,
        sessionId: sessionId,
        claudeModel: claudeModel,
        imagePaths: imagePaths,
        commitAfterRun: commitAfterRun,
      );
    }
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    ref.invalidateSelf();
  }

  Future<void> save({
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
  }) async {
    final all = await _repo.getAll();
    final entry = all.firstWhere((p) => p.id == id);
    await _repo.update(
      entry.copyWith(
        content: content,
        branch: branch,
        projectPath: projectPath,
        priority: priority,
        isSkipped: isSkipped,
        sessionId: sessionId,
        claudeModel: claudeModel,
        imagePaths: imagePaths,
        commitAfterRun: commitAfterRun,
        updatedAt: DateTime.now(),
      ),
    );
    ref.invalidateSelf();
  }

  Future<void> toggleSkip(String id) async {
    final all = await _repo.getAll();
    final entry = all.firstWhere((p) => p.id == id);
    await _repo.setSkipped(id, isSkipped: !entry.isSkipped);
    ref.invalidateSelf();
  }

  Future<void> swapPriority(String idA, String idB) async {
    final all = await _repo.getAll();
    final a = all.firstWhere((p) => p.id == idA);
    final b = all.firstWhere((p) => p.id == idB);
    await _repo.updatePriority(idA, b.priority);
    await _repo.updatePriority(idB, a.priority);
    ref.invalidateSelf();
  }

  Future<void> updateStatus(String id, PromptStatus status) async {
    await _repo.updateStatus(id, status);
    ref.invalidateSelf();
  }

  Future<void> reset(String id) async {
    await _repo.resetStatus(id);
    ref.invalidateSelf();
  }

  Future<void> duplicate(String id) async {
    final all = await _repo.getAll();
    final src = all.firstWhere((p) => p.id == id);
    await _repo.insert(
      content: src.content,
      branch: src.branch,
      projectPath: src.projectPath,
      sessionId: src.sessionId,
      claudeModel: src.claudeModel,
      imagePaths: src.imagePaths,
      commitAfterRun: src.commitAfterRun,
    );
    ref.invalidateSelf();
  }
}
