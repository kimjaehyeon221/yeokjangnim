# 역 컬렉터 (Metro Collector)

전국 철도역 스탬프 수집 앱 (Flutter). 저장소·패키지 식별자: `yeokjangnim`.

## 문서

- 개인정보처리방침(초안): `docs/privacy-policy.md` · 웹용 HTML: `docs/privacy-policy.html`
- 이용약관(초안): `docs/terms.md` · 웹용 HTML: `docs/terms.html`
- GitHub Pages 배포·**올라갔는지 확인하는 방법**: `docs/github-pages-deploy.md`
- 배포 체크리스트: `docs/release-checklist.md`
- **Play 스토어 — 정책 URL 복사 & 본인이 할 일만**: `docs/PLAY_STORE_MANUAL_KO.md`
- 역 데이터 갱신: `docs/STATION_DATA_UPDATE_KO.md`

정책 공개 URL(저장소가 `kimjaehyeon221/yeokjangnim`이고 Pages 소스가 `/docs`일 때):

- https://kimjaehyeon221.github.io/yeokjangnim/
- https://kimjaehyeon221.github.io/yeokjangnim/privacy-policy.html
- https://kimjaehyeon221.github.io/yeokjangnim/terms.html

> **지금 404가 나오면** 저장소 Settings → Pages에서 **Branch + `/docs`** 를 켰는지, `main`에 `docs/*.html`이 push 됐는지 확인하세요. 자세한 절차는 `docs/github-pages-deploy.md`를 보세요.

## 개발 실행

1. `flutter pub get`
2. `flutter run`

## 릴리즈 사전 점검

- PowerShell: `./scripts/release_preflight.ps1 -ProjectRoot .`

## Supabase SQL

다음을 SQL Editor에서 프로젝트에 맞게 실행:

1. `supabase/profiles_schema.sql`
2. `supabase/stamps_schema.sql`
3. `supabase/stations_schema.sql` (사용 시)
4. `supabase/user_badges_schema.sql`
5. 탈퇴 기능 사용 시: `supabase/delete_own_account.sql`

Auth URL·Redirect·기타 콘솔 작업: `supabase/CONSOLE_CHECKLIST_KO.txt`

## Android 식별자

- `applicationId`: `io.github.kjh96.yeokjangnim`
