import 'package:assibant/src/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Settings card container ───────────────────────────────────────────────────

class SetCard extends StatelessWidget {
  const SetCard({
    required this.title,
    required this.c,
    required this.children,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final AppColors c;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: TextStyle(fontSize: 12, color: c.ink3)),
                ],
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

// ─── Settings row with a toggle switch ────────────────────────────────────────

class SetRowSwitch extends StatelessWidget {
  const SetRowSwitch({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.c,
    super.key,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border2))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(description,
                    style: TextStyle(fontSize: 11.5, color: c.ink3)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38,
              height: 22,
              decoration: BoxDecoration(
                color: value ? c.accent : c.surface3,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: value ? c.accent : c.border),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 180),
                    left: value ? 17 : 1,
                    top: 1,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 2)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings row with a text input field ─────────────────────────────────────

class SetRowInput extends StatefulWidget {
  const SetRowInput({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.c,
    this.placeholder = '',
    this.onPickFile,
    super.key,
  });

  final String label;
  final String description;
  final String value;
  final ValueChanged<String> onChanged;
  final AppColors c;
  final String placeholder;
  /// When non-null a folder-icon button is shown; calling it should open a
  /// file picker and eventually call [onChanged] with the selected path.
  final Future<void> Function()? onPickFile;

  @override
  State<SetRowInput> createState() => _SetRowInputState();
}

class _SetRowInputState extends State<SetRowInput> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(SetRowInput old) {
    super.didUpdateWidget(old);
    // Sync controller when the value is changed externally (e.g. file picker).
    if (widget.value != old.value && widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
      _ctrl.selection =
          TextSelection.collapsed(offset: widget.value.length);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border2))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(widget.description,
                    style: TextStyle(fontSize: 11.5, color: c.ink3)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 280,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ctrl,
                    onChanged: widget.onChanged,
                    style: GoogleFonts.ibmPlexMono(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      hintStyle: TextStyle(color: c.ink4),
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
                if (widget.onPickFile != null) ...[
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.folder_open_outlined,
                          size: 16, color: c.ink3),
                      tooltip: 'ファイルを選択',
                      onPressed: widget.onPickFile == null
                        ? null
                        : () { widget.onPickFile!(); },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings row with a custom right-side widget ─────────────────────────────

class SetRowWidget extends StatelessWidget {
  const SetRowWidget({
    required this.label,
    required this.description,
    required this.c,
    required this.child,
    super.key,
  });

  final String label;
  final String description;
  final AppColors c;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border2))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(description,
                    style: TextStyle(fontSize: 11.5, color: c.ink3)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          child,
        ],
      ),
    );
  }
}

// ─── Segmented control ────────────────────────────────────────────────────────

class SegControl extends StatelessWidget {
  const SegControl({
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.c,
    super.key,
  });

  final List<(String, String)> items;
  final String selected;
  final ValueChanged<String> onSelect;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surface3,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final (key, label) = item;
          final active = selected == key;
          return GestureDetector(
            onTap: () => onSelect(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: active ? c.ink : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: active ? Colors.white : c.ink3,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Action button for settings rows ─────────────────────────────────────────

class SettingsActionBtn extends StatelessWidget {
  const SettingsActionBtn({
    required this.label,
    required this.onTap,
    required this.c,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: c.ink),
        ),
      ),
    );
  }
}
