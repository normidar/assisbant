import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:assibant/src/data/database/app_database.dart';
import 'package:assibant/src/data/database/prompt_status.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

class ImportExportService {
  static const _uuid = Uuid();

  static const _headers = [
    'content', 'branch', 'priority', 'status', 'isSkipped',
    'output', 'projectPath', 'sessionId', 'claudeModel',
  ];

  // A-I covers all 9 columns
  static const _cols = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'];

  // ─── Export methods ─────────────────────────────────────────────────────────

  static String exportToJson(List<PromptEntry> prompts) {
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'prompts': prompts.map(_promptToMap).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static String exportToCsv(List<PromptEntry> prompts) {
    final rows = [
      _headers.join(','),
      ...prompts.map(
        (p) => [
          _csvEscape(p.content),
          _csvEscape(p.branch),
          p.priority.toString(),
          p.status.name,
          p.isSkipped.toString(),
          _csvEscape(p.output ?? ''),
          _csvEscape(p.projectPath),
          _csvEscape(p.sessionId),
          _csvEscape(p.claudeModel),
        ].join(','),
      ),
    ];
    return rows.join('\n');
  }

  /// Produces a real OOXML .xlsx file (ZIP of XMLs).
  static List<int> exportToExcel(List<PromptEntry> prompts) {
    final archive = Archive()
      ..addFile(ArchiveFile.string('[Content_Types].xml', _contentTypesXml))
      ..addFile(ArchiveFile.string('_rels/.rels', _relsXml))
      ..addFile(ArchiveFile.string('xl/workbook.xml', _workbookXml))
      ..addFile(
          ArchiveFile.string('xl/_rels/workbook.xml.rels', _workbookRelsXml))
      ..addFile(ArchiveFile.string('xl/styles.xml', _stylesXml))
      ..addFile(
          ArchiveFile.string('xl/worksheets/sheet1.xml', _sheetXml(prompts)));

    return ZipEncoder().encode(archive);
  }

  // Binary format: magic(4) "ASBB" + version(4 LE) + count(4 LE)
  // + per-prompt: length(4 LE) + UTF-8 JSON bytes
  static Uint8List exportToBinary(List<PromptEntry> prompts) {
    final chunks = prompts
        .map(
          (p) => utf8.encode(const JsonEncoder().convert(_promptToMap(p))),
        )
        .toList();

    final totalSize = 12 + chunks.fold<int>(0, (s, c) => s + 4 + c.length);
    final buf = Uint8List(totalSize);
    final bd = ByteData.sublistView(buf);

    buf[0] = 0x41; buf[1] = 0x53; buf[2] = 0x42; buf[3] = 0x42; // "ASBB"
    bd
      ..setUint32(4, 1, Endian.little) // version
      ..setUint32(8, prompts.length, Endian.little); // count

    var offset = 12;
    for (final chunk in chunks) {
      bd.setUint32(offset, chunk.length, Endian.little);
      offset += 4;
      buf.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }

    return buf;
  }

  // ─── XLSX XML fragments ──────────────────────────────────────────────────────

  static String _sheetXml(List<PromptEntry> prompts) {
    final buf = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write(
          '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">')
      ..write('<sheetData>');

    // header row
    buf.write('<row r="1">');
    for (var i = 0; i < _headers.length; i++) {
      buf.write(
          '<c r="${_cols[i]}1" t="inlineStr"><is><t>${_xmlEsc(_headers[i])}</t></is></c>');
    }
    buf.write('</row>');

    // data rows
    for (var ri = 0; ri < prompts.length; ri++) {
      final p = prompts[ri];
      final row = ri + 2;
      final vals = [
        p.content, p.branch, p.priority.toString(), p.status.name,
        p.isSkipped.toString(), p.output ?? '',
        p.projectPath, p.sessionId, p.claudeModel,
      ];
      buf.write('<row r="$row">');
      for (var ci = 0; ci < vals.length; ci++) {
        buf.write(
            '<c r="${_cols[ci]}$row" t="inlineStr"><is><t>${_xmlEsc(vals[ci])}</t></is></c>');
      }
      buf.write('</row>');
    }

    buf
      ..write('</sheetData>')
      ..write('</worksheet>');
    return buf.toString();
  }

  static const _contentTypesXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
      '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
      '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
      '</Types>';

  static const _relsXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1"'
      ' Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"'
      ' Target="xl/workbook.xml"/>'
      '</Relationships>';

  static const _workbookXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"'
      ' xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
      '<sheets>'
      '<sheet name="Prompts" sheetId="1" r:id="rId1"/>'
      '</sheets>'
      '</workbook>';

  static const _workbookRelsXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1"'
      ' Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"'
      ' Target="worksheets/sheet1.xml"/>'
      '<Relationship Id="rId2"'
      ' Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles"'
      ' Target="styles.xml"/>'
      '</Relationships>';

  static const _stylesXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<fonts count="1"><font><sz val="11"/><name val="Calibri"/></font></fonts>'
      '<fills count="2">'
      '<fill><patternFill patternType="none"/></fill>'
      '<fill><patternFill patternType="gray125"/></fill>'
      '</fills>'
      '<borders count="1">'
      '<border><left/><right/><top/><bottom/><diagonal/></border>'
      '</borders>'
      '<cellStyleXfs count="1">'
      '<xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>'
      '</cellStyleXfs>'
      '<cellXfs count="1">'
      '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
      '</cellXfs>'
      '</styleSheet>';

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _promptToMap(PromptEntry p) => {
        'content': p.content,
        'branch': p.branch,
        'priority': p.priority,
        'status': p.status.name,
        'isSkipped': p.isSkipped,
        'output': p.output,
        'projectPath': p.projectPath,
        'sessionId': p.sessionId,
        'claudeModel': p.claudeModel,
      };

  static String _xmlEsc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  static String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // ─── Import ──────────────────────────────────────────────────────────────────

  static List<PromptsCompanion> importFromJson(String jsonStr) {
    final dynamic decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid format: expected JSON object');
    }
    final promptsRaw = decoded['prompts'];
    if (promptsRaw is! List) {
      throw const FormatException('Invalid format: missing "prompts" array');
    }
    final now = DateTime.now();
    return promptsRaw.map((dynamic raw) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Invalid prompt entry');
      }
      final statusName = raw['status'] as String? ?? 'pending';
      final status = PromptStatus.values.firstWhere(
        (s) => s.name == statusName,
        orElse: () => PromptStatus.pending,
      );
      return PromptsCompanion.insert(
        id: _uuid.v4(),
        content: raw['content'] as String? ?? '',
        branch: raw['branch'] as String? ?? '',
        priority: Value(raw['priority'] as int? ?? 0),
        status: Value(status),
        isSkipped: Value(raw['isSkipped'] as bool? ?? false),
        output: Value(raw['output'] as String?),
        projectPath: Value(raw['projectPath'] as String? ?? ''),
        sessionId: Value(raw['sessionId'] as String? ?? ''),
        claudeModel: Value(raw['claudeModel'] as String? ?? ''),
        createdAt: now,
        updatedAt: now,
      );
    }).toList();
  }
}
