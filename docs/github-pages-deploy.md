# 정책 페이지 GitHub Pages 배포 가이드

## 목표
`docs/` 폴더의 HTML을 GitHub Pages로 공개해, 앱·스토어에서 고정 URL로 링크합니다.

## 1) 저장소 준비
- GitHub에 `yeokjangnim` 저장소(또는 실제 사용 중인 저장소 이름)에 코드를 push합니다.
- 정책 파일: `docs/privacy-policy.html`, `docs/terms.html`, (선택) 루트 안내 `docs/index.html`

## 2) Pages 설정
1. GitHub 저장소 → **Settings** → **Pages**
2. **Build and deployment**에서 **Deploy from a branch** 선택
3. **Branch**: `main`(또는 기본 브랜치) / **Folder**: **`/docs`** → Save

처음 배포 후 **1~10분** 정도 지나야 URL이 살아날 수 있습니다.

## 3) 공개 URL (예: 사용자 `kimjaehyeon221`, 저장소 `yeokjangnim`)
- 정책 목차(선택): `https://kimjaehyeon221.github.io/yeokjangnim/`
- 개인정보처리방침: `https://kimjaehyeon221.github.io/yeokjangnim/privacy-policy.html`
- 이용약관: `https://kimjaehyeon221.github.io/yeokjangnim/terms.html`

GitHub 사용자명·저장소 이름이 다르면 `...github.io/<저장소이름>/...` 만 본인 것으로 바꿉니다.

---

## GitHub Pages에 올라갔는지 확인하는 방법

1. **브라우저에서 직접 열기**  
   위 URL을 주소창에 붙여 넣습니다.  
   - 정상: 약관/개인정보 HTML이 보임  
   - **404**: Pages 미설정, 브랜치/폴더가 `/docs`가 아님, 아직 빌드 전, 또는 **저장소 이름·계정명이 URL과 다름**

2. **Settings → Pages**  
   상단에 **Your site is live at `https://...`** 같은 초록 안내가 뜨는지 확인합니다.

3. **Actions 탭**  
   Pages가 워크플로로 돌아가는 설정이면, 최근 실행이 성공(초록)인지 봅니다.  
   (브랜치 `/docs` 방식은 보통 Actions 없이 바로 게시됩니다.)

4. **로컬과 원격**  
   `docs/*.html`을 수정만 하고 **push 안 했으면** 사이트는 옛내용이거나 404일 수 있습니다. 반드시 **push 후** 다시 확인합니다.

---

## 4) 앱 링크와 일치 확인
- `lib/main.dart`의 `kPrivacyPolicyUrl`, `kTermsUrl`이 **실제로 열리는 위 URL**과 문자 그대로 같아야 합니다.
- GitHub 사용자명·저장소 이름이 바뀌면 `lib/main.dart`의 정책 URL과 Supabase Redirect도 같이 맞추세요.

## 5) 배포 직전 체크
- 시크릿 창에서 약관·개인정보 URL 두 개 모두 열어보기
- 앱(또는 웹)에서 같은 버튼으로 열어보기
