import 'dart:convert';

import 'package:http/http.dart' as http;

/// 공공데이터 오픈 API만 사용 (Flutter 의존 없음 — 에셋 생성 스크립트용).
///
/// **"등록되지 않은 서비스" / SERVICE KEY IS NOT REGISTERED**
/// - [data.go.kr](https://www.data.go.kr) 로그인 → 사용할 **각** 데이터 상세 페이지에서 [활용신청] 후 **승인**이 필요합니다.
/// - **한국철도공사_역 위치**만 승인: 철도 역만 수백 건 수집, 지하철(도시철도) API는 0건·오류 응답이어도 병합은 진행됩니다.
/// - **전국 ~950역** 수준을 쓰려면 **전국도시철도역사정보**도 추가로 신청·승인받으세요.
/// - 승인된 뒤 **일반 인증키(Encoding)** 를 아래 기본값 대신 넣거나, 빌드/실행 시
///   `--dart-define=ODCLOUD_SERVICE_KEY=인코딩된키` 로 넘기세요.
/// - 키는 **Encoding( URL 인코딩 된 값 )** 을 그대로 사용합니다. (decode 후 queryParameters 로 넣으면 오류 나는 경우가 있습니다.)
class StationOdcloudFetch {
  /// 포털 **일반 인증키(Encoding)**. `dart run --dart-define=ODCLOUD_SERVICE_KEY=...` 로 덮어쓸 수 있음.
  static const _key = String.fromEnvironment(
    'ODCLOUD_SERVICE_KEY',
    defaultValue:
        '3OXoR614oaT7zpzKYmt5tsM%2BOVSrA0iGLEMttJg7g%2FmF8dSkAyDLpwd7lvB5Qw20SNvGfBVzg65wl4HTBfjc9g%3D%3D',
  );

  static const _korailUrl =
      'https://api.odcloud.kr/api/15127532/v1/uddi:3e7a10e9-53d2-4a9a-92c9-81abf5d04b44';

  static const _metroUrl =
      'https://api.odcloud.kr/api/15013205/v1/uddi:f29d5df8-e853-4bde-ae33-0f4d8caee7c9';

  /// [onDiagnostic]에 HTTP 상태·응답 미리보기 등을 넘깁니다 (export_stations 등에서 사용).
  static Future<List<Map<String, dynamic>>> fetchStationMaps({
    void Function(String message)? onDiagnostic,
  }) async {
    final results = await Future.wait([
      _fetchKorailMaps(onDiagnostic: onDiagnostic),
      _fetchMetroMaps(onDiagnostic: onDiagnostic),
    ]);
    onDiagnostic?.call(
      '병합 전 건수 — Korail(철도): ${results[0].length}, Metro(도시철도): ${results[1].length}',
    );
    final all = <String, Map<String, dynamic>>{};
    for (final list in results) {
      for (final m in list) {
        final name = m['name'] as String? ?? '';
        final line = m['line'] as String? ?? '';
        all[name + line] = m;
      }
    }
    onDiagnostic?.call('병합 후(이름+노선 기준): ${all.length}건');
    return all.values.toList(growable: false);
  }

  static void _logResponse(
    void Function(String message)? log,
    String label,
    Uri url,
    http.Response res,
  ) {
    if (log == null) return;
    final text = utf8.decode(res.bodyBytes);
    final preview =
        text.length > 1600 ? '${text.substring(0, 1600)}…(truncated)' : text;
    final b = StringBuffer()
      ..writeln('── $label ──')
      ..writeln('URL: $url')
      ..writeln('HTTP ${res.statusCode}, ${res.bodyBytes.length} bytes')
      ..writeln('preview:\n$preview');
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        b.writeln('JSON keys: ${decoded.keys.join(", ")}');
        final tc = decoded['totalCount'];
        if (tc != null) b.writeln('totalCount: $tc');
        final data = decoded['data'];
        if (data is List) b.writeln('data.length: ${data.length}');
        final rc = decoded['resultCode'];
        if (rc != null) {
          b.writeln('resultCode: $rc  resultMsg: ${decoded['resultMsg']}');
        }
        final nested = decoded['RESULT'];
        if (nested is Map) {
          b.writeln('RESULT.CODE: ${nested['CODE']}  MESSAGE: ${nested['MESSAGE']}');
        }
      }
    } catch (e) {
      b.writeln('(JSON parse error: $e)');
    }
    log(b.toString());
  }

  static Future<List<Map<String, dynamic>>> _fetchKorailMaps({
    void Function(String message)? onDiagnostic,
  }) async {
    final out = <Map<String, dynamic>>[];
    var page = 1;
    const perPage = 100;

    while (true) {
      final url = _buildUri(_korailUrl, page, perPage);
      final res = await http.get(url, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (page == 1) {
        _logResponse(onDiagnostic, 'Korail (철도 역) page 1', url, res);
      }
      if (res.statusCode != 200) return [];

      dynamic json;
      try {
        json = jsonDecode(utf8.decode(res.bodyBytes));
      } catch (e) {
        onDiagnostic?.call('Korail JSON decode error: $e');
        return [];
      }
      final data = json['data'] as List?;
      if (data == null || data.isEmpty) break;

      for (final item in data) {
        final lat = double.tryParse(item['위도']?.toString() ?? '') ?? 0;
        final lng = double.tryParse(item['경도']?.toString() ?? '') ?? 0;
        if (lat == 0 || lng == 0) continue;

        final name = item['역명']?.toString() ?? '';
        final hub = item['지역본부']?.toString() ?? '';
        final line = _parseKorailLine(hub);
        out.add({
          'id': _generateId(name, line),
          'name': name,
          'en': _toEnglish(name),
          'line': line,
          'icon': _getIcon(name, 'rail'),
          'region': _parseRegion(hub),
          'lat': lat,
          'lng': lng,
        });
      }

      final total = json['totalCount'] as int? ?? 0;
      if (page * perPage >= total) break;
      page++;
    }
    return out;
  }

  static Future<List<Map<String, dynamic>>> _fetchMetroMaps({
    void Function(String message)? onDiagnostic,
  }) async {
    final out = <Map<String, dynamic>>[];
    var page = 1;
    const perPage = 200;

    while (true) {
      final url = _buildUri(_metroUrl, page, perPage);
      final res = await http.get(url, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (page == 1) {
        _logResponse(onDiagnostic, 'Metro (도시철도) page 1', url, res);
      }
      if (res.statusCode != 200) return [];

      dynamic json;
      try {
        json = jsonDecode(utf8.decode(res.bodyBytes));
      } catch (e) {
        onDiagnostic?.call('Metro JSON decode error: $e');
        return [];
      }
      final data = json['data'] as List?;
      if (data == null || data.isEmpty) break;

      for (final item in data) {
        final lat = double.tryParse(item['역위도']?.toString() ?? '') ?? 0;
        final lng = double.tryParse(item['역경도']?.toString() ?? '') ?? 0;
        if (lat == 0 || lng == 0) continue;

        final lineName = _parseMetroLine(
          item['노선명']?.toString() ?? '',
          item['운영기관명']?.toString() ?? '',
        );
        final name = item['역사명']?.toString() ?? '';
        final op = item['운영기관명']?.toString() ?? '';

        out.add({
          'id': _generateId(name, lineName),
          'name': name,
          'en': item['영문역사명']?.toString() ?? _toEnglish(name),
          'line': lineName,
          'icon': _getIcon(name, 'metro'),
          'region': _parseRegionFromOperator(op),
          'lat': lat,
          'lng': lng,
        });
      }

      final total = json['totalCount'] as int? ?? 0;
      if (page * perPage >= total) break;
      page++;
    }
    return out;
  }

  static Uri _buildUri(String baseUrl, int page, int perPage) {
    // Encoding 키를 한 번만 쿼리에 붙임 (decode + replace(queryParameters) 조합은 이중 인코딩·포털 오류 유발 사례 있음)
    return Uri.parse(
      '$baseUrl?page=$page&perPage=$perPage&serviceKey=$_key',
    );
  }

  static int _generateId(String name, String line) {
    return (name + line).hashCode.abs() % 10000000;
  }

  static String _parseMetroLine(String lineName, String operator) {
    // 지역 메트로를 먼저 체크해야 서울 호선으로 잘못 분류되지 않는다.
    if (operator.contains('부산') && lineName.contains('1호선')) return '부산1';
    if (operator.contains('부산') && lineName.contains('2호선')) return '부산2';
    if (operator.contains('부산') && lineName.contains('3호선')) return '부산3';
    if (operator.contains('부산') && lineName.contains('4호선')) return '부산4';
    if (operator.contains('대구') && lineName.contains('1호선')) return '대구1';
    if (operator.contains('대구') && lineName.contains('2호선')) return '대구2';
    if (operator.contains('대구') && lineName.contains('3호선')) return '대구3';
    if (operator.contains('광주') && lineName.contains('1호선')) return '광주1';
    if (operator.contains('광주') && lineName.contains('2호선')) return '광주2';
    if (operator.contains('대전')) return '대전1';
    if (lineName.contains('동해선')) return '동해선';

    if (lineName.contains('1호선') || lineName.contains('수도권 1')) return '1호선';
    if (lineName.contains('2호선')) return '2호선';
    if (lineName.contains('3호선')) return '3호선';
    if (lineName.contains('4호선')) return '4호선';
    if (lineName.contains('5호선')) return '5호선';
    if (lineName.contains('6호선')) return '6호선';
    if (lineName.contains('7호선')) return '7호선';
    if (lineName.contains('8호선')) return '8호선';
    if (lineName.contains('9호선')) return '9호선';
    if (lineName.contains('경의') || lineName.contains('중앙선')) return '경의중앙';
    if (lineName.contains('경춘')) return '경춘선';
    if (lineName.contains('수인') || lineName.contains('분당')) return '수인분당';
    if (lineName.contains('신분당')) return '신분당선';
    if (lineName.contains('공항')) return '공항철도';
    if (lineName.contains('GTX') || lineName.contains('A선')) return 'GTX-A';
    return lineName;
  }

  static String _parseKorailLine(String hub) {
    if (hub.contains('수도권') || hub.contains('서울')) return 'KTX';
    if (hub.contains('강원')) return 'ITX';
    if (hub.contains('전남') || hub.contains('광주') || hub.contains('전북')) return '무궁화';
    if (hub.contains('경남') || hub.contains('부산')) return 'SRT';
    if (hub.contains('충남') || hub.contains('대전') || hub.contains('충북')) return 'KTX';
    return 'KTX';
  }

  static String _parseRegion(String hub) {
    if (hub.contains('수도권') || hub.contains('서울')) return '서울';
    if (hub.contains('부산') || hub.contains('경남')) return '부산';
    if (hub.contains('대구') || hub.contains('경북')) return '대구';
    if (hub.contains('광주') || hub.contains('전남')) return '광주';
    if (hub.contains('대전') || hub.contains('충남')) return '대전';
    if (hub.contains('강원')) return '강원';
    return '기타';
  }

  static String _parseRegionFromOperator(String op) {
    if (op.contains('서울') || op.contains('수도권') || op.contains('코레일')) return '서울';
    if (op.contains('부산')) return '부산';
    if (op.contains('대구')) return '대구';
    if (op.contains('광주')) return '광주';
    if (op.contains('대전')) return '대전';
    return '기타';
  }

  static String _toEnglish(String name) {
    const map = {
      '서울': 'Seoul',
      '강남': 'Gangnam',
      '홍대입구': 'Hongik Univ.',
      '성수': 'Seongsu',
      '잠실': 'Jamsil',
      '광화문': 'Gwanghwamun',
      '명동': 'Myeongdong',
      '종각': 'Jonggak',
      '시청': 'City Hall',
      '부산': 'Busan',
      '대전': 'Daejeon',
      '대구': 'Daegu',
      '광주': 'Gwangju',
      '수원': 'Suwon',
      '인천': 'Incheon',
    };
    return map[name] ?? name;
  }

  static String _getIcon(String name, String type) {
    const icons = {
      '서울': '🏛️',
      '홍대입구': '🎸',
      '강남': '💼',
      '잠실': '🏟️',
      '성수': '🏭',
      '경복궁': '👑',
      '명동': '🛍️',
      '광화문': '🗺️',
      '여의도': '🏦',
      '이태원': '🌏',
      '해운대': '🏖️',
      '부산': '🚉',
      '인천공항': '✈️',
      '김포공항': '✈️',
      '판교': '💻',
      '강릉': '🏔️',
      '동대문': '🏯',
      '시청': '🏢',
      '종각': '🔔',
    };
    for (final key in icons.keys) {
      if (name.contains(key)) return icons[key]!;
    }
    return type == 'rail' ? '🚄' : '🚇';
  }
}
