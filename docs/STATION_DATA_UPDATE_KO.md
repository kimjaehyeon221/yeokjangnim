# 역(스탬프) 데이터 갱신 절차

앱은 `lib/station_api.dart`의 `loadBundledStations()` 기준으로 번들을 읽습니다.

## 우선순위

1. **`assets/stations.json`**이 있고 JSON 배열이 **비어 있지 않으면** → 이 파일만 사용합니다.
2. 비어 있거나 없으면 → **`assets/stations_korail.json`** 과 **`assets/stations_metro_kric.json`**을 이름+노선 키로 합칩니다. (파일이 없으면 해당 분만 건너뜀)

`pubspec.yaml`의 `flutter.assets`에 위 경로가 등록돼 있어야 합니다.

---

## A. 도시철도 역만 KRIC 엑셀에서 갱신

국토교통부 KRIC 등에서 받은 **전체 도시철도 역사 정보 XLSX**를 사용합니다.

프로젝트 루트에서:

```bash
dart run tool/kric_xlsx_to_stations.dart "다운로드한파일.xlsx"
```

- 출력: **`assets/stations_metro_kric.json`** (스크립트가 `assets` 폴더를 만들고 덮어씀)
- 앱이 **`stations.json` 단일 번들**을 쓰는 배포 상태라면, metro만 바꿔도 반영되지 않습니다. 그 경우 B를 참고하거나 `stations.json`을 비우고 korail+metro 병합 경로를 쓰도록 맞춥니다.

엑셀 컬럼 매핑·노선 정규화 규칙은 `tool/kric_xlsx_to_stations.dart` 주석·코드를 기준으로 합니다.

---

## B. 공공데이터 포털 API로 통합 `stations.json` 생성

코레일·도시철도 등 오픈API를 코드에서 모아 **한 JSON**으로 씁니다.

```bash
dart run tool/export_stations.dart
```

인증키(Encoding)를 넘기려면:

```bash
dart run --dart-define=ODCLOUD_SERVICE_KEY=포털에서_복사한_Encoding키 tool/export_stations.dart
```

- 출력: **`assets/stations.json`**
- 이 파일이 비어 있지 않으면 앱은 **병합 없이** 이것만 사용합니다.

---

## 배포 전 체크

- 갱신한 JSON이 **커밋·빌드 에셋에 포함**됐는지 확인합니다.
- `flutter test`로 최소 스모크 테스트를 한 번 돌려 둡니다.
