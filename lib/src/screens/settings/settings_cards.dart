import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:assibant/src/app/theme.dart';
import 'package:assibant/src/data/services/image_gen_service.dart';
import 'package:assibant/src/i18n/app_strings.dart';
import 'package:assibant/src/providers/database_providers.dart';
import 'package:assibant/src/remote/server/remote_server_service.dart';
import 'package:assibant/src/screens/settings/settings_widgets.dart';
import 'package:assibant/src/state/ui_providers.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Popular SD/Flux model presets ────────────────────────────────────────────
// (display name, Automatic1111 model_name)
const kImageGenPresets = [
  ('SD 1.5',         'v1-5-pruned-emaonly'),
  ('SDXL',           'sd_xl_base_1.0'),
  ('SDXL Turbo',     'sdxl_turbo_1.0_fp16'),
  ('SD 3.5 Medium',  'sd3.5_medium'),
  ('Flux.1-dev',     'flux1-dev'),
  ('Flux.1-schnell', 'flux1-schnell'),
];

// ─── Image Generation settings card ──────────────────────────────────────────

class ImageGenSettingsCard extends ConsumerStatefulWidget {
  const ImageGenSettingsCard({
    required this.settings,
    required this.onUpdate,
    required this.c,
    required this.s,
    super.key,
  });

  final AppSettings settings;
  final void Function(AppSettings) onUpdate;
  final AppColors c;
  final AppStrings s;

  @override
  ConsumerState<ImageGenSettingsCard> createState() =>
      _ImageGenSettingsCardState();
}

class _ImageGenSettingsCardState extends ConsumerState<ImageGenSettingsCard> {
  List<String> _models = [];
  bool _loadingModels = false;
  String? _modelsError;

  Future<void> _refreshModels() async {
    setState(() {
      _loadingModels = true;
      _modelsError = null;
    });
    try {
      final models =
          await ImageGenService.getModels(widget.settings.imageGenApiUrl);
      if (mounted) setState(() => _models = models);
    } catch (e) {
      if (mounted) setState(() => _modelsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingModels = false);
    }
  }

  Future<void> _openCivitai() async {
    await Process.start('open', ['https://civitai.com/models']);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final s = widget.s;
    final settings = widget.settings;

    return SetCard(
      title: s.imageGenSettings,
      subtitle: settings.sdLocalMode ? s.sdLocalModeLabel : s.sdWebApiModeLabel,
      c: c,
      children: [
        // Mode toggle
        _ModeToggleRow(
          localMode: settings.sdLocalMode,
          onChanged: (v) =>
              widget.onUpdate(settings.copyWith(sdLocalMode: v)),
          c: c,
          s: s,
        ),

        if (settings.sdLocalMode) ...[
          // Local mode: dylib + model + VAE paths
          SetRowInput(
            label: s.sdDylibPath,
            description: s.sdDylibPathDesc,
            value: settings.sdDylibPath,
            placeholder: s.sdDylibPathPlaceholder,
            onChanged: (v) =>
                widget.onUpdate(settings.copyWith(sdDylibPath: v.trim())),
            c: c,
          ),
          SetRowInput(
            label: s.sdModelPath,
            description: s.sdModelPathDesc,
            value: settings.sdModelPath,
            placeholder: s.sdModelPathPlaceholder,
            onChanged: (v) =>
                widget.onUpdate(settings.copyWith(sdModelPath: v.trim())),
            c: c,
          ),
          SetRowInput(
            label: s.sdVaePath,
            description: s.sdVaePathDesc,
            value: settings.sdVaePath,
            placeholder: s.sdVaePathPlaceholder,
            onChanged: (v) =>
                widget.onUpdate(settings.copyWith(sdVaePath: v.trim())),
            c: c,
          ),
        ] else ...[
          // Web API mode: Automatic1111 URL + model selector
          SetRowInput(
            label: s.imageGenApiUrl,
            description: s.imageGenApiUrlDesc,
            value: settings.imageGenApiUrl,
            placeholder: s.imageGenApiUrlPlaceholder,
            onChanged: (v) =>
                widget.onUpdate(settings.copyWith(imageGenApiUrl: v.trim())),
            c: c,
          ),
          _ModelSelectorRow(
            settings: settings,
            models: _models,
            loadingModels: _loadingModels,
            modelsError: _modelsError,
            onRefresh: _refreshModels,
            onSelectModel: (m) =>
                widget.onUpdate(settings.copyWith(imageGenModel: m)),
            c: c,
            s: s,
          ),
          _PresetModelsRow(
            settings: settings,
            onSelectModel: (m) =>
                widget.onUpdate(settings.copyWith(imageGenModel: m)),
            c: c,
            s: s,
          ),
          SetRowWidget(
            label: s.imageGenDownloadModels,
            description: s.imageGenDownloadModelsDesc,
            c: c,
            child: SettingsActionBtn(
              label: 'Civitai',
              onTap: _openCivitai,
              c: c,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Mode toggle row ──────────────────────────────────────────────────────────

class _ModeToggleRow extends StatelessWidget {
  const _ModeToggleRow({
    required this.localMode,
    required this.onChanged,
    required this.c,
    required this.s,
  });

  final bool localMode;
  final ValueChanged<bool> onChanged;
  final AppColors c;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border2))),
      child: Row(
        children: [
          Expanded(
            child: Text(
              localMode ? s.sdLocalModeDesc : s.imageGenSettingsDesc,
              style: TextStyle(fontSize: 11.5, color: c.ink3),
            ),
          ),
          const SizedBox(width: 14),
          _ModeChip(
            label: s.sdWebApiModeLabel,
            selected: !localMode,
            onTap: () => onChanged(false),
            c: c,
          ),
          const SizedBox(width: 6),
          _ModeChip(
            label: s.sdLocalModeLabel,
            selected: localMode,
            onTap: () => onChanged(true),
            c: c,
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.c,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? c.accent : c.surface3,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: selected ? c.accent : c.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : c.ink2,
          ),
        ),
      ),
    );
  }
}

class _ModelSelectorRow extends StatelessWidget {
  const _ModelSelectorRow({
    required this.settings,
    required this.models,
    required this.loadingModels,
    required this.modelsError,
    required this.onRefresh,
    required this.onSelectModel,
    required this.c,
    required this.s,
  });

  final AppSettings settings;
  final List<String> models;
  final bool loadingModels;
  final String? modelsError;
  final VoidCallback onRefresh;
  final ValueChanged<String> onSelectModel;
  final AppColors c;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.imageGenModel,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(s.imageGenModelDesc,
                        style: TextStyle(fontSize: 11.5, color: c.ink3)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: loadingModels ? null : onRefresh,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: loadingModels
                      ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: c.ink3),
                        )
                      : Text(s.imageGenRefreshModels,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: c.ink2)),
                ),
              ),
            ],
          ),
          if (modelsError != null) ...[
            const SizedBox(height: 8),
            Text('Error: $modelsError',
                style: const TextStyle(fontSize: 11.5, color: Colors.red)),
          ] else if (models.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: models.map((m) {
                final selected = settings.imageGenModel == m;
                return GestureDetector(
                  onTap: () => onSelectModel(m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: selected ? c.accent : c.surface3,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: selected ? c.accent : c.border),
                    ),
                    child: Text(m,
                        style: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.white : c.ink2,
                        )),
                  ),
                );
              }).toList(),
            ),
          ] else if (!loadingModels) ...[
            const SizedBox(height: 6),
            Text(
              settings.imageGenModel.isNotEmpty
                  ? settings.imageGenModel
                  : 'Click Refresh to load models from the API.',
              style: TextStyle(fontSize: 11.5, color: c.ink4),
            ),
          ],
        ],
      ),
    );
  }
}

class _PresetModelsRow extends StatelessWidget {
  const _PresetModelsRow({
    required this.settings,
    required this.onSelectModel,
    required this.c,
    required this.s,
  });

  final AppSettings settings;
  final ValueChanged<String> onSelectModel;
  final AppColors c;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.imageGenPresetModels,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text('SD 1.5 · SDXL · Flux.1 など。タップでモデル名をセット。',
              style: TextStyle(fontSize: 11.5, color: c.ink3)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: kImageGenPresets.map((preset) {
              final (label, modelId) = preset;
              final selected = settings.imageGenModel == modelId;
              return GestureDetector(
                onTap: () => onSelectModel(modelId),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 130),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: selected ? c.accent : c.surface3,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: selected ? c.accent : c.border),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : c.ink2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (settings.imageGenModel.isNotEmpty &&
              !kImageGenPresets
                  .any((p) => p.$2 == settings.imageGenModel)) ...[
            const SizedBox(height: 8),
            Text('現在: ${settings.imageGenModel}',
                style: TextStyle(fontSize: 11.5, color: c.ink4)),
          ],
        ],
      ),
    );
  }
}

// ─── Remote Control card ──────────────────────────────────────────────────────

class RemoteControlCard extends ConsumerStatefulWidget {
  const RemoteControlCard({
    required this.settings,
    required this.onUpdate,
    required this.c,
    required this.lang,
    super.key,
  });

  final AppSettings settings;
  final void Function(AppSettings) onUpdate;
  final AppColors c;
  final String lang;

  @override
  ConsumerState<RemoteControlCard> createState() => _RemoteControlCardState();
}

class _RemoteControlCardState extends ConsumerState<RemoteControlCard> {
  late TextEditingController _portCtrl;

  @override
  void initState() {
    super.initState();
    _portCtrl =
        TextEditingController(text: widget.settings.remotePort.toString());
  }

  @override
  void dispose() {
    _portCtrl.dispose();
    super.dispose();
  }

  // Collect all translatable strings in one place to avoid repetitive conditionals.
  _RemoteLabels _labels() {
    final lang = widget.lang;
    return _RemoteLabels(
      title: lang == 'zh'
          ? '手机遥控'
          : lang == 'ja'
              ? 'スマホリモコン'
              : 'Mobile Remote Control',
      subtitle: lang == 'zh'
          ? '通过 WiFi 让手机远程控制电脑上的任务'
          : lang == 'ja'
              ? '同一WiFiでスマホからリモートコントロール'
              : 'Control this Mac remotely from phone over WiFi',
      enableLabel: lang == 'zh'
          ? '启用远程连接'
          : lang == 'ja'
              ? 'リモート接続を有効化'
              : 'Enable Remote Connection',
      enableDesc: lang == 'zh'
          ? '在本机启动 WebSocket 服务器并广播 mDNS'
          : lang == 'ja'
              ? 'WebSocketサーバーを起動しmDNSでアドバタイズ'
              : 'Starts a WebSocket server and advertises via mDNS',
      portLabel: lang == 'zh' ? '端口' : lang == 'ja' ? 'ポート番号' : 'Port',
      portDesc: lang == 'zh'
          ? '监听端口 (默认 8765)'
          : lang == 'ja'
              ? 'リッスンポート (デフォルト: 8765)'
              : 'Listen port (default: 8765)',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final lang = widget.lang;
    final labels = _labels();
    final serverState = ref.watch(remoteServerProvider);

    final (statusText, statusColor) = _buildStatus(serverState, lang, c);

    return SetCard(
      title: labels.title,
      subtitle: labels.subtitle,
      c: c,
      children: [
        SetRowSwitch(
          label: labels.enableLabel,
          description: labels.enableDesc,
          value: widget.settings.remoteEnabled,
          onChanged: (v) =>
              widget.onUpdate(widget.settings.copyWith(remoteEnabled: v)),
          c: c,
        ),

        // Port input
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border2))),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(labels.portLabel,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(labels.portDesc,
                        style: TextStyle(fontSize: 11.5, color: c.ink3)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _portCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) {
                    final port = int.tryParse(v);
                    if (port != null && port > 0 && port < 65536) {
                      widget.onUpdate(
                          widget.settings.copyWith(remotePort: port));
                    }
                  },
                  style: GoogleFonts.ibmPlexMono(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 8),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: c.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: c.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: c.ink3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Server status indicator
        Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(statusText,
                    style: TextStyle(fontSize: 12, color: c.ink3)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  (String text, Color color) _buildStatus(
      RemoteServerState serverState, String lang, AppColors c) {
    if (serverState.isRunning) {
      final count = serverState.clientCount;
      final text = lang == 'zh'
          ? '运行中 · 端口 ${serverState.port}${count > 0 ? ' · $count 台设备已连接' : ''}'
          : lang == 'ja'
              ? '稼働中 · ポート ${serverState.port}${count > 0 ? ' · $count 台接続中' : ''}'
              : 'Running · port ${serverState.port}${count > 0 ? ' · $count device(s) connected' : ''}';
      return (text, Colors.green.shade600);
    }
    if (serverState.errorMessage != null) {
      return (serverState.errorMessage!, Colors.red.shade600);
    }
    final stopped =
        lang == 'zh' ? '已停止' : lang == 'ja' ? '停止中' : 'Stopped';
    return (stopped, c.ink3);
  }
}

// ─── Private data class for remote control labels ─────────────────────────────

class _RemoteLabels {
  const _RemoteLabels({
    required this.title,
    required this.subtitle,
    required this.enableLabel,
    required this.enableDesc,
    required this.portLabel,
    required this.portDesc,
  });

  final String title;
  final String subtitle;
  final String enableLabel;
  final String enableDesc;
  final String portLabel;
  final String portDesc;
}
