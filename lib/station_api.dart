import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';
import 'station_odcloud.dart';

class StationApiService {
  static const _cacheKeyStations = 'cached_stations_v1';
  static const _cacheKeyTs = 'cached_stations_ts_v1';
  static const _cacheTtl = Duration(days: 7);
  static const _supabaseTable = 'stations';
  static const _bundledAsset = 'assets/stations.json';
  static const _bundledMetroKric = 'assets/stations_metro_kric.json';
  static const _bundledKorail = 'assets/stations_korail.json';

  /// 1) [assets/stations.json]이 비어 있지 않으면 그대로 사용.
  /// 2) 비었거나 없으면 [assets/stations_korail.json] + [assets/stations_metro_kric.json]을
  ///    이름+노선 기준으로 합침 (파일이 없으면 해당 부분은 건너뜀).
  static Future<List<Station>> loadBundledStations() async {
    try {
      final raw = await rootBundle.loadString(_bundledAsset);
      final decoded = jsonDecode(raw) as List<dynamic>;
      if (decoded.isNotEmpty) {
        return decoded
            .map((e) => Station.fromJson(e as Map<String, dynamic>))
            .toList(growable: false);
      }
    } catch (_) {}

    final byKey = <String, Station>{};
    for (final path in [_bundledKorail, _bundledMetroKric]) {
      try {
        final raw = await rootBundle.loadString(path);
        final decoded = jsonDecode(raw) as List<dynamic>;
        for (final e in decoded) {
          final s = Station.fromJson(Map<String, dynamic>.from(e as Map));
          byKey[s.name + s.line] = s;
        }
      } catch (_) {}
    }
    if (byKey.isEmpty) return [];
    return byKey.values.toList(growable: false);
  }

  static List<Station> _mapsToStations(List<Map<String, dynamic>> maps) {
    return maps
        .map((e) => Station.fromJson(e))
        .toList(growable: false);
  }

  static Future<List<Station>> _fetchFromOpenData() async {
    final maps = await StationOdcloudFetch.fetchStationMaps();
    if (maps.isEmpty) return [];
    return _mapsToStations(maps);
  }

  /// 전체 역 데이터 로드: 번들 → 로컬 캐시 → Supabase → 공공 API → 샘플
  static Future<List<Station>> fetchAllStations() async {
    final bundled = await loadBundledStations();
    if (bundled.isNotEmpty) return bundled;

    final cached = await loadStationsFromCache();
    if (cached.isNotEmpty) return cached;

    final fromSupabase = await loadStationsFromSupabase();
    if (fromSupabase.isNotEmpty) {
      await saveStationsToCache(fromSupabase);
      return fromSupabase;
    }

    try {
      final merged = await _fetchFromOpenData();
      if (merged.isEmpty) {
        final fallback = sampleStations;
        await saveStationsToCache(fallback);
        await saveStationsToSupabase(fallback);
        return fallback;
      }
      await saveStationsToCache(merged);
      await saveStationsToSupabase(merged);
      return merged;
    } catch (e) {
      final fallback = sampleStations;
      await saveStationsToCache(fallback);
      await saveStationsToSupabase(fallback);
      return fallback;
    }
  }

  static Future<List<Station>> loadStationsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedRaw = prefs.getString(_cacheKeyStations);
      final cachedTs = prefs.getInt(_cacheKeyTs);
      if (cachedRaw == null || cachedTs == null) return [];

      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(cachedTs),
      );
      if (age > _cacheTtl) return [];

      final decoded = jsonDecode(cachedRaw) as List<dynamic>;
      return decoded
          .map((e) => Station.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveStationsToCache(List<Station> stations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(stations.map((s) => s.toJson()).toList());
      await prefs.setString(_cacheKeyStations, encoded);
      await prefs.setInt(_cacheKeyTs, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  static Future<List<Station>> loadStationsFromSupabase() async {
    try {
      final sb = Supabase.instance.client;
      final rows = await sb.from(_supabaseTable).select().limit(2000);
      if (rows.isEmpty) return [];
      return rows
          .map((e) => Station.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveStationsToSupabase(List<Station> stations) async {
    if (stations.isEmpty) return;
    try {
      final sb = Supabase.instance.client;
      if (sb.auth.currentUser == null) return;
      final payload = stations
          .map((s) => {
                'id': s.id,
                'name': s.name,
                'en': s.en,
                'line': s.line,
                'icon': s.icon,
                'region': s.region,
                'lat': s.lat,
                'lng': s.lng,
                'updated_at': DateTime.now().toIso8601String(),
              })
          .toList(growable: false);
      await sb.from(_supabaseTable).upsert(payload);
    } catch (_) {
      // Supabase 권한/테이블 미구성 시 앱 흐름은 로컬 캐시로 계속 진행
    }
  }
}
