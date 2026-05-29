import 'package:flutter_test/flutter_test.dart';
import 'package:assibant/src/data/database/app_database.dart';
import 'package:assibant/src/data/database/prompt_status.dart';
import 'package:assibant/src/screens/prompts/prompt_filter_helpers.dart';

// ─── Fixture builder ─────────────────────────────────────────────────────────

PromptEntry _entry({
  String id = 'id',
  String content = 'content',
  String branch = 'main',
  int priority = 10,
  PromptStatus status = PromptStatus.pending,
  bool isSkipped = false,
  String projectPath = '',
  DateTime? updatedAt,
}) =>
    PromptEntry(
      id: id,
      content: content,
      branch: branch,
      priority: priority,
      status: status,
      isSkipped: isSkipped,
      output: null,
      projectPath: projectPath,
      sessionId: '',
      claudeSessionId: '',
      claudeModel: '',
      imagePaths: '',
      commitAfterRun: false,
      startedAt: null,
      createdAt: DateTime(2024),
      updatedAt: updatedAt ?? DateTime(2024),
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── computePromptMetadata ─────────────────────────────────────────────────

  group('computePromptMetadata', () {
    test('returns empty collections and zero priority for empty list', () {
      final (branches, paths, max) = computePromptMetadata([]);
      expect(branches, isEmpty);
      expect(paths, isEmpty);
      expect(max, 0);
    });

    test('returns single branch and correct max priority', () {
      final (branches, _, max) = computePromptMetadata([
        _entry(branch: 'main', priority: 42),
      ]);
      expect(branches, ['main']);
      expect(max, 42);
    });

    test('returns unique branches sorted by most-recently-updated first', () {
      final older = DateTime(2024, 1, 1);
      final newer = DateTime(2024, 6, 1);
      final (branches, _, _) = computePromptMetadata([
        _entry(id: '1', branch: 'old-branch', updatedAt: older),
        _entry(id: '2', branch: 'new-branch', updatedAt: newer),
      ]);
      expect(branches, ['new-branch', 'old-branch']);
    });

    test('uses the latest updatedAt when a branch has multiple prompts', () {
      final early = DateTime(2024, 1, 1);
      final late = DateTime(2024, 12, 31);
      final (branches, _, _) = computePromptMetadata([
        _entry(id: '1', branch: 'alpha', updatedAt: early),
        _entry(id: '2', branch: 'beta', updatedAt: early),
        _entry(id: '3', branch: 'alpha', updatedAt: late),
      ]);
      // alpha has a newer updatedAt than beta → alpha should come first
      expect(branches.first, 'alpha');
    });

    test('excludes prompts with empty projectPath from path list', () {
      final (_, paths, _) = computePromptMetadata([
        _entry(id: '1', projectPath: ''),
        _entry(id: '2', projectPath: '/repo/foo'),
      ]);
      expect(paths, ['/repo/foo']);
    });

    test('sorts project paths by most-recently-updated first', () {
      final older = DateTime(2024, 1, 1);
      final newer = DateTime(2024, 6, 1);
      final (_, paths, _) = computePromptMetadata([
        _entry(id: '1', projectPath: '/old', updatedAt: older),
        _entry(id: '2', projectPath: '/new', updatedAt: newer),
      ]);
      expect(paths, ['/new', '/old']);
    });

    test('returns max priority across all prompts', () {
      final (_, _, max) = computePromptMetadata([
        _entry(id: '1', priority: 5),
        _entry(id: '2', priority: 99),
        _entry(id: '3', priority: 30),
      ]);
      expect(max, 99);
    });
  });

  // ── applyProjectAndBranchFilter ───────────────────────────────────────────

  group('applyProjectAndBranchFilter', () {
    final prompts = [
      _entry(id: '1', branch: 'main', projectPath: '/a'),
      _entry(id: '2', branch: 'dev', projectPath: '/a'),
      _entry(id: '3', branch: 'main', projectPath: '/b'),
    ];

    test('returns all prompts when both filters are null', () {
      final result = applyProjectAndBranchFilter(prompts, null, null);
      expect(result.length, 3);
    });

    test('filters by project path only', () {
      final result = applyProjectAndBranchFilter(prompts, '/a', null);
      expect(result.map((p) => p.id).toSet(), {'1', '2'});
    });

    test('filters by branch only', () {
      final result = applyProjectAndBranchFilter(prompts, null, 'main');
      expect(result.map((p) => p.id).toSet(), {'1', '3'});
    });

    test('applies both filters together (AND semantics)', () {
      final result = applyProjectAndBranchFilter(prompts, '/a', 'main');
      expect(result.map((p) => p.id).toList(), ['1']);
    });

    test('returns empty list when no prompts match', () {
      final result = applyProjectAndBranchFilter(prompts, '/nonexistent', null);
      expect(result, isEmpty);
    });
  });

  // ── applyPromptFilters ────────────────────────────────────────────────────

  group('applyPromptFilters', () {
    final now = DateTime(2024);
    final prompts = [
      _entry(id: 'p', content: 'pending task', branch: 'main',
          priority: 30, status: PromptStatus.pending),
      _entry(id: 'r', content: 'running task', branch: 'dev',
          priority: 20, status: PromptStatus.running),
      _entry(id: 'd', content: 'done task', branch: 'main',
          priority: 10, status: PromptStatus.done),
      _entry(id: 'f', content: 'failed task', branch: 'feature',
          priority: 5, status: PromptStatus.failed),
      _entry(id: 's', content: 'skipped task', branch: 'main',
          priority: 15, isSkipped: true, status: PromptStatus.pending),
    ];

    test('filter=all returns all prompts sorted by priority desc', () {
      final result = applyPromptFilters(prompts, null, null, '', 'all');
      expect(result.map((p) => p.id).toList(), ['p', 'r', 's', 'd', 'f']);
    });

    test('filter=pending excludes skipped and non-pending', () {
      final result = applyPromptFilters(prompts, null, null, '', 'pending');
      expect(result.map((p) => p.id).toList(), ['p']);
    });

    test('filter=running returns only running prompts', () {
      final result = applyPromptFilters(prompts, null, null, '', 'running');
      expect(result.map((p) => p.id).toList(), ['r']);
    });

    test('filter=done returns only done prompts', () {
      final result = applyPromptFilters(prompts, null, null, '', 'done');
      expect(result.map((p) => p.id).toList(), ['d']);
    });

    test('filter=failed returns only failed prompts', () {
      final result = applyPromptFilters(prompts, null, null, '', 'failed');
      expect(result.map((p) => p.id).toList(), ['f']);
    });

    test('filter=skipped returns only skipped prompts', () {
      final result = applyPromptFilters(prompts, null, null, '', 'skipped');
      expect(result.map((p) => p.id).toList(), ['s']);
    });

    test('query matches content case-insensitively', () {
      final result = applyPromptFilters(prompts, null, null, 'PENDING', 'all');
      expect(result.map((p) => p.id).toList(), ['p', 's']);
    });

    test('query matches branch name', () {
      final result = applyPromptFilters(prompts, null, null, 'feature', 'all');
      expect(result.map((p) => p.id).toList(), ['f']);
    });

    test('branch filter narrows results before status filter', () {
      final result = applyPromptFilters(prompts, null, 'main', '', 'pending');
      // 'main' has: p (pending), d (done), s (skipped). filter=pending → only p
      expect(result.map((p) => p.id).toList(), ['p']);
    });

    test('result is sorted by priority descending', () {
      final result = applyPromptFilters(prompts, null, null, '', 'all');
      final priorities = result.map((p) => p.priority).toList();
      expect(priorities, orderedEquals([30, 20, 15, 10, 5]));
    });

    test('empty query with filter=all returns everything', () {
      final result = applyPromptFilters(prompts, null, null, '', 'all');
      expect(result.length, prompts.length);
    });

    test('query + status filter combine correctly', () {
      final result =
          applyPromptFilters(prompts, null, null, 'task', 'done');
      expect(result.map((p) => p.id).toList(), ['d']);
    });
  });

  // ── computePromptCounts ───────────────────────────────────────────────────

  group('computePromptCounts', () {
    test('all zeros for empty list', () {
      final counts = computePromptCounts([]);
      expect(counts['all'], 0);
      expect(counts['pending'], 0);
      expect(counts['running'], 0);
      expect(counts['done'], 0);
      expect(counts['failed'], 0);
      expect(counts['skipped'], 0);
    });

    test('counts each status correctly', () {
      final prompts = [
        _entry(id: '1', status: PromptStatus.pending),
        _entry(id: '2', status: PromptStatus.running),
        _entry(id: '3', status: PromptStatus.done),
        _entry(id: '4', status: PromptStatus.failed),
        _entry(id: '5', isSkipped: true, status: PromptStatus.pending),
      ];
      final counts = computePromptCounts(prompts);
      expect(counts['all'], 5);
      expect(counts['pending'], 1);
      expect(counts['running'], 1);
      expect(counts['done'], 1);
      expect(counts['failed'], 1);
      expect(counts['skipped'], 1);
    });

    test('skipped prompts increment skipped, not their status bucket', () {
      final prompts = [
        _entry(id: '1', status: PromptStatus.pending, isSkipped: true),
        _entry(id: '2', status: PromptStatus.failed, isSkipped: true),
      ];
      final counts = computePromptCounts(prompts);
      expect(counts['skipped'], 2);
      expect(counts['pending'], 0);
      expect(counts['failed'], 0);
      expect(counts['all'], 2);
    });

    test('multiple prompts in the same status accumulate correctly', () {
      final prompts = [
        _entry(id: '1', status: PromptStatus.done),
        _entry(id: '2', status: PromptStatus.done),
        _entry(id: '3', status: PromptStatus.done),
      ];
      final counts = computePromptCounts(prompts);
      expect(counts['done'], 3);
      expect(counts['all'], 3);
    });
  });
}
