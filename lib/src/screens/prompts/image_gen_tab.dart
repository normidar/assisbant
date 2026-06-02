import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:assibant/src/app/theme.dart';
import 'package:assibant/src/data/services/comfyui_service.dart';
import 'package:assibant/src/data/services/image_gen_service.dart';
import 'package:assibant/src/i18n/app_strings.dart';
import 'package:assibant/src/providers/database_providers.dart';
import 'package:assibant/src/screens/prompts/prompt_form_shared.dart';
import 'package:assibant/src/state/ui_providers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stable_diffusion_ffi/stable_diffusion_ffi.dart';

// ─── Image Generation Tab ──────────────────────────────────────────────────────

class ImageGenTab extends ConsumerStatefulWidget {
  const ImageGenTab({
    required this.strings,
    required this.c,
    required this.onAttach,
    super.key,
  });

  final AppStrings strings;
  final AppColors c;
  final void Function(String imagePath) onAttach;

  @override
  ConsumerState<ImageGenTab> createState() => _ImageGenTabState();
}

class _ImageGenTabState extends ConsumerState<ImageGenTab> {
  final _promptCtrls = <TextEditingController>[TextEditingController()];
  final _negativeCtrl = TextEditingController();

  List<Uint8List?> _results = [];
  List<String?> _recordIds = [];
  bool _generating = false;
  int _generatingIndex = -1;
  String? _lastError;
  bool _infiniteMode = false;
  bool _stopRequested = false;
  int _infiniteIteration = 0;

  int _selectedPreset = 0;
  bool _customMode = false;
  final _customWCtrl = TextEditingController(text: '512');
  final _customHCtrl = TextEditingController(text: '512');
  int _steps = 8;

  static const List<({int h, String ratio, int w})> _presets = [
    (ratio: '1:1',    w: 512,  h: 512),
    (ratio: '3:2',    w: 768,  h: 512),
    (ratio: '2:3',    w: 512,  h: 768),
    (ratio: '4:3',    w: 768,  h: 576),
    (ratio: '3:4',    w: 576,  h: 768),
    (ratio: '16:9',   w: 896,  h: 512),
    (ratio: '9:16',   w: 512,  h: 896),
    (ratio: '1:1 XL', w: 1024, h: 1024),
  ];

  ({String ratio, int w, int h}) get _preset {
    if (_customMode) {
      final w = int.tryParse(_customWCtrl.text) ?? 512;
      final h = int.tryParse(_customHCtrl.text) ?? 512;
      return (ratio: 'custom', w: w.clamp(64, 2048), h: h.clamp(64, 2048));
    }
    return _presets[_selectedPreset];
  }

  bool get _canGenerate =>
      !_generating &&
      _promptCtrls.any((ctrl) => ctrl.text.trim().isNotEmpty);

  @override
  void dispose() {
    for (final ctrl in _promptCtrls) {
      ctrl.dispose();
    }
    _negativeCtrl.dispose();
    _customWCtrl.dispose();
    _customHCtrl.dispose();
    super.dispose();
  }

  void _addPrompt() {
    setState(() => _promptCtrls.add(TextEditingController()));
  }

  void _removePrompt(int index) {
    if (_promptCtrls.length <= 1) return;
    _promptCtrls[index].dispose();
    setState(() {
      _promptCtrls.removeAt(index);
      if (_results.length > index) _results.removeAt(index);
      if (_recordIds.length > index) _recordIds.removeAt(index);
    });
  }

  Future<void> _generateAll() async {
    if (!_canGenerate) return;
    _stopRequested = false;
    setState(() {
      _generating = true;
      _generatingIndex = -1;
      _lastError = null;
      _infiniteIteration = 0;
      _results = List<Uint8List?>.filled(_promptCtrls.length, null);
      _recordIds = List<String?>.filled(_promptCtrls.length, null);
    });

    final settings = ref.read(settingsStateProvider);
    final repo = ref.read(imageGenRepositoryProvider);

    do {
      if (_infiniteMode) {
        setState(() {
          _infiniteIteration++;
          _results = List<Uint8List?>.filled(_promptCtrls.length, null);
          _recordIds = List<String?>.filled(_promptCtrls.length, null);
        });
      }

      for (var i = 0; i < _promptCtrls.length; i++) {
        if (_stopRequested || !mounted) break;
        final prompt = _promptCtrls[i].text.trim();
        if (prompt.isEmpty) continue;
        setState(() => _generatingIndex = i);
        final started = DateTime.now();
        try {
          final ImageGenResult result;
          if (settings.comfyuiEnabled) {
            final r = await ComfyUIService.generate(
              baseUrl: settings.comfyuiUrl,
              prompt: prompt,
              unetName: settings.comfyuiUnetName,
              clipName: settings.comfyuiClipName,
              vaeName: settings.comfyuiVaeName,
              width: _preset.w,
              height: _preset.h,
              steps: _steps,
            );
            result = ImageGenResult(bytes: r.bytes, seed: r.seed);
          } else if (settings.sdLocalMode) {
            final sdResult = await StableDiffusionFfi.generate(
              SdGenerateParams(
                modelPath: settings.sdModelPath,
                dylibPath: settings.sdDylibPath,
                vaePath: settings.sdVaePath,
                prompt: prompt,
                negativePrompt: _negativeCtrl.text.trim(),
                width: _preset.w,
                height: _preset.h,
              ),
            );
            result = ImageGenResult(
                bytes: sdResult.pngBytes, seed: sdResult.seed);
          } else {
            result = await ImageGenService.generate(
              apiUrl: settings.imageGenApiUrl,
              prompt: prompt,
              negativePrompt: _negativeCtrl.text.trim(),
              model: settings.imageGenModel,
              width: _preset.w,
              height: _preset.h,
            );
          }
          final finished = DateTime.now();
          final modelLabel = settings.comfyuiEnabled
              ? settings.comfyuiUnetName
              : settings.sdLocalMode
                  ? settings.sdModelPath.split('/').last
                  : settings.imageGenModel;
          final record = await repo.insert(
            prompt: prompt,
            negativePrompt: _negativeCtrl.text.trim(),
            model: modelLabel,
            width: _preset.w,
            height: _preset.h,
            seed: result.seed,
            steps: _steps,
            generationTimeMs: finished.difference(started).inMilliseconds,
            startedAt: started,
            finishedAt: finished,
            status: 'success',
            iteration: _infiniteMode ? _infiniteIteration : 0,
          );
          if (mounted) {
            setState(() {
              _results[i] = result.bytes;
              _recordIds[i] = record.id;
            });
          }
        } catch (e) {
          final finished = DateTime.now();
          final modelLabel = settings.comfyuiEnabled
              ? settings.comfyuiUnetName
              : settings.sdLocalMode
                  ? settings.sdModelPath.split('/').last
                  : settings.imageGenModel;
          unawaited(repo.insert(
            prompt: prompt,
            negativePrompt: _negativeCtrl.text.trim(),
            model: modelLabel,
            width: _preset.w,
            height: _preset.h,
            steps: _steps,
            generationTimeMs: finished.difference(started).inMilliseconds,
            startedAt: started,
            finishedAt: finished,
            status: 'failed',
            errorMessage: e.toString(),
            iteration: _infiniteMode ? _infiniteIteration : 0,
          ));
          if (mounted) setState(() => _lastError = '#${i + 1}: $e');
        }
      }

      if (_stopRequested || !_infiniteMode) break;
      if (_infiniteMode && mounted && !_stopRequested) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    } while (_infiniteMode && !_stopRequested && mounted);

    if (mounted) {
      setState(() {
        _generating = false;
        _generatingIndex = -1;
      });
    }
  }

  void _stopInfinite() => setState(() => _stopRequested = true);

  Future<void> _saveImage(int index) async {
    final bytes = _results.length > index ? _results[index] : null;
    if (bytes == null) return;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save generated image',
      fileName: 'generated_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    if (path == null) return;
    await File(path).writeAsBytes(bytes);
    if (_recordIds.length > index && _recordIds[index] != null) {
      unawaited(
          ref.read(imageGenRepositoryProvider).updateImagePath(
              _recordIds[index]!, path));
    }
    widget.onAttach(path);
  }

  // ─── Size preview widget ──────────────────────────────────────────────────

  Widget _buildAspectRatioPreview(int w, int h, AppColors c) {
    const boxSize = 72.0;
    const inner = boxSize - 16.0;
    final double rectW;
    final double rectH;
    if (w >= h) {
      rectW = inner;
      rectH = (inner * h / w).clamp(8.0, inner);
    } else {
      rectH = inner;
      rectW = (inner * w / h).clamp(8.0, inner);
    }
    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          width: rectW,
          height: rectH,
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: 0.12),
            border: Border.all(color: c.accent, width: 1.5),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Text(
                '$w×$h',
                key: ValueKey('$w×$h'),
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w600,
                  color: c.accent,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepsSection(AppColors c, AppStrings s) {
    return Row(
      children: [
        Text(
          s.imageGenSteps.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: c.ink4,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Slider(
            value: _steps.toDouble(),
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: c.accent,
            inactiveColor: c.border,
            onChanged: _generating
                ? null
                : (v) => setState(() => _steps = v.round()),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$_steps',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.ink,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildSizeSection(AppColors c, AppStrings s) {
    final p = _preset;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.imageGenSize.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: c.ink4,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...List.generate(_presets.length, (i) {
                    final preset = _presets[i];
                    final selected = !_customMode && _selectedPreset == i;
                    return GestureDetector(
                      onTap: _generating
                          ? null
                          : () => setState(() {
                                _selectedPreset = i;
                                _customMode = false;
                              }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 130),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected ? c.accent : c.surface3,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: selected ? c.accent : c.border),
                        ),
                        child: Text(
                          preset.ratio,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: selected ? Colors.white : c.ink2,
                          ),
                        ),
                      ),
                    );
                  }),
                  // Custom size chip
                  GestureDetector(
                    onTap: _generating
                        ? null
                        : () => setState(() => _customMode = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _customMode ? c.accent : c.surface3,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: _customMode ? c.accent : c.border),
                      ),
                      child: Text(
                        'Custom',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _customMode ? Colors.white : c.ink2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_customMode) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customWCtrl,
                        enabled: !_generating,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 13, color: c.ink),
                        decoration: formInputDeco(c, 'W').copyWith(
                          labelText: 'W',
                          labelStyle:
                              TextStyle(fontSize: 11, color: c.ink4),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('×',
                          style: TextStyle(color: c.ink3, fontSize: 14)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _customHCtrl,
                        enabled: !_generating,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 13, color: c.ink),
                        decoration: formInputDeco(c, 'H').copyWith(
                          labelText: 'H',
                          labelStyle:
                              TextStyle(fontSize: 11, color: c.ink4),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'px',
                      style: TextStyle(fontSize: 11.5, color: c.ink4),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 6),
                Text(
                  '${p.w} × ${p.h} px',
                  style: TextStyle(fontSize: 11.5, color: c.ink4),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 14),
        _buildAspectRatioPreview(p.w, p.h, c),
      ],
    );
  }

  Widget _buildGenerateButton(AppColors c, AppStrings s) {
    final activeCount = _promptCtrls
        .where((ctrl) => ctrl.text.trim().isNotEmpty)
        .length;
    final enabled = _canGenerate;

    String progressText() {
      if (_generatingIndex < 0) return s.imageGenGenerating;
      final prog =
          s.imageGenProgressOf(_generatingIndex + 1, _promptCtrls.length);
      if (_infiniteMode && _infiniteIteration > 0) {
        return '${s.imageGenLoopIteration(_infiniteIteration)}  ·  $prog';
      }
      return prog;
    }

    return GestureDetector(
      onTap: enabled ? _generateAll : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: enabled ? c.accent : c.surface3,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: enabled ? c.accent : c.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_generating) ...[
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: c.ink3),
              ),
              const SizedBox(width: 8),
              Text(
                progressText(),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.ink3),
              ),
            ] else ...[
              Icon(Icons.auto_awesome_outlined,
                  size: 14, color: enabled ? Colors.white : c.ink4),
              const SizedBox(width: 6),
              Text(
                s.imageGenGenerateAllCount(activeCount),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: enabled ? Colors.white : c.ink4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final s = widget.strings;
    final hasResults = _results.isNotEmpty && _results.any((r) => r != null);

    final settings = ref.watch(settingsStateProvider);
    final isComfyUI = settings.comfyuiEnabled;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Negative prompt (hidden in ComfyUI mode — uses zeroed conditioning)
          if (!isComfyUI) ...[
            PromptFormField(
              label: s.imageGenNegative,
              child: TextField(
                controller: _negativeCtrl,
                maxLines: 2,
                minLines: 1,
                style: GoogleFonts.ibmPlexMono(fontSize: 12.5),
                decoration: formInputDeco(c, s.imageGenNegativePlaceholder),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _buildSizeSection(c, s),
          const SizedBox(height: 12),
          // Steps control (always shown in ComfyUI mode)
          if (isComfyUI) _buildStepsSection(c, s),
          if (isComfyUI) const SizedBox(height: 16),
          if (!isComfyUI) const SizedBox(height: 4),

          // Prompt list header
          Row(
            children: [
              Text(
                s.imageGenPrompt.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: c.ink4,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _generating ? null : _addPrompt,
                child: Container(
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 11, color: c.ink3),
                      const SizedBox(width: 3),
                      Text(s.imageGenAddPrompt,
                          style: TextStyle(fontSize: 11, color: c.ink3)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Prompt text fields
          ...List.generate(_promptCtrls.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Index badge
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 9, right: 8),
                    decoration: BoxDecoration(
                      color: c.surface3,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: c.ink3,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _promptCtrls[i],
                      maxLines: 2,
                      minLines: 1,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.ibmPlexMono(fontSize: 12.5),
                      decoration:
                          formInputDeco(c, s.imageGenPromptPlaceholder),
                    ),
                  ),
                  if (_promptCtrls.length > 1)
                    GestureDetector(
                      onTap: _generating ? null : () => _removePrompt(i),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6, top: 10),
                        child: Icon(Icons.close, size: 16, color: c.ink3),
                      ),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),

          // Infinite mode toggle
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _infiniteMode,
                  onChanged: _generating
                      ? null
                      : (v) => setState(() => _infiniteMode = v ?? false),
                  activeColor: c.accent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                s.imageGenInfiniteMode,
                style: TextStyle(fontSize: 12.5, color: c.ink2),
              ),
              if (_infiniteMode && _infiniteIteration > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    s.imageGenLoopIteration(_infiniteIteration),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.accent,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          _buildGenerateButton(c, s),

          // Stop button (infinite mode only)
          if (_generating && _infiniteMode) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _stopRequested ? null : _stopInfinite,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _stopRequested
                      ? Colors.grey.shade100
                      : Colors.red.shade50,
                  border: Border.all(
                    color: _stopRequested
                        ? Colors.grey.shade300
                        : Colors.red.shade200,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.stop_circle_outlined,
                      size: 14,
                      color: _stopRequested
                          ? Colors.grey.shade400
                          : Colors.red.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.stop,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _stopRequested
                            ? Colors.grey.shade400
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Error banner
          if (_lastError != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      size: 14, color: Colors.red.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SelectableText(
                      _lastError!,
                      style: TextStyle(
                          fontSize: 11.5, color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Results
          if (hasResults) ...[
            const SizedBox(height: 16),
            Divider(color: c.border2),
            const SizedBox(height: 8),
            ...List.generate(_results.length, (i) {
              final bytes = _results[i];
              if (bytes == null) return const SizedBox.shrink();
              final promptPreview = _promptCtrls.length > i
                  ? _promptCtrls[i].text.trim()
                  : '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: c.accent,
                            ),
                          ),
                        ),
                        if (promptPreview.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              promptPreview,
                              style: TextStyle(
                                  fontSize: 11.5, color: c.ink3),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(bytes, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _saveImage(i),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: c.border),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_alt_outlined,
                                size: 13, color: c.ink2),
                            const SizedBox(width: 5),
                            Text(
                              '${s.imageGenSave}  ·  ${s.imageGenAttach}',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: c.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else if (!_generating) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: c.surface2,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Icons.image_outlined, size: 28, color: c.ink4),
                  const SizedBox(height: 8),
                  Text(
                    s.imageGenIdle,
                    style: TextStyle(fontSize: 12.5, color: c.ink4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Image path chip ──────────────────────────────────────────────────────────

class ImageChip extends StatelessWidget {
  const ImageChip({
    required this.path,
    required this.onRemove,
    required this.c,
    super.key,
  });

  final String path;
  final VoidCallback onRemove;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    final name = path.split('/').last;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 12, color: c.ink3),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              name,
              style: TextStyle(fontSize: 12, color: c.ink2),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 12, color: c.ink3),
          ),
        ],
      ),
    );
  }
}
