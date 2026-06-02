import 'dart:async';
import 'dart:io';

import 'package:assibant/src/data/services/model_manager_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

// ─── Helpers ─────────────────────────────────────────────────────────────────

ModelManagerService _svc(Directory dir) =>
    ModelManagerService(dirOverride: dir);

File _touch(Directory dir, String name, {String content = ''}) {
  final f = File(p.join(dir.path, name));
  f.writeAsStringSync(content);
  return f;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  // ── Data classes ────────────────────────────────────────────────────────────

  group('LocalModelInfo', () {
    test('stores name, path and sizeBytes', () {
      const info = LocalModelInfo(
        name: 'model.gguf',
        path: '/models/model.gguf',
        sizeBytes: 1024,
      );
      expect(info.name, 'model.gguf');
      expect(info.path, '/models/model.gguf');
      expect(info.sizeBytes, 1024);
    });
  });

  group('DownloadableModel', () {
    test('stores all fields', () {
      const m = DownloadableModel(
        id: 'test_id',
        name: 'Test Model',
        description: 'A test model',
        sizeLabel: '1.5 GB',
        url: 'https://huggingface.co/example/resolve/main/model.gguf',
      );
      expect(m.id, 'test_id');
      expect(m.name, 'Test Model');
      expect(m.description, 'A test model');
      expect(m.sizeLabel, '1.5 GB');
      expect(m.url, contains('huggingface.co'));
    });
  });

  // ── kCuratedModels ──────────────────────────────────────────────────────────

  group('kCuratedModels', () {
    test('has at least 4 entries', () {
      expect(kCuratedModels.length, greaterThanOrEqualTo(4));
    });

    test('all IDs are unique', () {
      final ids = kCuratedModels.map((m) => m.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('all URLs point to HuggingFace and end with .gguf', () {
      for (final m in kCuratedModels) {
        expect(
          m.url,
          startsWith('https://huggingface.co/'),
          reason: '${m.id} URL should be a HuggingFace URL',
        );
        expect(
          m.url,
          endsWith('.gguf'),
          reason: '${m.id} URL should end with .gguf',
        );
      }
    });

    test('all entries have non-empty name, description and sizeLabel', () {
      for (final m in kCuratedModels) {
        expect(m.name, isNotEmpty, reason: '${m.id} name is empty');
        expect(
          m.description,
          isNotEmpty,
          reason: '${m.id} description is empty',
        );
        expect(m.sizeLabel, isNotEmpty, reason: '${m.id} sizeLabel is empty');
      }
    });
  });

  // ── modelsDir ───────────────────────────────────────────────────────────────

  group('ModelManagerService.modelsDir()', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('model_test_');
    });

    tearDown(() async {
      await tmp.delete(recursive: true);
    });

    test('returns the injected directory', () async {
      final svc = _svc(tmp);
      final dir = await svc.modelsDir();
      expect(dir.path, tmp.path);
    });
  });

  // ── watchModels ─────────────────────────────────────────────────────────────

  group('ModelManagerService.watchModels()', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('model_test_');
    });

    tearDown(() async {
      await tmp.delete(recursive: true);
    });

    test('emits immediately on subscription (empty folder)', () async {
      final svc = _svc(tmp);
      final first = await svc.watchModels().first;
      expect(first, isEmpty);
    });

    test('lists .gguf files', () async {
      _touch(tmp, 'model-a.gguf', content: 'x' * 100);
      _touch(tmp, 'model-b.gguf', content: 'x' * 200);
      final svc = _svc(tmp);
      final models = await svc.watchModels().first;
      final names = models.map((m) => m.name).toSet();
      expect(names, containsAll(['model-a.gguf', 'model-b.gguf']));
    });

    test('lists .safetensors files', () async {
      _touch(tmp, 'weights.safetensors', content: 'y' * 50);
      final svc = _svc(tmp);
      final models = await svc.watchModels().first;
      expect(models.map((m) => m.name), contains('weights.safetensors'));
    });

    test('excludes .gguf.part (in-progress download) files', () async {
      _touch(tmp, 'model.gguf.part');
      _touch(tmp, 'model.gguf', content: 'done');
      final svc = _svc(tmp);
      final models = await svc.watchModels().first;
      expect(models.map((m) => m.name), isNot(contains('model.gguf.part')));
      expect(models.map((m) => m.name), contains('model.gguf'));
    });

    test('excludes unrelated files', () async {
      _touch(tmp, 'readme.txt');
      _touch(tmp, 'config.json');
      final svc = _svc(tmp);
      final models = await svc.watchModels().first;
      expect(models, isEmpty);
    });

    test('reports correct sizeBytes', () async {
      _touch(tmp, 'tiny.gguf', content: 'a' * 42);
      final svc = _svc(tmp);
      final models = await svc.watchModels().first;
      expect(models.first.sizeBytes, 42);
    });

    test('reports absolute path', () async {
      _touch(tmp, 'model.gguf');
      final svc = _svc(tmp);
      final models = await svc.watchModels().first;
      expect(models.first.path, p.join(tmp.path, 'model.gguf'));
    });

    test('returns models sorted alphabetically by name', () async {
      _touch(tmp, 'zzz.gguf');
      _touch(tmp, 'aaa.gguf');
      _touch(tmp, 'mmm.gguf');
      final svc = _svc(tmp);
      final models = await svc.watchModels().first;
      final names = models.map((m) => m.name).toList();
      expect(names, ['aaa.gguf', 'mmm.gguf', 'zzz.gguf']);
    });

    test('emits updated list after a file is added (2nd tick)', () async {
      final svc = _svc(tmp);
      final completer = Completer<List<LocalModelInfo>>();
      var firstReceived = false;

      final sub = svc.watchModels().listen((list) {
        if (!firstReceived) {
          firstReceived = true;
          _touch(tmp, 'new.gguf'); // add file after first empty emit
        } else if (list.isNotEmpty && !completer.isCompleted) {
          completer.complete(list);
        }
      });

      final updated = await completer.future.timeout(
        const Duration(seconds: 8),
      );
      await sub.cancel();
      expect(updated.map((m) => m.name), contains('new.gguf'));
    });
  });

  // ── cancelDownload ───────────────────────────────────────────────────────────

  group('ModelManagerService.cancelDownload()', () {
    test('is a no-op when no download is active for that id', () {
      final svc = ModelManagerService();
      // Should not throw.
      expect(() => svc.cancelDownload('non_existent_id'), returnsNormally);
    });
  });
}
