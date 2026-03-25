import 'dart:convert';
import 'station_api.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' hide Badge;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

final supabase = Supabase.instance.client;

/// 이메일 인증·비밀번호 재설정 메일의 링크가 열릴 주소.
/// 웹은 현재 앱 베이스(URL path 포함 — GitHub Pages `…/yeokjangnim/` 등), 앱은 Supabase 딥링크.
String authEmailRedirectUri() {
  if (kIsWeb) {
    final u = Uri.base;
    var path = u.path;
    if (path.toLowerCase().endsWith('index.html')) {
      path = path.substring(0, path.length - 'index.html'.length);
    }
    path = path.replaceAll(RegExp(r'/+$'), '');
    path = path.isEmpty ? '/' : '$path/';
    if (path == '/') {
      final o = u.origin;
      return o.endsWith('/') ? o : '$o/';
    }
    return '${u.origin}$path';
  }
  return 'io.supabase.flutter://login-callback/';
}

class StationDistance {
  final Station station;
  final double distanceMeters;
  const StationDistance({
    required this.station,
    required this.distanceMeters,
  });
}

class AppState extends ChangeNotifier {
  String nickname = '철도인';
  /// 프로필 '사진'을 DB에 저장하기 위한 스키마가 아직 없어서,
  /// 배포 위험을 줄이기 위해 이모지 아이콘 형태로 저장합니다. (로컬 유지)
  String profileIcon = '🧳';
  List<Station> stations = [];
  Set<int> stampedIds = {};
  Map<int, DateTime> stampDates = {};
  bool isLoading = false;
  String? userId;
  bool profileReady = false;
  String? lastStampError;
  final List<Badge> _recentUnlockedBadges = [];
  static const _pendingStampsKey = 'pending_stamps_v1';
  static const _pendingBadgesKey = 'pending_badges_v1';
  static const _prefsProfileIconKey = 'profile_icon_v1';

  // 초기화
  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    // 프로필 아이콘(로컬 저장) 로드
    try {
      final prefs = await SharedPreferences.getInstance();
      profileIcon = prefs.getString(_prefsProfileIconKey) ?? profileIcon;
    } catch (_) {}

    // 공공데이터 API로 역 로드 (실패 시 샘플 데이터)
    try {
      final fetched = await StationApiService.fetchAllStations();
      stations = fetched.isNotEmpty ? fetched : sampleStations;
      _syncStampedIdsFromStations();
    } catch (e) {
      stations = sampleStations;
      _syncStampedIdsFromStations();
    }

    // Supabase 로그인 상태 확인
    final session = supabase.auth.currentSession;
    if (session != null) {
      userId = session.user.id;
      await syncProfileFromRemote();
      await retryPendingStamps();
      await retryPendingBadges();
      await loadStamps();
      await loadBadges();
    } else {
      _refreshBadges();
    }

    isLoading = false;
    notifyListeners();
  }

  // 스탬프 로드
  Future<void> loadStamps() async {
    if (userId == null) return;
    try {
      final res = <dynamic>[];
      const pageSize = 1000;
      var offset = 0;

      while (true) {
        final page = await supabase
            .from('stamps')
            .select()
            .eq('user_id', userId!)
            .order('stamped_at', ascending: true)
            .range(offset, offset + pageSize - 1);
        res.addAll(page);
        if (page.length < pageSize) break;
        offset += pageSize;
      }

      stampedIds = {};
      stampDates = {};
      for (final row in res) {
        final sidRaw = row['station_id'];
        final sid = sidRaw is int ? sidRaw : int.tryParse(sidRaw.toString());
        if (sid == null) continue;
        stampedIds.add(sid);
        final stampedAtRaw = row['stamped_at']?.toString();
        if (stampedAtRaw != null) {
          final parsed = DateTime.tryParse(stampedAtRaw);
          if (parsed != null) {
            stampDates[sid] = parsed;
          }
        }
        // 로컬 stations 업데이트
        final idx = stations.indexWhere((s) => s.id == sid);
        if (idx >= 0) stations[idx].got = true;
      }
      _refreshBadges();
      notifyListeners();
    } catch (e) {
      debugPrint('스탬프 로드 오류: $e');
    }
  }

  // 스탬프 찍기
  Future<bool> stampStation(Station station) async {
    if (stampedIds.contains(station.id)) {
      lastStampError = '이미 찍은 역이에요.';
      return false;
    }
    lastStampError = null;

    final currentPosition = await getCurrentPosition();
    if (currentPosition == null) return false;

    final distance = distanceMeters(
      lat1: currentPosition.latitude,
      lng1: currentPosition.longitude,
      lat2: station.lat,
      lng2: station.lng,
    );
    if (distance > 100) {
      lastStampError = '현재 역과의 거리가 ${distance.toStringAsFixed(0)}m예요. 100m 이내에서 다시 시도해주세요.';
      return false;
    }

    final stampedAt = DateTime.now();

    // 로컬 즉시 반영
    stampedIds.add(station.id);
    stampDates[station.id] = stampedAt;
    final idx = stations.indexWhere((s) => s.id == station.id);
    if (idx >= 0) stations[idx].got = true;
    _checkBadgeUnlock(station, stampedAt);
    notifyListeners();

    // Supabase 저장 (로그인 상태일 때)
    if (userId != null) {
      try {
        await supabase.from('stamps').upsert({
          'user_id': userId,
          'station_id': station.id,
          'station_name': station.name,
          'station_line': station.line,
          'stamped_at': stampedAt.toIso8601String(),
        }, onConflict: 'user_id,station_id');
      } catch (e) {
        debugPrint('스탬프 저장 오류: $e');
        await _enqueuePendingStamp(
          station: station,
          stampedAt: stampedAt,
        );
      }
    }
    return true;
  }

  Future<void> retryPendingStamps() async {
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingStampsKey);
    if (raw == null || raw.isEmpty) return;

    List<dynamic> pending;
    try {
      pending = jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return;
    }

    if (pending.isEmpty) return;
    final remains = <Map<String, dynamic>>[];
    for (final item in pending) {
      final row = Map<String, dynamic>.from(item as Map);
      try {
        await supabase.from('stamps').upsert({
          'user_id': userId,
          'station_id': row['station_id'],
          'station_name': row['station_name'],
          'station_line': row['station_line'],
          'stamped_at': row['stamped_at'],
        }, onConflict: 'user_id,station_id');
      } catch (_) {
        remains.add(row);
      }
    }

    await prefs.setString(_pendingStampsKey, jsonEncode(remains));
  }

  Future<void> _enqueuePendingStamp({
    required Station station,
    required DateTime stampedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingStampsKey);
    List<dynamic> pending;
    try {
      pending = raw == null || raw.isEmpty ? <dynamic>[] : (jsonDecode(raw) as List<dynamic>);
    } catch (_) {
      pending = <dynamic>[];
    }

    // 동일 station_id 임시기록은 최신값으로 치환
    pending.removeWhere((e) => (e as Map)['station_id'] == station.id);
    pending.add({
      'station_id': station.id,
      'station_name': station.name,
      'station_line': station.line,
      'stamped_at': stampedAt.toIso8601String(),
    });
    await prefs.setString(_pendingStampsKey, jsonEncode(pending));
  }

  List<Badge> consumeRecentUnlockedBadges() {
    final copy = List<Badge>.from(_recentUnlockedBadges);
    _recentUnlockedBadges.clear();
    return copy;
  }

  Future<void> loadBadges() async {
    if (userId == null) return;
    try {
      final rows = await supabase
          .from('user_badges')
          .select('badge_id')
          .eq('user_id', userId!);
      final ids = rows
          .map((r) => r['badge_id']?.toString())
          .whereType<String>()
          .toSet();
      _applyUnlockedBadges(ids);
    } catch (e) {
      debugPrint('배지 로드 오류: $e');
    }
  }

  void _applyUnlockedBadges(Set<String> unlockedIds) {
    for (final list in kBadges.values) {
      for (final b in list) {
        if (unlockedIds.contains(b.id)) b.got = true;
      }
    }
    notifyListeners();
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        lastStampError = '위치 서비스가 꺼져 있어요. GPS를 켜주세요.';
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        lastStampError = '위치 권한이 필요해요. 설정에서 위치 권한을 허용해주세요.';
        return null;
      }

      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      debugPrint('위치 조회 오류: $e');
      lastStampError = '현재 위치를 가져오지 못했어요. 잠시 후 다시 시도해주세요.';
      return null;
    }
  }

  List<StationDistance> getNearestStationsFromPosition(
    Position position, {
    int limit = 5,
    bool onlyUnstamped = true,
  }) {
    final source = onlyUnstamped
        ? stations.where((s) => !stampedIds.contains(s.id)).toList(growable: false)
        : stations;
    final withDistance = source
        .map(
          (s) => StationDistance(
            station: s,
            distanceMeters: distanceMeters(
              lat1: position.latitude,
              lng1: position.longitude,
              lat2: s.lat,
              lng2: s.lng,
            ),
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    if (withDistance.length <= limit) return withDistance;
    return withDistance.take(limit).toList(growable: false);
  }

  // 닉네임 설정
  void setNickname(String name) {
    nickname = name.isEmpty ? '철도인' : name;
    profileReady = true;
    notifyListeners();
  }

  Future<void> saveNickname(String name) async {
    setNickname(name);
    if (userId == null) return;
    try {
      await supabase.auth.updateUser(
        UserAttributes(
          data: {'nickname': nickname},
        ),
      );
    } catch (e) {
      debugPrint('auth 메타데이터 닉네임 저장 오류: $e');
    }

    try {
      await supabase.from('profiles').upsert({
        'id': userId,
        'nickname': nickname,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // profiles 테이블이 아직 없을 수 있으므로 앱 동작은 계속 유지
      debugPrint('profiles 업서트 오류: $e');
    }
  }

  /// 프로필 아이콘 선택 저장 (로컬 SharedPreferences)
  Future<void> setProfileIcon(String icon) async {
    profileIcon = icon;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsProfileIconKey, icon);
    } catch (_) {}
  }

  Future<void> syncProfileFromRemote() async {
    if (userId == null) return;

    String? remoteNickname;
    try {
      final user = supabase.auth.currentUser;
      final fromAuth = user?.userMetadata?['nickname'];
      if (fromAuth is String && fromAuth.trim().isNotEmpty) {
        remoteNickname = fromAuth.trim();
      }
    } catch (_) {}

    if (remoteNickname == null) {
      try {
        final row = await supabase
            .from('profiles')
            .select('nickname')
            .eq('id', userId!)
            .maybeSingle();
        final fromProfile = row?['nickname'];
        if (fromProfile is String && fromProfile.trim().isNotEmpty) {
          remoteNickname = fromProfile.trim();
        }
      } catch (_) {}
    }

    if (remoteNickname != null) {
      nickname = remoteNickname;
      profileReady = true;
    } else {
      profileReady = false;
    }
    notifyListeners();
  }

  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.session == null) {
        return '로그인에 실패했어요. 이메일/비밀번호를 확인해주세요.';
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return '로그인에 실패했어요.\n$e';
    }
  }

  Future<String?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: authEmailRedirectUri(),
      );
      if (res.session == null) {
        return '회원가입 완료! 이메일 인증 후 로그인해주세요.';
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return '회원가입에 실패했어요.\n$e';
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: authEmailRedirectUri(),
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return '비밀번호 재설정 메일 발송에 실패했어요.\n$e';
    }
  }

  // 통계
  int get gotCount => stampedIds.length;
  int get totalStations => stations.length;
  double get completionPct {
    if (totalStations == 0) return 0;
    return gotCount / totalStations * 100;
  }

  void _checkBadgeUnlock(Station station, DateTime stampedAt) {
    final List<Badge> allBadges = [
      ...(kBadges['노선 완주'] ?? <Badge>[]),
      ...(kBadges['스토리'] ?? <Badge>[]),
    ];

    // 수집 개수 기반 배지
    final count = gotCount;
    _awardById(allBadges, 'b-first', count >= 1);
    _awardById(allBadges, 'b-10', count >= 10);
    _awardById(allBadges, 'b-50', count >= 50);
    _awardById(allBadges, 'b-100', count >= 100);
    _awardById(allBadges, 'b-500', count >= 500);

    // 시간/특수 조건 배지
    _awardById(allBadges, 'b-night', stampedAt.hour < 5);
    _awardById(allBadges, 'b-xmas', stampedAt.month == 12 && stampedAt.day == 25);
    _awardById(allBadges, 'b-airport', station.name.contains('공항') || station.line == '공항철도');

    // 노선/권역 완주 배지
    _awardLineCompletionBadge(allBadges, '1호선', 'b-l1');
    _awardLineCompletionBadge(allBadges, '2호선', 'b-l2');
    _awardLineCompletionBadge(allBadges, '3호선', 'b-l3');
    _awardLineCompletionBadge(allBadges, '4호선', 'b-l4');
    _awardLineCompletionBadge(allBadges, '5호선', 'b-l5');
    _awardLineCompletionBadge(allBadges, '6호선', 'b-l6');
    _awardLineCompletionBadge(allBadges, '7호선', 'b-l7');
    _awardLineCompletionBadge(allBadges, 'KTX', 'b-lktx');

    _awardById(allBadges, 'b-lbs', _isRegionComplete('부산'));
    _awardById(allBadges, 'b-ldg', _isRegionComplete('대구'));
    _awardById(allBadges, 'b-lgj', _isRegionComplete('광주'));
    _awardById(allBadges, 'b-ldj', _isRegionComplete('대전'));
  }

  void _syncStampedIdsFromStations() {
    stampedIds = stations.where((s) => s.got).map((s) => s.id).toSet();
    for (final s in stations.where((s) => s.got)) {
      stampDates[s.id] ??= DateTime.now();
    }
  }

  void _refreshBadges() {
    final List<Badge> allBadges = [
      ...(kBadges['노선 완주'] ?? <Badge>[]),
      ...(kBadges['스토리'] ?? <Badge>[]),
    ];

    final count = gotCount;
    _awardById(allBadges, 'b-first', count >= 1);
    _awardById(allBadges, 'b-10', count >= 10);
    _awardById(allBadges, 'b-50', count >= 50);
    _awardById(allBadges, 'b-100', count >= 100);
    _awardById(allBadges, 'b-500', count >= 500);

    final stampedTimes = stampDates.values.toList();
    _awardById(allBadges, 'b-night', stampedTimes.any((d) => d.hour < 5));
    _awardById(allBadges, 'b-xmas', stampedTimes.any((d) => d.month == 12 && d.day == 25));

    final airportStamped = stampedIds.any((id) {
      final idx = stations.indexWhere((s) => s.id == id);
      if (idx < 0) return false;
      final s = stations[idx];
      return s.name.contains('공항') || s.line == '공항철도';
    });
    _awardById(allBadges, 'b-airport', airportStamped);

    _awardLineCompletionBadge(allBadges, '1호선', 'b-l1');
    _awardLineCompletionBadge(allBadges, '2호선', 'b-l2');
    _awardLineCompletionBadge(allBadges, '3호선', 'b-l3');
    _awardLineCompletionBadge(allBadges, '4호선', 'b-l4');
    _awardLineCompletionBadge(allBadges, '5호선', 'b-l5');
    _awardLineCompletionBadge(allBadges, '6호선', 'b-l6');
    _awardLineCompletionBadge(allBadges, '7호선', 'b-l7');
    _awardLineCompletionBadge(allBadges, 'KTX', 'b-lktx');

    _awardById(allBadges, 'b-lbs', _isRegionComplete('부산'));
    _awardById(allBadges, 'b-ldg', _isRegionComplete('대구'));
    _awardById(allBadges, 'b-lgj', _isRegionComplete('광주'));
    _awardById(allBadges, 'b-ldj', _isRegionComplete('대전'));
  }

  void _awardLineCompletionBadge(List<Badge> badges, String line, String badgeId) {
    final lineStations = stations.where((s) => s.line == line).toList();
    if (lineStations.isEmpty) return;
    final completed = lineStations.every((s) => stampedIds.contains(s.id));
    _awardById(badges, badgeId, completed);
  }

  bool _isRegionComplete(String region) {
    final regionStations = stations.where((s) => s.region == region).toList();
    if (regionStations.isEmpty) return false;
    return regionStations.every((s) => stampedIds.contains(s.id));
  }

  void _awardById(List<Badge> badges, String id, bool achieved) {
    if (!achieved) return;
    final idx = badges.indexWhere((b) => b.id == id);
    if (idx < 0) return;
    if (!badges[idx].got) {
      badges[idx].got = true;
      _recentUnlockedBadges.add(badges[idx]);
      _persistBadgeUnlock(id);
    }
  }

  Future<void> _persistBadgeUnlock(String badgeId) async {
    if (userId == null) {
      await _enqueuePendingBadge(badgeId);
      return;
    }
    try {
      await supabase.from('user_badges').upsert(
        {
          'user_id': userId,
          'badge_id': badgeId,
          'earned_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,badge_id',
      );
    } catch (e) {
      debugPrint('배지 저장 오류: $e');
      await _enqueuePendingBadge(badgeId);
    }
  }

  Future<void> retryPendingBadges() async {
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingBadgesKey);
    if (raw == null || raw.isEmpty) return;

    List<dynamic> pending;
    try {
      pending = jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return;
    }
    if (pending.isEmpty) return;

    final remains = <String>[];
    for (final item in pending) {
      final badgeId = item.toString();
      try {
        await supabase.from('user_badges').upsert(
          {
            'user_id': userId,
            'badge_id': badgeId,
            'earned_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'user_id,badge_id',
        );
      } catch (_) {
        remains.add(badgeId);
      }
    }

    await prefs.setString(_pendingBadgesKey, jsonEncode(remains.toSet().toList()));
  }

  Future<void> _enqueuePendingBadge(String badgeId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingBadgesKey);
    List<dynamic> pending;
    try {
      pending = raw == null || raw.isEmpty ? <dynamic>[] : (jsonDecode(raw) as List<dynamic>);
    } catch (_) {
      pending = <dynamic>[];
    }
    pending.add(badgeId);
    final deduped = pending.map((e) => e.toString()).toSet().toList();
    await prefs.setString(_pendingBadgesKey, jsonEncode(deduped));
  }

  /// 서버 RPC [delete_own_account] 실행 후 로그아웃. (SQL은 supabase/delete_own_account.sql 참고)
  Future<String?> deleteOwnAccount() async {
    if (userId == null) return '로그인이 필요해요.';
    try {
      await supabase.rpc('delete_own_account');
    } catch (e) {
      return '탈퇴에 실패했어요. 네트워크를 확인하거나, Supabase에 delete_own_account 함수를 적용했는지 확인해주세요.\n$e';
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingStampsKey);
    await prefs.remove(_pendingBadgesKey);
    await signOut();
    return null;
  }

  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (_) {}
    userId = null;
    profileReady = false;
    nickname = '철도인';
    profileIcon = '🧳';
    stampedIds.clear();
    stampDates.clear();
    lastStampError = null;
    _recentUnlockedBadges.clear();
    for (final s in stations) {
      s.got = false;
      s.stampedAt = null;
    }
    // 배지 상태는 전부 false로
    for (final list in kBadges.values) {
      for (final b in list) {
        b.got = false;
      }
    }
    notifyListeners();
  }

  List<Station> get recentStations {
    final got = stations.where((s) => s.got).toList();
    got.sort((a, b) => (stampDates[b.id] ?? DateTime(0))
        .compareTo(stampDates[a.id] ?? DateTime(0)));
    return got.take(6).toList();
  }

  Map<String, Map<String, int>> get lineStats {
    final stats = <String, Map<String, int>>{};
    for (final s in stations) {
      stats.putIfAbsent(s.line, () => {'got': 0, 'total': 0});
      stats[s.line]!['total'] = stats[s.line]!['total']! + 1;
      if (s.got) stats[s.line]!['got'] = stats[s.line]!['got']! + 1;
    }
    return stats;
  }
}
