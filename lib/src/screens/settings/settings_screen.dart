import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:assibant/src/app/theme.dart';
import 'package:assibant/src/data/services/import_export_service.dart';
import 'package:assibant/src/i18n/app_strings.dart';
import 'package:assibant/src/providers/database_providers.dart';
import 'package:assibant/src/screens/settings/connection_settings_modal.dart';
import 'package:assibant/src/screens/settings/env_overrides_dialog.dart';
import 'package:assibant/src/screens/settings/export_dialog.dart';
import 'package:assibant/src/screens/settings/language_picker.dart';
import 'package:assibant/src/screens/settings/settings_cards.dart';
import 'package:assibant/src/screens/settings/settings_widgets.dart';
import 'package:assibant/src/state/prompt_notifier.dart';
import 'package:assibant/src/state/ui_providers.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({required this.strings, super.key});
  final AppStrings strings;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _toastMessage;

  void _showToast(String msg) {
    setState(() => _toastMessage = msg);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  Future<void> _openConnectionSettings() async {
    await showDialog<void>(
      context: context,
      builder: (_) => ConnectionSettingsModal(
        c: context.ac,
        s: widget.strings,
      ),
    );
  }

  Future<void> _openEnvOverridesDialog() async {
    final settings = ref.read(settingsStateProvider);
    final s = widget.strings;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => EnvOverridesDialog(
        initial: settings.envOverrides,
        strings: s,
        c: context.ac,
      ),
    );
    if (result != null && mounted) {
      ref.read(settingsStateProvider.notifier).update(
            settings.copyWith(envOverrides: result),
          );
    }
  }

  Future<void> _openExportDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => ExportDialog(strings: widget.strings),
    );
    if (result == true && mounted) {
      _showToast(widget.strings.exportSuccess);
    }
  }

  Future<void> _doImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.first.path;
    if (path == null) return;

    try {
      final jsonStr = await File(path).readAsString();
      final entries = ImportExportService.importFromJson(jsonStr);
      final repo = ref.read(promptRepositoryProvider);
      final count = await repo.importBatch(entries);
      ref.invalidate(promptListNotifierProvider);
      if (mounted) _showToast(widget.strings.importSuccessCount(count));
    } catch (_) {
      if (mounted) _showToast(widget.strings.importFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final s = widget.strings;
    final settings = ref.watch(settingsStateProvider);
    final lang = ref.watch(langNotifierProvider);

    void upd(AppSettings updated) =>
        ref.read(settingsStateProvider.notifier).update(updated);

    return Stack(
      children: [
        Column(
          children: [
            // Toolbar
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: c.surface2,
                border: Border(bottom: BorderSide(color: c.border)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(s.settings,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      // Execution card
                      SetCard(
                        title: lang == 'zh'
                            ? '执行配置'
                            : lang == 'ja'
                                ? '実行設定'
                                : 'Execution',
                        subtitle: lang == 'zh'
                            ? '控制 AI 工具如何被调用'
                            : lang == 'ja'
                                ? 'プロンプトの実行設定'
                                : 'Prompt execution settings',
                        c: c,
                        children: [
                          // Connect settings (opens modal)
                          GestureDetector(
                            onTap: _openConnectionSettings,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(
                                  18, 14, 18, 14),
                              decoration: BoxDecoration(
                                border: Border(
                                    bottom:
                                        BorderSide(color: c.border2)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(s.connectSettings,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.w500)),
                                        const SizedBox(height: 2),
                                        Text(s.connectSettingsDesc,
                                            style: TextStyle(
                                                fontSize: 11.5,
                                                color: c.ink3)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        modeSummary(settings),
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: c.ink2),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                          Icons.chevron_right_rounded,
                                          size: 16,
                                          color: c.ink3),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SetRowSwitch(
                            label: s.autoCheckout,
                            description: s.autoCheckoutDesc,
                            value: settings.autoCheckout,
                            onChanged: (v) =>
                                upd(settings.copyWith(autoCheckout: v)),
                            c: c,
                          ),
                          SetRowSwitch(
                            label: s.pauseOnFail,
                            description: s.pauseOnFailDesc,
                            value: settings.pauseOnFail,
                            onChanged: (v) =>
                                upd(settings.copyWith(pauseOnFail: v)),
                            c: c,
                          ),
                          SetRowSwitch(
                            label: s.commitAfterPrompt,
                            description: s.commitAfterPromptDesc,
                            value: settings.commitAfterPrompt,
                            onChanged: (v) =>
                                upd(settings.copyWith(commitAfterPrompt: v)),
                            c: c,
                          ),
                          SetRowWidget(
                            label: s.envOverrides,
                            description: s.envOverridesDesc,
                            c: c,
                            child: SettingsActionBtn(
                              label: settings.envOverrides.isEmpty
                                  ? s.envOverridesNone
                                  : 'Active (${settings.envOverrides.length})',
                              onTap: _openEnvOverridesDialog,
                              c: c,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Appearance card
                      SetCard(
                        title: s.appearance,
                        subtitle: lang == 'zh'
                            ? '语言和主题'
                            : lang == 'ja'
                                ? '言語とテーマ'
                                : 'Language and theme',
                        c: c,
                        children: [
                          LangPickerRow(
                            label: s.language,
                            description: s.languageDesc,
                            c: c,
                          ),
                          SetRowWidget(
                            label: s.theme,
                            description: s.themeDesc,
                            c: c,
                            child: SegControl(
                              items: [
                                (
                                  lang == 'ja'
                                      ? 'ライト'
                                      : lang == 'zh'
                                          ? '浅色'
                                          : 'Light',
                                  lang == 'ja'
                                      ? 'ライト'
                                      : lang == 'zh'
                                          ? '浅色'
                                          : 'Light'
                                ),
                                (
                                  lang == 'ja'
                                      ? 'ダーク'
                                      : lang == 'zh'
                                          ? '深色'
                                          : 'Dark',
                                  lang == 'ja'
                                      ? 'ダーク'
                                      : lang == 'zh'
                                          ? '深色'
                                          : 'Dark'
                                ),
                              ],
                              selected: lang == 'ja'
                                  ? 'ライト'
                                  : lang == 'zh'
                                      ? '浅色'
                                      : 'Light',
                              onSelect: (_) {},
                              c: c,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Data management card
                      SetCard(
                        title: s.dataManagement,
                        subtitle: s.dataManagementDesc,
                        c: c,
                        children: [
                          SetRowWidget(
                            label: s.exportData,
                            description: s.exportDataDesc,
                            c: c,
                            child: SettingsActionBtn(
                              label: s.exportBtn,
                              onTap: _openExportDialog,
                              c: c,
                            ),
                          ),
                          SetRowWidget(
                            label: s.importData,
                            description: s.importDataDesc,
                            c: c,
                            child: SettingsActionBtn(
                              label: s.importBtn,
                              onTap: _doImport,
                              c: c,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Mobile remote control card
                      RemoteControlCard(
                        settings: settings,
                        onUpdate: upd,
                        c: c,
                        lang: lang,
                      ),
                      const SizedBox(height: 14),

                      // Image generation card
                      ImageGenSettingsCard(
                        settings: settings,
                        onUpdate: upd,
                        c: c,
                        s: s,
                      ),
                      const SizedBox(height: 14),

                      // About card
                      SetCard(
                        title: lang == 'zh'
                            ? '关于'
                            : lang == 'ja'
                                ? 'このアプリについて'
                                : 'About',
                        c: c,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(18, 14, 18, 14),
                            child: Row(
                              children: [
                                const Text(
                                  'assisbant',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'v0.1.0',
                                  style: GoogleFonts.ibmPlexMono(
                                    fontSize: 12,
                                    color: c.ink3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_toastMessage != null)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(child: _Toast(message: _toastMessage!)),
          ),
      ],
    );
  }
}

// ─── Toast notification ───────────────────────────────────────────────────────

class _Toast extends StatelessWidget {
  const _Toast({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A17),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 14)],
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 12.5),
      ),
    );
  }
}
