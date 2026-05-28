import 'package:flutter/material.dart';
import 'package:assibant/src/app/theme.dart';
import 'package:assibant/src/i18n/app_strings.dart';
import 'package:google_fonts/google_fonts.dart';

const kDs4Keys = [
  'ANTHROPIC_BASE_URL',
  'ANTHROPIC_AUTH_TOKEN',
  'ANTHROPIC_MODEL',
  'ANTHROPIC_DEFAULT_SONNET_MODEL',
  'ANTHROPIC_DEFAULT_HAIKU_MODEL',
  'ANTHROPIC_DEFAULT_OPUS_MODEL',
  'CLAUDE_CODE_SUBAGENT_MODEL',
  'CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC',
  'CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK',
  'CLAUDE_STREAM_IDLE_TIMEOUT_MS',
];

const kDs4Values = {
  'ANTHROPIC_BASE_URL': 'http://127.0.0.1:8001',
  'ANTHROPIC_AUTH_TOKEN': 'dsv4-local',
  'ANTHROPIC_MODEL': 'deepseek-v4-flash',
  'ANTHROPIC_DEFAULT_SONNET_MODEL': 'deepseek-v4-flash',
  'ANTHROPIC_DEFAULT_HAIKU_MODEL': 'deepseek-v4-flash',
  'ANTHROPIC_DEFAULT_OPUS_MODEL': 'deepseek-v4-flash',
  'CLAUDE_CODE_SUBAGENT_MODEL': 'deepseek-v4-flash',
  'CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC': '1',
  'CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK': '1',
  'CLAUDE_STREAM_IDLE_TIMEOUT_MS': '600000',
};

class EnvOverridesDialog extends StatefulWidget {
  const EnvOverridesDialog({
    required this.initial,
    required this.strings,
    required this.c,
    super.key,
  });

  final Map<String, String> initial;
  final AppStrings strings;
  final AppColors c;

  @override
  State<EnvOverridesDialog> createState() => _EnvOverridesDialogState();
}

class _EnvOverridesDialogState extends State<EnvOverridesDialog> {
  bool _unsetApiKey = false;
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _unsetApiKey = widget.initial['ANTHROPIC_API_KEY'] == '__UNSET__';
    _controllers = {
      for (final key in kDs4Keys)
        key: TextEditingController(
          text: widget.initial.containsKey(key) ? widget.initial[key] : '',
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyDs4Preset() {
    setState(() {
      _unsetApiKey = true;
      for (final key in kDs4Keys) {
        _controllers[key]!.text = kDs4Values[key] ?? '';
      }
    });
  }

  void _clearAll() {
    setState(() {
      _unsetApiKey = false;
      for (final c in _controllers.values) {
        c.clear();
      }
    });
  }

  void _save() {
    final result = <String, String>{};
    if (_unsetApiKey) result['ANTHROPIC_API_KEY'] = '__UNSET__';
    for (final entry in _controllers.entries) {
      final val = entry.value.text.trim();
      if (val.isNotEmpty) result[entry.key] = val;
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final s = widget.strings;

    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.border),
      ),
      child: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.envOverridesTitle,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(null),
                    child: Icon(Icons.close_rounded, size: 18, color: c.ink3),
                  ),
                ],
              ),
            ),
            // Toolbar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _applyDs4Preset,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: c.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s.envOverridesDs4Btn,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _clearAll,
                    child: Text(
                      s.envOverridesClearAll,
                      style: TextStyle(
                          fontSize: 12.5,
                          color: c.ink3,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: c.border2),
            // Body
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          setState(() => _unsetApiKey = !_unsetApiKey),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _unsetApiKey
                                    ? c.accent
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color:
                                      _unsetApiKey ? c.accent : c.border,
                                  width: 1.5,
                                ),
                              ),
                              child: _unsetApiKey
                                  ? const Icon(Icons.check_rounded,
                                      size: 11, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              s.envOverridesUnsetApiKey,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: c.ink),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...kDs4Keys.map(
                      (key) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              key,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: c.ink3,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _controllers[key],
                              style: GoogleFonts.ibmPlexMono(fontSize: 12.5),
                              decoration: InputDecoration(
                                hintText: kDs4Values[key],
                                hintStyle:
                                    TextStyle(color: c.ink4, fontSize: 12),
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
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        border: Border.all(color: c.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s.cancel,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: c.ink2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: c.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s.save,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
