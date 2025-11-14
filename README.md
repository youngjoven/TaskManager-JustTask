# Just Task

Gmail 라벨 기반 과업 관리 iOS 애플리케이션

<img width="856" height="571" alt="그림" src="https://github.com/user-attachments/assets/6d465493-1217-463f-be82-47e27b54b047" />

## 개요

Just Task는 Gmail의 라벨을 활용하여 이메일을 과업으로 변환하고 관리하는 iOS 앱입니다. AI 요약 기능을 통해 이메일 내용을 자동으로 분석하고, 캘린더 형태로 과업을 시각화합니다.

## 주요 기능

### 📧 Gmail 연동
- OAuth 2.0 기반 안전한 Google 계정 인증
- 사용자가 생성한 Gmail 라벨 자동 가져오기
- 최신 이메일순 자동 정렬
- 최대 20개의 최근 이메일 가져오기

### 🤖 AI 요약
- Gemini 2.0 Flash API를 활용한 이메일 자동 요약
- 최신 3개 이메일에 대한 지능형 분석
- 주제, 일시, 장소, 관련 인원 자동 추출
- 향후 과업 자동 도출

### 📅 캘린더형 UI
- 월별 캘린더 뷰로 과업 관리
- 날짜별 과업 개수 표시
- 선택한 날짜의 과업 상세 보기
- 다크모드 지원

### 🏷️ 라벨 기반 분류
- Gmail 라벨을 활용한 업무 분류
- 라벨별 최신 이메일 날짜 표시
- 한 번에 하나의 라벨 선택

## 기술 스택

- **언어**: Swift
- **프레임워크**: SwiftUI
- **최소 지원**: iOS 15.0+
- **API**:
  - Gmail API (Google Cloud)
  - Gemini 2.0 Flash API (Google AI Studio)
- **인증**: OAuth 2.0 (GoogleSignIn SDK)
- **의존성 관리**: Swift Package Manager

## 프로젝트 구조

```
GmailTaskManager/
├── Models/
│   ├── Task.swift              # EmailTask 데이터 모델
│   └── GmailLabel.swift        # Gmail 라벨 모델
├── Views/
│   ├── MainView.swift          # 메인 네비게이션
│   ├── LoginView.swift         # 로그인 화면
│   ├── LabelSelectionView.swift # 라벨 선택
│   └── CalendarView.swift      # 캘린더 UI
├── Services/
│   ├── GmailService.swift      # Gmail API 서비스
│   └── GeminiService.swift     # Gemini AI 서비스
├── Config.swift                # ⚠️ API 키 (gitignored)
├── Config.swift.example        # 설정 템플릿
└── Assets.xcassets/
    └── AppIcon.appiconset/     # 앱 아이콘
```

## 설치 및 실행

### 사전 요구사항

- macOS (Xcode 실행 환경)
- Xcode 14.0 이상
- iOS 15.0+ 지원 기기
- Google Cloud Console 계정
- Google AI Studio 계정

### 1. 저장소 클론

```bash
git clone https://github.com/youngjoven/TaskManager-JustTask.git
cd TaskManager-JustTask
```

### 2. API 키 설정

#### Config.swift 파일 생성

```bash
cd GmailTaskManager
cp Config.swift.example Config.swift
```

`Config.swift` 파일을 열고 다음 값들을 설정하세요:

#### Google OAuth Client ID 발급

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 프로젝트 생성 또는 선택
3. **APIs & Services > Credentials** 이동
4. **Create Credentials > OAuth 2.0 Client ID** 선택
5. **Application type**: iOS 선택
6. **Bundle ID**: `com.yjgwon.GmailTaskManager` 입력
7. 생성된 Client ID를 `Config.swift`에 입력

#### Gemini API Key 발급

1. [Google AI Studio](https://aistudio.google.com/app/apikey) 접속
2. **Create API Key** 클릭
3. 생성된 API Key를 `Config.swift`에 입력

#### GoogleService-Info.plist 설정

1. Google Cloud Console에서 OAuth 2.0 Client 설정 파일 다운로드
2. 파일을 `GmailTaskManager/` 폴더에 복사
3. Xcode에서 프로젝트에 추가

### 3. Xcode 프로젝트 열기

⚠️ **중요**: `.xcodeproj` 폴더는 Git에 포함되어 있지 않습니다.

Xcode에서 새 프로젝트를 생성하고 소스 파일을 추가하세요:

1. Xcode 실행
2. **File > New > Project**
3. **iOS > App** 선택
4. 프로젝트 설정:
   - **Product Name**: GmailTaskManager
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Bundle Identifier**: com.yjgwon.GmailTaskManager
5. 클론한 폴더를 선택하여 저장
6. 기존 소스 파일들이 자동으로 인식됨

### 4. Swift Package 의존성 추가

Xcode에서:
1. **File > Add Package Dependencies**
2. URL 입력: `https://github.com/google/GoogleSignIn-iOS`
3. **Add Package** 클릭

### 5. 빌드 및 실행

1. 타겟 기기 선택 (시뮬레이터 또는 실제 기기)
2. **Signing & Capabilities**에서 Team 선택
3. **Cmd + R**로 빌드 및 실행

## 보안 주의사항

⚠️ **다음 파일들은 절대로 Git에 커밋하지 마세요:**

- `Config.swift` - API 키 및 Client ID 포함
- `GoogleService-Info.plist` - OAuth 설정 포함
- `*.xcodeproj/` - 프로젝트 설정 (개인 경로 포함)
- `xcuserdata/` - 사용자별 Xcode 설정

이 파일들은 이미 `.gitignore`에 추가되어 있습니다.

### 민감한 정보 확인

```bash
# Git에 추적되는 파일 중 민감한 정보 확인
git ls-files | grep -E "Config\.swift|GoogleService-Info\.plist"

# 아무것도 출력되지 않아야 정상입니다!
```

## 문제 해결

### 빌드 오류

**"No such module 'GoogleSignIn'"**
- File > Add Package Dependencies 확인
- Clean Build Folder (Cmd + Shift + K) 실행

**"Config.swift file not found"**
- `Config.swift.example`을 `Config.swift`로 복사했는지 확인
- API 키를 올바르게 입력했는지 확인

### 런타임 오류

**"403 emm_app_verification_required"**
- Google Cloud Console > OAuth consent screen
- Test users에 사용자 계정 추가

**"Gemini API Error 400"**
- Gemini API Key가 올바른지 확인
- Google AI Studio에서 API 활성화 확인

## 개발 로드맵

- [x] Gmail API 연동
- [x] OAuth 2.0 인증
- [x] AI 요약 기능 (Gemini 2.0 Flash)
- [x] 캘린더형 UI
- [x] 다크모드 지원
- [x] 라벨별 정렬
- [ ] 과업 완료 표시
- [ ] 로컬 데이터 저장 (CoreData)
- [ ] Pull-to-refresh
- [ ] 푸시 알림
- [ ] App Store 배포

## 라이선스

이 프로젝트는 개인 사용을 위한 것입니다.

## 기여

현재 개인 프로젝트로 진행 중입니다.
