import 'package:assibant/src/data/database/app_database.dart';
import 'package:assibant/src/data/database/prompt_status.dart';
import 'package:assibant/src/data/repositories/prompt_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _makeDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late PromptRepository repo;

  setUp(() {
    db = _makeDb();
    repo = PromptRepository(db);
  });

  tearDown(() => db.close());

  group('PromptRepository', () {
    group('insert', () {
      test('creates a prompt with defaults', () async {
        final entry = await repo.insert(
          content: 'Add login page',
          branch: 'feature/auth',
          projectPath: '/tmp/project',
        );

        expect(entry.content, 'Add login page');
        expect(entry.branch, 'feature/auth');
        expect(entry.status, PromptStatus.pending);
        expect(entry.isSkipped, false);
        expect(entry.priority, 10);
        expect(entry.id, isNotEmpty);
      });

      test('auto-increments priority by 10 per entry', () async {
        final a = await repo.insert(
          content: 'Task A',
          branch: 'main',
          projectPath: '/tmp/project',
        );
        final b = await repo.insert(
          content: 'Task B',
          branch: 'main',
          projectPath: '/tmp/project',
        );
        final c = await repo.insert(
          content: 'Task C',
          branch: 'main',
          projectPath: '/tmp/project',
        );

        expect(a.priority, 10);
        expect(b.priority, 20);
        expect(c.priority, 30);
      });

      test('respects explicit priority', () async {
        final entry = await repo.insert(
          content: 'Urgent task',
          branch: 'main',
          projectPath: '/tmp/project',
          priority: 1,
        );
        expect(entry.priority, 1);
      });
    });

    group('getAll', () {
      test('returns prompts ordered by priority ascending', () async {
        await repo.insert(
          content: 'C',
          branch: 'main',
          projectPath: '/tmp/project',
          priority: 30,
        );
        await repo.insert(
          content: 'A',
          branch: 'main',
          projectPath: '/tmp/project',
          priority: 10,
        );
        await repo.insert(
          content: 'B',
          branch: 'main',
          projectPath: '/tmp/project',
          priority: 20,
        );

        final all = await repo.getAll();
        expect(all.map((e) => e.content).toList(), ['A', 'B', 'C']);
      });
    });

    group('getByBranch', () {
      test('filters by branch', () async {
        await repo.insert(
          content: 'Main task',
          branch: 'main',
          projectPath: '/tmp/project',
        );
        await repo.insert(
          content: 'Feature task',
          branch: 'feature/auth',
          projectPath: '/tmp/project',
        );

        final main = await repo.getByBranch('main');
        final feature = await repo.getByBranch('feature/auth');

        expect(main.length, 1);
        expect(main.first.content, 'Main task');
        expect(feature.length, 1);
        expect(feature.first.content, 'Feature task');
      });
    });

    group('getExecutable', () {
      test('excludes done, failed, and skipped prompts', () async {
        final p1 = await repo.insert(
          content: 'Pending',
          branch: 'main',
          projectPath: '/tmp/project',
        );
        final p2 = await repo.insert(
          content: 'Done',
          branch: 'main',
          projectPath: '/tmp/project',
        );
        final p3 = await repo.insert(
          content: 'Skipped',
          branch: 'main',
          projectPath: '/tmp/project',
        );
        final p4 = await repo.insert(
          content: 'Failed',
          branch: 'main',
          projectPath: '/tmp/project',
        );

        await repo.updateStatus(p2.id, PromptStatus.done);
        await repo.setSkipped(p3.id, isSkipped: true);
        await repo.updateStatus(p4.id, PromptStatus.failed);

        final executable = await repo.getExecutable();
        expect(executable.length, 1);
        expect(executable.first.id, p1.id);
      });
    });

    group('updateStatus', () {
      test('changes prompt status', () async {
        final entry = await repo.insert(
          content: 'Task',
          branch: 'main',
          projectPath: '/tmp/project',
        );
        await repo.updateStatus(entry.id, PromptStatus.done);

        final all = await repo.getAll();
        expect(all.first.status, PromptStatus.done);
      });
    });

    group('updatePriority', () {
      test('changes prompt priority', () async {
        final entry = await repo.insert(
          content: 'Task',
          branch: 'main',
          projectPath: '/tmp/project',
        );
        await repo.updatePriority(entry.id, 5);

        final all = await repo.getAll();
        expect(all.first.priority, 5);
      });
    });

    group('setSkipped', () {
      test('marks prompt as skipped', () async {
        final entry = await repo.insert(
          content: 'Task',
          branch: 'main',
          projectPath: '/tmp/project',
        );
        await repo.setSkipped(entry.id, isSkipped: true);

        final all = await repo.getAll();
        expect(all.first.isSkipped, true);
      });

      test('un-skips a prompt', () async {
        final entry = await repo.insert(
          content: 'Task',
          branch: 'main',
          projectPath: '/tmp/project',
        );
        await repo.setSkipped(entry.id, isSkipped: true);
        await repo.setSkipped(entry.id, isSkipped: false);

        final all = await repo.getAll();
        expect(all.first.isSkipped, false);
      });
    });

    group('delete', () {
      test('removes the prompt', () async {
        final entry = await repo.insert(
          content: 'Task',
          branch: 'main',
          projectPath: '/tmp/project',
        );
        await repo.delete(entry.id);

        final all = await repo.getAll();
        expect(all, isEmpty);
      });
    });

    group('getBranchNames', () {
      test('returns unique branch names sorted', () async {
        await repo.insert(
          content: 'A',
          branch: 'main',
          projectPath: '/tmp/project',
        );
        await repo.insert(
          content: 'B',
          branch: 'feature/auth',
          projectPath: '/tmp/project',
        );
        await repo.insert(
          content: 'C',
          branch: 'main',
          projectPath: '/tmp/project',
        );

        final names = await repo.getBranchNames();
        expect(names, ['feature/auth', 'main']);
      });
    });

    group('getBranchSummaries', () {
      test('aggregates prompts by branch correctly', () async {
        await repo.insert(
          content: 'A',
          branch: 'main',
          projectPath: '/tmp/project',
        );
        final b = await repo.insert(
          content: 'B',
          branch: 'main',
          projectPath: '/tmp/project',
        );
        await repo.insert(
          content: 'C',
          branch: 'feature/auth',
          projectPath: '/tmp/project',
        );

        await repo.updateStatus(b.id, PromptStatus.done);

        final summaries = await repo.getBranchSummaries();
        final main = summaries.firstWhere((s) => s.name == 'main');
        final feature = summaries.firstWhere((s) => s.name == 'feature/auth');

        expect(main.totalCount, 2);
        expect(main.pendingCount, 1);
        expect(main.doneCount, 1);
        expect(feature.totalCount, 1);
        expect(feature.pendingCount, 1);
      });
    });

    group('watchAll', () {
      test('emits updated list when a prompt is added', () async {
        final stream = repo.watchAll();

        await repo.insert(
          content: 'Task 1',
          branch: 'main',
          projectPath: '/tmp/project',
        );

        final result = await stream.first;
        expect(result.length, 1);
        expect(result.first.content, 'Task 1');
      });
    });
  });
}
