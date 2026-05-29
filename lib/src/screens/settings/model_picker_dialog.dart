import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:assibant/src/app/theme.dart';
import 'package:assibant/src/data/services/model_manager_service.dart';
import 'package:assibant/src/i18n/app_strings.dart';
import 'package:assibant/src/providers/model_manager_providers.dart';

// ─── Main dialog widget ───────────────────────────────────────────────────────

class ModelPickerDialog extends ConsumerStatefulWidget {
  const ModelPickerDialog({
    required this.c,
    required this.s,
    required this.currentPath,
    required this.onSelect,
    super.key,
  });

  final AppColors c;
  final AppStrings s;
  final String currentPath;
  final ValueChanged<String> onSelect;

  @override
  ConsumerState<ModelPickerDialog> createState() => _ModelPickerDialogState();
}

class _ModelPickerDialogState extends ConsumerState<ModelPickerDialog> {
  // keyed by model.id
  final Map<String, ({int received, int total})> _bytes = {};
  final Set<String> _downloading = {};
  final Set<String> _done = {};
  final Map<String, Object> _errors = {};

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final s = widget.s;

    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.border),
      ),
      child: SizedBox(
        width: 560,
        height: 520,
        child: DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── header ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
                child: Row(
                  children: [
                    Text(
                      s.modelPickerTitle,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: c.ink3),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              ),
              // ── tab bar ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: c.surface3,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: c.border),
                  ),
                  child: TabBar(
                    tabs: [
                      Tab(text: s.modelPickerTabLocal),
                      Tab(text: s.modelPickerTabDownload),
                    ],
                    indicator: BoxDecoration(
                      color: c.ink,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: c.ink3,
                    labelStyle: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w500),
                    unselectedLabelStyle:
                        const TextStyle(fontSize: 12.5),
                    splashFactory: NoSplash.splashFactory,
                    overlayColor:
                        WidgetStateProperty.all(Colors.transparent),
                  ),
                ),
              ),
              // ── tab views ───────────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  children: [
                    _LocalModelsTab(
                      c: c,
                      s: s,
                      currentPath: widget.currentPath,
                      onSelect: (path) {
                        widget.onSelect(path);
                        Navigator.pop(context);
                      },
                    ),
                    _DownloadTab(
                      c: c,
                      s: s,
                      bytes: _bytes,
                      downloading: _downloading,
                      done: _done,
                      errors: _errors,
                      onDownload: _startDownload,
                      onCancel: _cancelDownload,
                      onSelect: (path) {
                        widget.onSelect(path);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startDownload(DownloadableModel model) async {
    if (_downloading.contains(model.id)) return;
    setState(() {
      _downloading.add(model.id);
      _errors.remove(model.id);
    });

    await ref.read(modelManagerServiceProvider).downloadModel(
      model,
      onProgress: (received, total) {
        if (mounted) {
          setState(() => _bytes[model.id] = (received: received, total: total));
        }
      },
      onComplete: (path) {
        if (mounted) {
          setState(() {
            _downloading.remove(model.id);
            _done.add(model.id);
            _bytes.remove(model.id);
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _downloading.remove(model.id);
            _errors[model.id] = e;
            _bytes.remove(model.id);
          });
        }
      },
    );
  }

  void _cancelDownload(String modelId) {
    ref.read(modelManagerServiceProvider).cancelDownload(modelId);
    if (mounted) {
      setState(() {
        _downloading.remove(modelId);
        _bytes.remove(modelId);
        _errors.remove(modelId);
      });
    }
  }
}

// ─── Local Models tab ─────────────────────────────────────────────────────────

class _LocalModelsTab extends ConsumerWidget {
  const _LocalModelsTab({
    required this.c,
    required this.s,
    required this.currentPath,
    required this.onSelect,
  });

  final AppColors c;
  final AppStrings s;
  final String currentPath;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelsAsync = ref.watch(modelsWatchProvider);

    return Column(
      children: [
        Expanded(
          child: modelsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(e.toString(),
                  style: TextStyle(fontSize: 12, color: c.ink3)),
            ),
            data: (models) {
              if (models.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      s.modelPickerNoLocal,
                      style: TextStyle(fontSize: 13, color: c.ink3),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: models.length,
                itemBuilder: (context, i) {
                  final m = models[i];
                  final selected = m.path == currentPath;
                  return _LocalModelRow(
                    model: m,
                    selected: selected,
                    c: c,
                    onTap: () => onSelect(m.path),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration:
              BoxDecoration(border: Border(top: BorderSide(color: c.border2))),
          child: Row(
            children: [
              _OutlineBtn(
                label: s.modelPickerOpenFolder,
                c: c,
                onTap: () async {
                  final svc = ref.read(modelManagerServiceProvider);
                  final dir = await svc.modelsDir();
                  await Process.start('open', [dir.path]);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocalModelRow extends StatelessWidget {
  const _LocalModelRow({
    required this.model,
    required this.selected,
    required this.c,
    required this.onTap,
  });

  final LocalModelInfo model;
  final bool selected;
  final AppColors c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? c.accent.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? c.accent : c.border2,
          ),
        ),
        child: Row(
          children: [
            if (selected)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.check_circle, size: 14, color: c.accent),
              ),
            Expanded(
              child: Text(
                model.name,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                    color: c.ink),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _fmtSize(model.sizeBytes),
              style: TextStyle(fontSize: 11.5, color: c.ink3),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtSize(int bytes) {
    if (bytes >= 1 << 30) {
      return '${(bytes / (1 << 30)).toStringAsFixed(2)} GB';
    }
    if (bytes >= 1 << 20) {
      return '${(bytes / (1 << 20)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}

// ─── Download tab ─────────────────────────────────────────────────────────────

class _DownloadTab extends ConsumerWidget {
  const _DownloadTab({
    required this.c,
    required this.s,
    required this.bytes,
    required this.downloading,
    required this.done,
    required this.errors,
    required this.onDownload,
    required this.onCancel,
    required this.onSelect,
  });

  final AppColors c;
  final AppStrings s;
  final Map<String, ({int received, int total})> bytes;
  final Set<String> downloading;
  final Set<String> done;
  final Map<String, Object> errors;
  final Future<void> Function(DownloadableModel) onDownload;
  final void Function(String) onCancel;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localModels = ref.watch(modelsWatchProvider).value ?? [];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: kCuratedModels.length,
      itemBuilder: (context, i) {
        final model = kCuratedModels[i];
        final installedPath = _installedPath(model, localModels);
        final isInstalled = installedPath != null;
        final isDownloading = downloading.contains(model.id);
        final isDone = done.contains(model.id);
        final hasFailed = errors.containsKey(model.id);
        final progress = bytes[model.id];

        return _DownloadModelRow(
          model: model,
          c: c,
          s: s,
          isInstalled: isInstalled || isDone,
          isDownloading: isDownloading,
          hasFailed: hasFailed,
          progress: progress,
          onDownload: () => onDownload(model),
          onCancel: () => onCancel(model.id),
          onSelect: isInstalled
              ? () => onSelect(installedPath)
              : isDone
                  ? null
                  : null,
        );
      },
    );
  }

  static String? _installedPath(
      DownloadableModel model, List<LocalModelInfo> locals) {
    final expected = p.basename(model.url);
    for (final m in locals) {
      if (m.name == expected) return m.path;
    }
    return null;
  }
}

class _DownloadModelRow extends StatelessWidget {
  const _DownloadModelRow({
    required this.model,
    required this.c,
    required this.s,
    required this.isInstalled,
    required this.isDownloading,
    required this.hasFailed,
    required this.progress,
    required this.onDownload,
    required this.onCancel,
    this.onSelect,
  });

  final DownloadableModel model;
  final AppColors c;
  final AppStrings s;
  final bool isInstalled;
  final bool isDownloading;
  final bool hasFailed;
  final ({int received, int total})? progress;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.name,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${model.description}  ·  ${model.sizeLabel}',
                      style: TextStyle(fontSize: 11.5, color: c.ink3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _actionWidget(context),
            ],
          ),
          if (isDownloading && progress != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress!.total > 0
                  ? progress!.received / progress!.total
                  : null,
              backgroundColor: c.surface3,
              color: c.accent,
              minHeight: 3,
            ),
            const SizedBox(height: 4),
            Text(
              _progressLabel(progress!),
              style: TextStyle(fontSize: 11, color: c.ink3),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionWidget(BuildContext context) {
    if (isInstalled) {
      return GestureDetector(
        onTap: onSelect,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: c.accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: 13, color: c.accent),
              const SizedBox(width: 4),
              Text(
                s.modelPickerDownloadDone,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: c.accent),
              ),
            ],
          ),
        ),
      );
    }

    if (isDownloading) {
      return GestureDetector(
        onTap: onCancel,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: c.border),
          ),
          child: Text(
            s.modelPickerCancel,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: c.ink2),
          ),
        ),
      );
    }

    if (hasFailed) {
      return GestureDetector(
        onTap: onDownload,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.red.shade300),
          ),
          child: Text(
            s.modelPickerDownloadFailed,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: Colors.red),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onDownload,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: c.accent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          s.modelPickerDownloadStart,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
        ),
      ),
    );
  }

  static String _progressLabel(({int received, int total}) p) {
    final mb = p.received / (1024 * 1024);
    if (p.total <= 0) return '${mb.toStringAsFixed(1)} MB';
    final gbTotal = p.total / (1024 * 1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB / ${gbTotal.toStringAsFixed(1)} GB';
  }
}

// ─── Shared helper widget ─────────────────────────────────────────────────────

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({
    required this.label,
    required this.c,
    required this.onTap,
  });

  final String label;
  final AppColors c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w500, color: c.ink2),
        ),
      ),
    );
  }
}
