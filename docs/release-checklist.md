# 역 도감 출시 체크리스트 (Android · iOS)

## 1) 필수 설정
- [ ] `applicationId`를 고유 값으로 변경 (`com.example...` 금지)
- [ ] 릴리즈 서명용 키스토어 생성
- [ ] `android/app/build.gradle.kts`에 release signingConfig 적용
- [ ] 버전 코드/버전명 업데이트

## 2) 정책/문서
- [ ] GitHub Pages 등 **공개 URL**에서 개인정보처리방침·이용약관이 200으로 열리는지 확인 (`docs/github-pages-deploy.md` 참고)
- [ ] **Play Console 붙여넣기 URL**: `docs/PLAY_STORE_MANUAL_KO.md` 표 참고
- [ ] 앱 내 `kPrivacyPolicyUrl`, `kTermsUrl`과 실제 URL 일치
- [ ] 로그인 화면·나 탭에서 정책 링크 동작 확인

## 3) 기능 검증
- [ ] 이메일 로그인·인증 메일·비밀번호 재설정(Supabase Redirect URL 포함)
- [ ] 위치 권한 허용/거부 케이스 안내 문구 검증
- [ ] 스탬프 오프라인 저장 후 온라인 재동기화 확인
- [ ] 배지 획득/저장/재로그인 후 복원 확인
- [ ] 공유(도감 공유 등) 동작 확인

## 4) iOS (App Store) — 코드에 반영된 것
- `PRODUCT_BUNDLE_IDENTIFIER`: `io.github.kjh96.yeokjangnim` (Xcode에서 팀·서명만 연결)
- `PrivacyInfo.xcprivacy`: UserDefaults / 파일 타임스탬프 / 디스크 여유 / 부팅 시각 등 **필수 사유 API** 선언 (ITMS-91053 대비)
- `ITSAppUsesNonExemptEncryption` = `false` (HTTPS 등 면제 암호화만 쓰는 경우 일반적; 실제 암호화 사용 시 심사 전 재확인)
- 최소 iOS **15.0** (`IPHONEOS_DEPLOYMENT_TARGET`)

### iOS에서 직접 할 일 (Mac + Xcode)
- [ ] Apple Developer Program 가입 후 **Signing & Capabilities**에 팀 선택, **Release** 서명 자동/수동 설정
- [ ] App Store Connect에 앱 등록(번들 ID 동일), 개인정보·데이터 수집 설문(앱 내 URL과 일치)
- [ ] Supabase **iOS 리다이렉트 URL**·Universal Link 필요 시 Associated Domains 추가
- [ ] `flutter build ipa` 또는 Xcode **Archive → Distribute App**

## 5) 빌드/배포 (Android)
- [ ] `android/key.properties.example`를 복사해 `android/key.properties` 생성
- [ ] `upload-keystore.jks` 파일 생성 후 `key.properties` 값 입력
- [ ] `flutter pub get`
- [ ] `flutter build appbundle --release`
- [ ] Play Console 내부 테스트 트랙 업로드
- [ ] 테스터 검증 후 프로덕션 배포

## 참고
- 현재 프로젝트는 `applicationId`를 `io.github.kjh96.yeokjangnim`으로 설정했습니다.
- 실제 배포 조직 기준으로 필요하면 한 번만 최종 변경 후 고정하세요.
- 키스토어 생성 예시:
  `keytool -genkey -v -keystore upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000`
