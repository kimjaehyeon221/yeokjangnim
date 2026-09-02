# Station Archive · 역 도감

**직접 가본 철도역을 GPS로 인증하고 스탬프로 수집하는 위치 기반 아카이브 앱입니다.**

지하철이나 기차역은 매일 지나치는 장소지만, 시간이 지나면 내가 어떤 역을 얼마나 경험했는지는 남지 않습니다. Station Archive는 실제 방문을 하나의 수집 경험으로 바꿔 **‘내가 직접 가본 도시의 흔적’**을 쌓아가는 앱입니다.

> **Concept**  
> 현실의 장소 방문을 디지털 수집 경험으로 바꾸면, 평범한 이동도 탐험이 될 수 있을까?

## What it does

- 전국 철도·도시철도 역 탐색
- 현재 위치를 이용한 **역 방문 인증**
- 방문한 역의 스탬프 수집
- 내가 모은 역과 아직 가보지 않은 역 구분
- 프로필과 수집 기록 저장
- 역별 수집 데이터를 기반으로 한 장기적인 도감 경험

## Product idea

관광지 스탬프처럼 특별한 장소만 수집하는 대신, **일상적으로 이동하는 역 자체를 수집 단위**로 삼았습니다. 사용자가 실제로 이동해야만 빈칸이 채워지고, 시간이 지나면서 자신의 이동 범위가 하나의 개인적인 지도와 도감으로 남는 것이 핵심입니다.

## Status

**현재 개발 중**

제품 구조와 UI를 계속 다듬고 있으며, 실제 위치 인증과 수집 경험을 중심으로 개발하고 있습니다.

## Tech

- Flutter
- GPS / location verification
- Supabase
- Android / iOS

## Screenshots

현재 개발 중인 실제 화면을 이 섹션에 추가해 `역 발견 → 직접 방문 → 위치 인증 → 스탬프 수집` 흐름을 한눈에 보여줄 예정입니다.

## Documents

- 개인정보처리방침(초안): `docs/privacy-policy.md`
- 이용약관(초안): `docs/terms.md`
- 배포 체크리스트: `docs/release-checklist.md`
- 역 데이터 갱신: `docs/STATION_DATA_UPDATE_KO.md`

## Development

1. `flutter pub get`
2. `flutter run`
