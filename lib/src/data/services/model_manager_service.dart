import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// ─── Data classes ─────────────────────────────────────────────────────────────

class LocalModelInfo {
  const LocalModelInfo({
    required this.name,
    required this.path,
    required this.sizeBytes,
  });
  final String name;
  final String path;
  final int sizeBytes;
}

class DownloadableModel {
  const DownloadableModel({
    required this.id,
    required this.name,
    required this.description,
    required this.sizeLabel,
    required this.url,
  });
  final String id;
  final String name;
  final String description;
  final String sizeLabel;
  final String url;
}

// ─── Curated model list ───────────────────────────────────────────────────────

const kCuratedModels = <DownloadableModel>[
  DownloadableModel(
    id: 'realistic_vision_v6_q8_0',
    name: 'Realistic Vision V6.0 B1',
    description: 'Photorealistic, high detail',
    sizeLabel: '1.8 GB',
    url:
        'https://huggingface.co/second-state/Realistic_Vision_V6.0_B1-GGUF/resolve/main/realisticVisionV60B1_v51HyperVAE-Q8_0.gguf',
  ),
  DownloadableModel(
    id: 'anything_v5_q4_0',
    name: 'Anything V5',
    description: 'Anime / illustration style',
    sizeLabel: '1.6 GB',
    url:
        'https://huggingface.co/genai-archive/anything-v5-gguf/resolve/main/anything-v5.q4_0.gguf',
  ),
  DownloadableModel(
    id: 'dreamshaper_8_lcm',
    name: 'DreamShaper 8 LCM',
    description: 'General / illustration, fast LCM',
    sizeLabel: '1.6 GB',
    url:
        'https://huggingface.co/stduhpf/dreamshaper-8LCM-im-GGUF-sdcpp/resolve/main/dreamshaper_8LCM-iq4_nl.gguf',
  ),
  DownloadableModel(
    id: 'sd_v15_q4_0',
    name: 'Stable Diffusion 1.5',
    description: 'Original baseline model, versatile',
    sizeLabel: '1.6 GB',
    url:
        'https://huggingface.co/second-state/stable-diffusion-v1-5-GGUF/resolve/main/stable-diffusion-v1-5-pruned-emaonly-Q4_0.gguf',
  ),
  DownloadableModel(
    id: 'sd_v21_q8_0',
    name: 'Stable Diffusion 2.1',
    description: 'Improved SD model, 768 px optimized',
    sizeLabel: '2.3 GB',
    url:
        'https://huggingface.co/gpustack/stable-diffusion-v2-1-GGUF/resolve/main/stable-diffusion-v2-1-Q8_0.gguf',
  ),
];

// ─── Service ──────────────────────────────────────────────────────────────────

class ModelManagerService {
  ModelManagerService({Directory? dirOverride}) : _dirOverride = dirOverride;

  final Directory? _dirOverride;
  final _tasks = <String, _DownloadTask>{};

  Future<Directory> modelsDir() async {
    if (_dirOverride != null) return _dirOverride;
    final appSupport = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appSupport.path, 'models'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Stream<List<LocalModelInfo>> watchModels() async* {
    while (true) {
      yield await _listModels();
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  Future<List<LocalModelInfo>> _listModels() async {
    try {
      final dir = await modelsDir();
      final files =
          dir
              .listSync()
              .whereType<File>()
              .where(
                (f) =>
                    f.path.endsWith('.gguf') || f.path.endsWith('.safetensors'),
              )
              .toList()
            ..sort(
              (a, b) => p.basename(a.path).compareTo(p.basename(b.path)),
            );
      return files
          .map(
            (f) => LocalModelInfo(
              name: p.basename(f.path),
              path: f.path,
              sizeBytes: f.lengthSync(),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> downloadModel(
    DownloadableModel model, {
    required void Function(int received, int total) onProgress,
    required void Function(String path) onComplete,
    required void Function(Object error) onError,
  }) async {
    if (_tasks.containsKey(model.id)) return;

    final dir = await modelsDir();
    final fileName = p.basename(model.url);
    final partFile = File(p.join(dir.path, '$fileName.part'));
    final finalFile = File(p.join(dir.path, fileName));
    final task = _DownloadTask(partFile: partFile);
    _tasks[model.id] = task;

    IOSink? sink;
    try {
      final client = http.Client();
      task.client = client;
      final request = http.Request('GET', Uri.parse(model.url));
      final response = await client.send(request);

      final total = response.contentLength ?? -1;
      var received = 0;

      sink = partFile.openWrite();
      task.sink = sink;

      await for (final chunk in response.stream) {
        if (task.cancelled) break;
        sink.add(chunk);
        received += chunk.length;
        onProgress(received, total);
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (!task.cancelled) {
        await partFile.rename(finalFile.path);
        onComplete(finalFile.path);
      } else {
        try {
          partFile.deleteSync();
        } catch (_) {}
      }
    } catch (e) {
      try {
        await sink?.close();
      } catch (_) {}
      try {
        partFile.deleteSync();
      } catch (_) {}
      if (!task.cancelled) onError(e);
    } finally {
      _tasks.remove(model.id);
    }
  }

  void cancelDownload(String modelId) {
    final task = _tasks[modelId];
    if (task == null) return;
    task.cancelled = true;
    try {
      task.client?.close();
    } catch (_) {}
    try {
      task.sink?.close();
    } catch (_) {}
    try {
      task.partFile.deleteSync();
    } catch (_) {}
    _tasks.remove(modelId);
  }
}

class _DownloadTask {
  _DownloadTask({required this.partFile});
  final File partFile;
  http.Client? client;
  IOSink? sink;
  bool cancelled = false;
}
