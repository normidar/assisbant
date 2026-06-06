import 'dart:async';
import 'dart:io';

import 'package:assibant/src/app/theme.dart';
import 'package:assibant/src/i18n/app_strings.dart';
import 'package:assibant/src/state/ui_providers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mlx_llm/mlx_llm.dart';

enum _State { idle, loading, generating, done, error }

/// ローカルMLX推論のテスト画面。
///
/// 設定画面の「テスト推論」ボタンから開くダイアログです。
/// MLXモデルのロード、プロンプト入力、ストリーミング生成を試せます。
class MlxInferenceScreen extends ConsumerStatefulWidget {
  const MlxInferenceScreen({required this.strings, super.key});
  final AppStrings strings;

  @override
  ConsumerState<MlxInferenceScreen> createState() =>
      _MlxInferenceScreenState();
}

class _MlxInferenceScreenState extends ConsumerState<MlxInferenceScreen> {
  final _promptCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  _State _state = _State.idle;
  String _output = '';
  String? _errorMsg;
  bool _modelLoaded = false;

  AppStrings get s => widget.strings;

  @override
  void dispose() {
    _promptCtrl.dispose();
    _scrollCtrl.dispose();
    // 生成中のままダイアログを閉じた場合はキャンセルする
    MlxLlm.cancelGeneration().ignore();
    super.dispose();
  }

  Future<void> _loadModel() async {
    final settings = ref.read(settingsStateProvider);
    final dir = settings.mlxModelDir;
    if (dir.isEmpty) return;

    setState(() {
      _state = _State.loading;
      _errorMsg = null;
    });
    try {
      await MlxLlm.loadModel(dir);
      if (mounted) setState(() { _state = _State.idle; _modelLoaded = true; });
    } catch (e) {
      if (mounted) setState(() { _state = _State.error; _errorMsg = e.toString(); });
    }
  }

  Future<void> _generate() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty || _state == _State.generating) return;

    setState(() {
      _state = _State.generating;
      _output = '';
      _errorMsg = null;
    });

    try {
      await for (final token in MlxLlm.generate(prompt)) {
        if (!mounted) break;
        setState(() => _output += token);
        _scrollToBottom();
      }
      if (mounted) setState(() => _state = _State.done);
    } on UnsupportedError catch (e) {
      if (mounted) setState(() { _state = _State.error; _errorMsg = e.message; });
    } catch (e) {
      if (mounted) setState(() { _state = _State.error; _errorMsg = e.toString(); });
    }
  }

  void _cancel() {
    MlxLlm.cancelGeneration().ignore();
    setState(() => _state = _State.done);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients &&
          _scrollCtrl.position.pixels < _scrollCtrl.position.maxScrollExtent) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickModelDir() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: s.mlxModelDir,
    );
    if (result == null || !mounted) return;
    final settings = ref.read(settingsStateProvider);
    ref
        .read(settingsStateProvider.notifier)
        .update(settings.copyWith(mlxModelDir: result));
    setState(() { _modelLoaded = false; _state = _State.idle; });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final settings = ref.watch(settingsStateProvider);
    final modelDir = settings.mlxModelDir;
    final isGenerating = _state == _State.generating;
    final isLoading = _state == _State.loading;
    final canGenerate = _modelLoaded && !isGenerating && !isLoading;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 700,
        height: 540,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(title: s.mlxTestInference, c: c),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ModelRow(
                      modelDir: modelDir,
                      modelLoaded: _modelLoaded,
                      isLoading: isLoading,
                      s: s,
                      c: c,
                      onLoad: _loadModel,
                      onPick: _pickModelDir,
                    ),
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _errorMsg!,
                        style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _promptCtrl,
                      enabled: !isGenerating && !isLoading,
                      decoration: InputDecoration(
                        hintText: s.mlxGenPromptHint,
                        hintStyle: TextStyle(fontSize: 13, color: c.ink3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: c.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: c.border),
                        ),
                        contentPadding: const EdgeInsets.all(10),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isGenerating)
                          TextButton(
                            onPressed: _cancel,
                            child: Text(
                              s.cancel,
                              style: TextStyle(color: Colors.red.shade600, fontSize: 13),
                            ),
                          )
                        else
                          ElevatedButton(
                            onPressed: canGenerate ? _generate : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8,
                              ),
                            ),
                            child: Text(s.mlxGenerate, style: const TextStyle(fontSize: 13)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: c.surface2,
                          border: Border.all(color: c.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          controller: _scrollCtrl,
                          child: SelectableText(
                            _output,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: c.ink,
                              height: 1.6,
                              fontFamily: 'ui-monospace',
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isGenerating)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 10, height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: c.ink3,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              s.mlxGenerating,
                              style: TextStyle(fontSize: 11, color: c.ink3),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.c});
  final String title;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: c.ink3),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _ModelRow extends StatelessWidget {
  const _ModelRow({
    required this.modelDir,
    required this.modelLoaded,
    required this.isLoading,
    required this.s,
    required this.c,
    required this.onLoad,
    required this.onPick,
  });

  final String modelDir;
  final bool modelLoaded;
  final bool isLoading;
  final AppStrings s;
  final AppColors c;
  final VoidCallback onLoad;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            modelDir.isEmpty ? s.mlxNotLoaded : modelDir,
            style: TextStyle(
              fontSize: 11.5,
              color: modelDir.isEmpty ? c.ink3 : c.ink2,
              fontFamily: 'ui-monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        // フォルダ選択ボタン
        IconButton(
          icon: Icon(Icons.folder_open, size: 16, color: c.ink3),
          onPressed: onPick,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: s.pickFolder,
        ),
        const SizedBox(width: 6),
        if (isLoading)
          SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: c.ink3),
          )
        else if (modelLoaded)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 14, color: Colors.green.shade600),
              const SizedBox(width: 3),
              Text(
                s.mlxModelReady,
                style: TextStyle(fontSize: 11, color: Colors.green.shade700),
              ),
            ],
          )
        else
          TextButton(
            onPressed: modelDir.isEmpty ? null : onLoad,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(s.mlxLoadModel, style: const TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}
