import 'package:assibant/src/data/database/app_database.dart';
import 'package:assibant/src/data/database/prompt_status.dart';
import 'package:assibant/src/data/repositories/prompt_repository.dart';
import 'package:assibant/src/providers/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final promptListNotifierProvider =
    AsyncNotifierProvider<PromptListNotifier, List<PromptEntry>>(
      PromptListNotifier.new,
    );

/// プロンプトリストの CRUD を管理する AsyncNotifier。
///
/// DB を「信頼の源（source of truth）」として扱う設計:
/// - `build` で DB の全件を取得し、状態の初期値とする
/// - 各ミューテーションは DB を更新した後に `ref.invalidateSelf()` を呼ぶことで
///   `build` を再実行させ、UI が常に DB と同期した状態を保つ
/// - ExecNotifier も実行状態変更後に `ref.invalidate(promptListNotifierProvider)`
///   を呼ぶため、実行中の状態変化も自動的にこのリストに反映される
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
    // 全件取得せず ID で直接1件取得する（テーブルが大きくなっても O(1) クエリ）
    final entry = await _repo.getById(id);
    if (entry == null) return; // 実行中に削除された場合は何もしない
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
    final entry = await _repo.getById(id);
    if (entry == null) return;
    await _repo.setSkipped(id, isSkipped: !entry.isSkipped);
    ref.invalidateSelf();
  }

  Future<void> swapPriority(String idA, String idB) async {
    // 2件とも並列取得して DB ラウンドトリップを最小化する
    final results = await Future.wait([
      _repo.getById(idA),
      _repo.getById(idB),
    ]);
    final a = results[0];
    final b = results[1];
    if (a == null || b == null) return;
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
    final src = await _repo.getById(id);
    if (src == null) return;
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
