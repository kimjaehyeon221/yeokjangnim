import 'package:flutter/material.dart';
import 'dart:math' as math;

// ── 역 모델 ──────────────────────────────────────────
class Station {
  final int id;
  final String name;
  final String en;
  final String line;
  final String icon;
  final String region;
  final double lat;
  final double lng;
  bool got;
  DateTime? stampedAt;

  Station({
    required this.id,
    required this.name,
    required this.en,
    required this.line,
    required this.icon,
    required this.region,
    required this.lat,
    required this.lng,
    this.got = false,
    this.stampedAt,
  });

  factory Station.fromJson(Map<String, dynamic> json) => Station(
    id: json['id'] as int? ?? 0,
    name: json['name']?.toString() ?? '',
    en: json['en'] ?? '',
    line: json['line'] ?? '',
    icon: json['icon'] ?? '🚉',
    region: json['region'] ?? '',
    lat: (json['lat'] ?? 0).toDouble(),
    lng: (json['lng'] ?? 0).toDouble(),
    got: json['got'] ?? false,
    stampedAt: json['stampedAt'] != null
        ? DateTime.tryParse(json['stampedAt'].toString())
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'en': en,
    'line': line,
    'icon': icon,
    'region': region,
    'lat': lat,
    'lng': lng,
    'got': got,
    'stampedAt': stampedAt?.toIso8601String(),
  };
}

// ── 노선 정보 ─────────────────────────────────────────
class LineInfo {
  final Color color;
  final String type;
  final String region;
  const LineInfo({required this.color, required this.type, required this.region});
}

class LineProgress {
  final String line;
  final List<Station> stations;
  final int visited;
  final int total;
  final Color color;
  final String type;
  final String region;

  const LineProgress({
    required this.line,
    required this.stations,
    required this.visited,
    required this.total,
    required this.color,
    required this.type,
    required this.region,
  });

  double get ratio => total == 0 ? 0 : visited / total;
  bool get isComplete => total > 0 && visited == total;
}

const Map<String, LineInfo> kLines = {
  '1호선':   LineInfo(color: Color(0xFF0052A4), type: 'metro', region: '수도권'),
  '2호선':   LineInfo(color: Color(0xFF00A84D), type: 'metro', region: '수도권'),
  '3호선':   LineInfo(color: Color(0xFFEF7C1C), type: 'metro', region: '수도권'),
  '4호선':   LineInfo(color: Color(0xFF00A5DE), type: 'metro', region: '수도권'),
  '5호선':   LineInfo(color: Color(0xFF996CAC), type: 'metro', region: '수도권'),
  '6호선':   LineInfo(color: Color(0xFFCD7C2F), type: 'metro', region: '수도권'),
  '7호선':   LineInfo(color: Color(0xFF747F00), type: 'metro', region: '수도권'),
  '8호선':   LineInfo(color: Color(0xFFE6186C), type: 'metro', region: '수도권'),
  '9호선':   LineInfo(color: Color(0xFFBDB092), type: 'metro', region: '수도권'),
  '경의중앙': LineInfo(color: Color(0xFF77C4A3), type: 'metro', region: '수도권'),
  '경춘선':  LineInfo(color: Color(0xFF0C8E72), type: 'metro', region: '수도권'),
  '수인분당': LineInfo(color: Color(0xFFF5A200), type: 'metro', region: '수도권'),
  '신분당선': LineInfo(color: Color(0xFFD4003B), type: 'metro', region: '수도권'),
  '공항철도': LineInfo(color: Color(0xFF0065B3), type: 'metro', region: '수도권'),
  'GTX-A':  LineInfo(color: Color(0xFF9B51E0), type: 'metro', region: '수도권'),
  '부산1':   LineInfo(color: Color(0xFFF06400), type: 'metro', region: '부산'),
  '부산2':   LineInfo(color: Color(0xFF81C147), type: 'metro', region: '부산'),
  '부산3':   LineInfo(color: Color(0xFFCAACE6), type: 'metro', region: '부산'),
  '부산4':   LineInfo(color: Color(0xFF30B9E8), type: 'metro', region: '부산'),
  '동해선':  LineInfo(color: Color(0xFFF4A83C), type: 'metro', region: '부산'),
  '대구1':   LineInfo(color: Color(0xFFD93F2C), type: 'metro', region: '대구'),
  '대구2':   LineInfo(color: Color(0xFF22874A), type: 'metro', region: '대구'),
  '대구3':   LineInfo(color: Color(0xFFF5A200), type: 'metro', region: '대구'),
  '광주1':   LineInfo(color: Color(0xFF00963A), type: 'metro', region: '광주'),
  '광주2':   LineInfo(color: Color(0xFFF5A200), type: 'metro', region: '광주'),
  '대전1':   LineInfo(color: Color(0xFF00A650), type: 'metro', region: '대전'),
  'KTX':    LineInfo(color: Color(0xFFE30613), type: 'rail',  region: '전국'),
  'SRT':    LineInfo(color: Color(0xFF8B1A4A), type: 'rail',  region: '전국'),
  'ITX':    LineInfo(color: Color(0xFF2D6FB4), type: 'rail',  region: '전국'),
  '무궁화':  LineInfo(color: Color(0xFF6B6B6B), type: 'rail',  region: '전국'),
};

// ── 뱃지 모델 ─────────────────────────────────────────
class Badge {
  final String id;
  final String icon;
  final String name;
  final String desc;
  bool got;

  Badge({
    required this.id,
    required this.icon,
    required this.name,
    required this.desc,
    this.got = false,
  });
}

final Map<String, List<Badge>> kBadges = {
  '노선 완주': [
    Badge(id:'b-l1', icon:'🔵', name:'1호선 완주', desc:'1호선 전 역 인증', got:false),
    Badge(id:'b-l2', icon:'🟢', name:'2호선 완주', desc:'서울 순환선 전 역 인증', got:false),
    Badge(id:'b-l3', icon:'🟠', name:'3호선 완주', desc:'대화~오금 전 역 인증', got:false),
    Badge(id:'b-l4', icon:'🩵', name:'4호선 완주', desc:'진접~오이도 전 역 인증', got:false),
    Badge(id:'b-l5', icon:'🟣', name:'5호선 완주', desc:'방화~하남 전 역 인증', got:false),
    Badge(id:'b-l6', icon:'🟤', name:'6호선 완주', desc:'응암~봉화산 전 역 인증', got:false),
    Badge(id:'b-l7', icon:'🫒', name:'7호선 완주', desc:'장암~석남 전 역 인증', got:false),
    Badge(id:'b-lktx', icon:'🔴', name:'KTX 완주', desc:'전국 KTX 정차역 인증', got:false),
    Badge(id:'b-lbs', icon:'🧡', name:'부산 완주', desc:'부산 지하철 전 역 인증', got:false),
    Badge(id:'b-ldg', icon:'❤️', name:'대구 완주', desc:'대구 지하철 전 역 인증', got:false),
    Badge(id:'b-lgj', icon:'💚', name:'광주 완주', desc:'광주 지하철 전 역 인증', got:false),
    Badge(id:'b-ldj', icon:'💛', name:'대전 완주', desc:'대전 지하철 전 역 인증', got:false),
  ],
  '스토리': [
    Badge(id:'b-first',  icon:'🌱', name:'첫 역',       desc:'첫 번째 스탬프 획득',        got:false),
    Badge(id:'b-night',  icon:'🌙', name:'야행성',       desc:'자정~새벽 5시 사이 인증',    got:false),
    Badge(id:'b-xmas',   icon:'🎄', name:'크리스마스역', desc:'12월 25일 역 인증',          got:false),
    Badge(id:'b-airport',icon:'✈️', name:'공항역',       desc:'공항 연결 역 인증',          got:false),
    Badge(id:'b-10',     icon:'🔟', name:'10개 달성',    desc:'스탬프 10개 획득',           got:false),
    Badge(id:'b-50',     icon:'🏅', name:'역장',         desc:'스탬프 50개 달성',           got:false),
    Badge(id:'b-100',    icon:'🏆', name:'수석역장',     desc:'스탬프 100개 달성',          got:false),
    Badge(id:'b-500',    icon:'🌟', name:'철도청장',     desc:'스탬프 500개 달성',          got:false),
  ],
};

// ── 샘플 역 데이터 (공공데이터 API 연동 전 사용) ──────
final List<Station> sampleStations = [
  Station(id:1,  name:'서울',      en:'Seoul',           line:'1호선', icon:'🏛️', region:'서울', lat:37.5547, lng:126.9707, got:true),
  Station(id:2,  name:'시청',      en:'City Hall',       line:'1호선', icon:'🏢', region:'서울', lat:37.5651, lng:126.9775, got:true),
  Station(id:3,  name:'종각',      en:'Jonggak',         line:'1호선', icon:'🔔', region:'서울', lat:37.5700, lng:126.9826, got:false),
  Station(id:4,  name:'종로3가',   en:'Jongno 3-ga',     line:'1호선', icon:'🏮', region:'서울', lat:37.5709, lng:126.9920, got:true),
  Station(id:5,  name:'동대문',    en:'Dongdaemun',      line:'1호선', icon:'🏯', region:'서울', lat:37.5716, lng:127.0100, got:false),
  Station(id:6,  name:'청량리',    en:'Cheongnyangni',   line:'1호선', icon:'🚉', region:'서울', lat:37.5802, lng:127.0445, got:true),
  Station(id:7,  name:'수원',      en:'Suwon',           line:'1호선', icon:'🏰', region:'경기', lat:37.2664, lng:127.0008, got:false),
  Station(id:8,  name:'천안',      en:'Cheonan',         line:'1호선', icon:'🌾', region:'충남', lat:36.8082, lng:127.1477, got:false),
  Station(id:9,  name:'인천',      en:'Incheon',         line:'1호선', icon:'⚓', region:'인천', lat:37.4743, lng:126.6217, got:false),
  Station(id:20, name:'홍대입구',  en:'Hongik Univ.',    line:'2호선', icon:'🎸', region:'서울', lat:37.5572, lng:126.9246, got:true),
  Station(id:21, name:'합정',      en:'Hapjeong',        line:'2호선', icon:'🌊', region:'서울', lat:37.5497, lng:126.9140, got:true),
  Station(id:22, name:'당산',      en:'Dangsan',         line:'2호선', icon:'🌉', region:'서울', lat:37.5340, lng:126.9006, got:false),
  Station(id:23, name:'강남',      en:'Gangnam',         line:'2호선', icon:'💼', region:'서울', lat:37.4979, lng:127.0276, got:true),
  Station(id:24, name:'잠실',      en:'Jamsil',          line:'2호선', icon:'🏟️', region:'서울', lat:37.5131, lng:127.1000, got:true),
  Station(id:25, name:'건대입구',  en:'Konkuk Univ.',    line:'2호선', icon:'🎓', region:'서울', lat:37.5402, lng:127.0705, got:false),
  Station(id:26, name:'성수',      en:'Seongsu',         line:'2호선', icon:'🏭', region:'서울', lat:37.5446, lng:127.0557, got:true),
  Station(id:27, name:'왕십리',    en:'Wangsimni',       line:'2호선', icon:'🔀', region:'서울', lat:37.5613, lng:127.0377, got:false),
  Station(id:28, name:'신도림',    en:'Sindorim',        line:'2호선', icon:'🔀', region:'서울', lat:37.5083, lng:126.8913, got:true),
  Station(id:40, name:'경복궁',    en:'Gyeongbokgung',   line:'3호선', icon:'👑', region:'서울', lat:37.5765, lng:126.9745, got:true),
  Station(id:41, name:'안국',      en:'Anguk',           line:'3호선', icon:'🏮', region:'서울', lat:37.5760, lng:126.9854, got:false),
  Station(id:42, name:'을지로3가', en:'Euljiro 3-ga',    line:'3호선', icon:'🖨️', region:'서울', lat:37.5660, lng:126.9930, got:true),
  Station(id:43, name:'고속터미널',en:'Express Bus T.',  line:'3호선', icon:'🚌', region:'서울', lat:37.5047, lng:127.0047, got:false),
  Station(id:44, name:'양재',      en:'Yangjae',         line:'3호선', icon:'🌳', region:'서울', lat:37.4843, lng:127.0342, got:false),
  Station(id:60, name:'혜화',      en:'Hyehwa',          line:'4호선', icon:'🎭', region:'서울', lat:37.5822, lng:127.0016, got:false),
  Station(id:61, name:'명동',      en:'Myeongdong',      line:'4호선', icon:'🛍️', region:'서울', lat:37.5636, lng:126.9828, got:true),
  Station(id:62, name:'이촌',      en:'Ichon',           line:'4호선', icon:'🏛️', region:'서울', lat:37.5228, lng:126.9716, got:false),
  Station(id:63, name:'사당',      en:'Sadang',          line:'4호선', icon:'🔀', region:'서울', lat:37.4764, lng:126.9817, got:false),
  Station(id:80, name:'광화문',    en:'Gwanghwamun',     line:'5호선', icon:'🗺️', region:'서울', lat:37.5716, lng:126.9769, got:true),
  Station(id:81, name:'여의도',    en:'Yeouido',         line:'5호선', icon:'🏦', region:'서울', lat:37.5219, lng:126.9247, got:false),
  Station(id:82, name:'공덕',      en:'Gongdeok',        line:'5호선', icon:'🔀', region:'서울', lat:37.5441, lng:126.9517, got:false),
  Station(id:100,name:'이태원',    en:'Itaewon',         line:'6호선', icon:'🌏', region:'서울', lat:37.5347, lng:126.9942, got:false),
  Station(id:101,name:'상수',      en:'Sangsu',          line:'6호선', icon:'☕', region:'서울', lat:37.5479, lng:126.9236, got:false),
  Station(id:120,name:'뚝섬유원지',en:'Ttukseom',        line:'7호선', icon:'🏖️', region:'서울', lat:37.5312, lng:127.0674, got:false),
  Station(id:121,name:'노원',      en:'Nowon',           line:'7호선', icon:'🌲', region:'서울', lat:37.6546, lng:127.0622, got:false),
  Station(id:140,name:'김포공항',  en:'Gimpo Airport',   line:'9호선', icon:'✈️', region:'서울', lat:37.5613, lng:126.8013, got:false),
  Station(id:141,name:'여의도',    en:'Yeouido',         line:'9호선', icon:'🔀', region:'서울', lat:37.5219, lng:126.9247, got:false),
  Station(id:160,name:'망원',      en:'Mangwon',         line:'경의중앙',icon:'🌊',region:'서울', lat:37.5557, lng:126.9101, got:false),
  Station(id:180,name:'수원',      en:'Suwon',           line:'수인분당',icon:'🔀',region:'경기', lat:37.2664, lng:127.0008, got:false),
  Station(id:181,name:'분당',      en:'Bundang',         line:'수인분당',icon:'🏘️',region:'경기', lat:37.3784, lng:127.1152, got:false),
  Station(id:200,name:'강남',      en:'Gangnam',         line:'신분당선',icon:'🔀',region:'서울', lat:37.4979, lng:127.0276, got:false),
  Station(id:201,name:'판교',      en:'Pangyo',          line:'신분당선',icon:'💻',region:'경기', lat:37.3943, lng:127.1110, got:false),
  Station(id:220,name:'인천공항1T',en:'ICN T1',          line:'공항철도',icon:'✈️',region:'인천', lat:37.4486, lng:126.4515, got:false),
  Station(id:221,name:'인천공항2T',en:'ICN T2',          line:'공항철도',icon:'✈️',region:'인천', lat:37.4690, lng:126.4536, got:false),
  Station(id:300,name:'서면',      en:'Seomyeon',        line:'부산1', icon:'🔀', region:'부산', lat:35.1576, lng:129.0593, got:false),
  Station(id:301,name:'부산역',    en:'Busan Station',   line:'부산1', icon:'🚉', region:'부산', lat:35.1148, lng:129.0420, got:false),
  Station(id:302,name:'해운대',    en:'Haeundae',        line:'부산2', icon:'🏖️', region:'부산', lat:35.1627, lng:129.1634, got:false),
  Station(id:303,name:'광안',      en:'Gwangan',         line:'부산2', icon:'🌉', region:'부산', lat:35.1533, lng:129.1188, got:false),
  Station(id:400,name:'반월당',    en:'Banwoldang',      line:'대구1', icon:'🔀', region:'대구', lat:35.8681, lng:128.5958, got:false),
  Station(id:401,name:'동대구',    en:'Dongdaegu',       line:'대구1', icon:'🚉', region:'대구', lat:35.8796, lng:128.6282, got:false),
  Station(id:500,name:'금남로4가', en:'Geumnamno 4-ga',  line:'광주1', icon:'🌸', region:'광주', lat:35.1501, lng:126.9174, got:false),
  Station(id:600,name:'중앙로',    en:'Jungangnno',      line:'대전1', icon:'🏛️', region:'대전', lat:36.3272, lng:127.4275, got:false),
  Station(id:700,name:'서울역',    en:'Seoul Station',   line:'KTX',   icon:'🚄', region:'서울', lat:37.5547, lng:126.9707, got:false),
  Station(id:701,name:'대전역',    en:'Daejeon',         line:'KTX',   icon:'🚄', region:'대전', lat:36.3322, lng:127.4344, got:false),
  Station(id:702,name:'동대구역',  en:'Dongdaegu',       line:'KTX',   icon:'🚄', region:'대구', lat:35.8796, lng:128.6282, got:false),
  Station(id:703,name:'부산역',    en:'Busan',           line:'KTX',   icon:'🚄', region:'부산', lat:35.1148, lng:129.0420, got:false),
  Station(id:704,name:'광주송정역',en:'Gwangju Songjeong',line:'KTX',  icon:'🚄', region:'광주', lat:35.1395, lng:126.7935, got:false),
  Station(id:705,name:'강릉역',    en:'Gangneung',       line:'KTX',   icon:'🏔️', region:'강원', lat:37.7519, lng:128.8963, got:false),
];

double distanceMeters({
  required double lat1,
  required double lng1,
  required double lat2,
  required double lng2,
}) {
  const earthRadiusMeters = 6371000.0;
  final dLat = _degToRad(lat2 - lat1);
  final dLng = _degToRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degToRad(lat1)) *
          math.cos(_degToRad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusMeters * c;
}

double _degToRad(double degree) => degree * math.pi / 180.0;
