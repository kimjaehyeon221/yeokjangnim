# Play Console — 복사용 URL & 본인이 할 일만

앱 이름: **역 컬렉터** · 패키지: `io.github.kjh96.yeokjangnim`

---

## Play Console에 그대로 붙여 넣을 주소 (정책)

| 항목 | URL |
|------|-----|
| **개인정보처리방침** | `https://kimjaehyeon221.github.io/yeokjangnim/privacy-policy.html` |
| **이용약관** (별도 입력란 있을 때) | `https://kimjaehyeon221.github.io/yeokjangnim/terms.html` |
| 정책 목차(참고) | `https://kimjaehyeon221.github.io/yeokjangnim/` |

> 스토어 UI마다 라벨이 다릅니다. **“개인정보처리방침 URL”** / **“Privacy policy”** 칸에는 위 개인정보 URL만 넣으면 됩니다.

---

## 저장소에 이미 맞춰 둔 것 (코드)

- `lib/main.dart` — `kPrivacyPolicyUrl`, `kTermsUrl` 위와 동일
- 앱 내 로그인·나 탭 링크가 위 주소로 열림
- Android 표시 이름: **역 컬렉터** (`AndroidManifest` 등) · 스토어 영문 등: Metro Collector

---

## 반드시 본인이 Play Console·로컬에서 할 일

아래는 제가 대신할 수 없는 작업입니다.

1. **Google Play Console** 접속 → 앱 만들기(또는 기존 앱 선택)
2. **스토어 설정**에서 앱 이름, 짧은 설명, 전체 설명, 그래픽(아이콘·스크린샷) 입력
3. **앱 콘텐츠** → 데이터 안전, 광고 여부, 타겟 연령, 뉴스 앱 여부 등 설문 작성
4. **개인정보처리방침** 필드에 위 표의 **개인정보 URL** 입력
5. **로컬 PC**에서:
   - `android/key.properties` 존재 확인 (`key.properties.example` 참고)
   - 릴리즈용 `.jks` 경로·비밀번호가 올바른지 확인
   - 터미널: `flutter pub get` 후 `flutter build appbundle --release`
6. 생성된 **`build/app/outputs/bundle/release/app-release.aab`** 를 Console에 **내부 테스트** 등으로 업로드
7. 테스터로 설치 테스트 후 **프로덕션** 제출

---

## 버전 올릴 때

- `pubspec.yaml`의 `version: x.y.z+빌드번호` — `+` 뒤 숫자가 Android **versionCode**로 올라갑니다. 재업로드마다 **반드시 증가**해야 합니다.
