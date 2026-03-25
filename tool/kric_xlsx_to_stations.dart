// KRIC XLSX(전체_도시철도역사정보) → assets/stations_metro_kric.json
// excel 패키지가 일부 XLSX에서 깨지므로 archive+xml 로 직접 읽습니다.
// 실행: dart run tool/kric_xlsx_to_stations.dart [경로.xlsx]

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

int generateId(String name, String line) {
  return ('$name$line').hashCode.abs() % 100000;
}

String normalizeLine(String raw) {
  var s = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (s.contains('1호선') && (s.contains('수도권') || s.contains('서울'))) return '1호선';
  if (s.contains('2호선') && s.contains('서울')) return '2호선';
  if (s.contains('3호선') && s.contains('서울')) return '3호선';
  if (s.contains('4호선') && s.contains('서울')) return '4호선';
  if (s.contains('5호선') && s.contains('서울')) return '5호선';
  if (s.contains('6호선') && s.contains('서울')) return '6호선';
  if (s.contains('7호선') && s.contains('서울')) return '7호선';
  if (s.contains('8호선') && s.contains('서울')) return '8호선';
  if (s.contains('9호선') && (s.contains('수도권') || s.contains('서울'))) return '9호선';
  if (s.contains('경의') || s.contains('중앙선')) return '경의중앙';
  if (s.contains('경춘')) return '경춘선';
  if (s.contains('수인') || s.contains('분당')) return '수인분당';
  if (s.contains('신분당')) return '신분당선';
  if (s.contains('공항') && (s.contains('철도') || s.contains('선'))) return '공항철도';
  if (s.contains('GTX') || s.contains('A선')) return 'GTX-A';
  if (s.contains('부산') && s.contains('1호선')) return '부산1';
  if (s.contains('부산') && s.contains('2호선')) return '부산2';
  if (s.contains('부산') && s.contains('3호선')) return '부산3';
  if (s.contains('부산') && s.contains('4호선')) return '부산4';
  if (s.contains('동해선')) return '동해선';
  if (s.contains('대구') && s.contains('1호선')) return '대구1';
  if (s.contains('대구') && s.contains('2호선')) return '대구2';
  if (s.contains('대구') && s.contains('3호선')) return '대구3';
  if (s.contains('광주') && s.contains('1호선')) return '광주1';
  if (s.contains('광주') && s.contains('2호선')) return '광주2';
  if (s.contains('대전') && s.contains('1호선')) return '대전1';
  return s;
}

String regionFromLine(String line, String operator) {
  final o = operator + line;
  if (o.contains('서울') || o.contains('수도권') || o.contains('경기') || o.contains('인천')) {
    return '서울';
  }
  if (o.contains('부산')) return '부산';
  if (o.contains('대구')) return '대구';
  if (o.contains('광주')) return '광주';
  if (o.contains('대전')) return '대전';
  return '기타';
}

String iconFor(String name) {
  const icons = {'서울': '🏛️', '홍대입구': '🎸', '강남': '💼', '잠실': '🏟️', '부산': '🚉'};
  for (final e in icons.entries) {
    if (name.contains(e.key)) return e.value;
  }
  return '🚇';
}

int _colIndexFromRef(String ref) {
  final letters = ref.split(RegExp(r'\d')).first;
  var n = 0;
  for (final u in letters.codeUnits) {
    n = n * 26 + (u - 64);
  }
  return n - 1;
}

List<String> _parseSharedStrings(String? xmlStr) {
  if (xmlStr == null || xmlStr.isEmpty) return [];
  final doc = XmlDocument.parse(xmlStr);
  final sstList = doc.findAllElements('sst').toList();
  if (sstList.isEmpty) return [];
  final sst = sstList.first;
  return sst.findElements('si').map((si) {
    return si.findAllElements('t').map((t) => t.innerText).join();
  }).toList();
}

String? _cellText(XmlElement c, List<String> shared) {
  final t = c.getAttribute('t');
  final vElems = c.findElements('v').toList();
  final vText = vElems.isEmpty ? null : vElems.first.innerText;
  if (vText != null) {
    if (t == 's') {
      final i = int.tryParse(vText);
      if (i != null && i >= 0 && i < shared.length) return shared[i];
      return null;
    }
    if (t == 'b') return vText == '1' ? 'TRUE' : 'FALSE';
    return vText;
  }
  final isList = c.findElements('is').toList();
  final isEl = isList.isEmpty ? null : isList.first;
  if (isEl != null) {
    return isEl.findAllElements('t').map((e) => e.innerText).join();
  }
  return null;
}

List<List<String?>> _parseSheetRows(String? xmlStr, List<String> shared) {
  if (xmlStr == null) return [];
  final doc = XmlDocument.parse(xmlStr);
  final rows = doc.findAllElements('row').toList();
  rows.sort((a, b) {
    final ra = int.tryParse(a.getAttribute('r') ?? '0') ?? 0;
    final rb = int.tryParse(b.getAttribute('r') ?? '0') ?? 0;
    return ra.compareTo(rb);
  });

  final out = <List<String?>>[];
  for (final row in rows) {
    var maxCol = 0;
    final cells = <int, String?>{};
    for (final c in row.findElements('c')) {
      final ref = c.getAttribute('r');
      if (ref == null) continue;
      final col = _colIndexFromRef(ref);
      if (col > maxCol) maxCol = col;
      cells[col] = _cellText(c, shared);
    }
    if (cells.isEmpty) {
      out.add([]);
      continue;
    }
    final list = List<String?>.filled(maxCol + 1, null);
    for (final e in cells.entries) {
      if (e.key < list.length) list[e.key] = e.value;
    }
    out.add(list);
  }
  return out;
}

Future<void> main(List<String> args) async {
  final path = args.isNotEmpty
      ? args.first
      : r'c:\Users\kjh96\Downloads\전체_도시철도역사정보_20250930.xlsx';
  final f = File(path);
  if (!f.existsSync()) {
    stderr.writeln('파일 없음: $path');
    exitCode = 1;
    return;
  }

  final bytes = await f.readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);

  String? readEntry(String name) {
    final file = archive.findFile(name);
    if (file == null) return null;
    return utf8.decode(file.content as List<int>);
  }

  final shared = _parseSharedStrings(readEntry('xl/sharedStrings.xml'));
  final sheetXml = readEntry('xl/worksheets/sheet1.xml');
  final rows = _parseSheetRows(sheetXml, shared);

  if (rows.isEmpty) {
    stderr.writeln('시트를 읽지 못했어요.');
    exitCode = 1;
    return;
  }

  stdout.writeln('행 수: ${rows.length}, 공유문자열: ${shared.length}');

  final header = rows.first;
  stdout.writeln('헤더: ${header.map((e) => e ?? "").join(" | ")}');

  int idx(String part) {
    return header.indexWhere((h) => h?.contains(part) == true);
  }

  var iName = idx('역사명');
  var iLine = idx('노선명');
  var iLat = idx('위도');
  var iLng = idx('경도');
  var iEn = idx('영문역사명');
  if (iEn < 0) iEn = idx('영문');
  var iOp = idx('운영기관');

  if (iName < 0 || iLine < 0 || iLat < 0 || iLng < 0) {
    stderr.writeln(
      '필수 열 없음 (역사명/노선명/위도/경도). 인덱스: name=$iName line=$iLine lat=$iLat lng=$iLng',
    );
    exitCode = 1;
    return;
  }
  final iOpFinal = iOp >= 0 ? iOp : iLine;

  String? g(List<String?> row, int i) =>
      i >= 0 && i < row.length ? row[i]?.trim() : null;

  final out = <Map<String, dynamic>>[];
  final seen = <String>{};

  for (var r = 1; r < rows.length; r++) {
    final row = rows[r];
    final name = g(row, iName) ?? '';
    final lineRaw = g(row, iLine) ?? '';
    final latS = g(row, iLat) ?? '';
    final lngS = g(row, iLng) ?? '';
    if (name.isEmpty || lineRaw.isEmpty) continue;

    final lat = double.tryParse(latS.replaceAll(',', '.')) ?? 0.0;
    final lng = double.tryParse(lngS.replaceAll(',', '.')) ?? 0.0;
    if (lat == 0 || lng == 0) continue;

    final line = normalizeLine(lineRaw);
    final op = g(row, iOpFinal) ?? '';
    final en = (iEn >= 0 ? g(row, iEn) : null) ?? name;
    final key = '$name|$line';
    if (seen.contains(key)) continue;
    seen.add(key);

    out.add({
      'id': generateId(name, line),
      'name': name,
      'en': en,
      'line': line,
      'icon': iconFor(name),
      'region': regionFromLine(line, op),
      'lat': lat,
      'lng': lng,
    });
  }

  stdout.writeln('유효 역: ${out.length}건');

  final assetsDir = Directory('assets');
  if (!assetsDir.existsSync()) await assetsDir.create(recursive: true);

  final outFile = File('assets/stations_metro_kric.json');
  await outFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(out),
  );
  stdout.writeln('저장: ${outFile.path}');
}
