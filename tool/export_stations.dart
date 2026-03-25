// 오픈API에서 역 목록을 받아 assets/stations.json 으로 저장합니다.
// 실행 (프로젝트 루트):
//   dart run tool/export_stations.dart
// 본인 인증키(Encoding)를 넘기려면:
//   dart run --dart-define=ODCLOUD_SERVICE_KEY=여기에_포털에서_복사한_Encoding키 tool/export_stations.dart

import 'dart:convert';
import 'dart:io';

import 'package:yeokjangnim/station_odcloud.dart';

Future<void> main() async {
  stdout.writeln('Fetching stations from odcloud.kr ...');
  stdout.writeln('(진단 로그: Korail / Metro 각각 첫 페이지 응답)\n');
  final maps = await StationOdcloudFetch.fetchStationMaps(
    onDiagnostic: stdout.writeln,
  );
  if (maps.isEmpty) {
    stderr.writeln('\nNo stations returned. 위 로그의 HTTP 코드·resultCode·응답 본문을 확인하세요.');
    exitCode = 1;
    return;
  }
  final dir = Directory('assets');
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }
  final file = File('assets/stations.json');
  await file.writeAsString(
    JsonEncoder.withIndent('  ').convert(maps),
  );
  stdout.writeln('Wrote ${maps.length} stations to ${file.path}');
}
