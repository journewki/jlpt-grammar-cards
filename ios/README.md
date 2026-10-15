# iOS 앱 실행 방법

## 준비물 (처음 한 번)
- Mac + Xcode 15 이상 (App Store에서 설치)
- Homebrew (https://brew.sh)
- XcodeGen: 터미널에서 `brew install xcodegen`

## 프로젝트 만들고 실행
```bash
git clone https://github.com/journewki/jlpt-grammar-cards.git
cd jlpt-grammar-cards
git checkout claude/grammar-db
cd ios
xcodegen generate        # GrammarCards.xcodeproj 생성
open GrammarCards.xcodeproj
```
Xcode가 열리면:
1. 위쪽 기기 선택에서 **iPhone 15 (시뮬레이터)** 등을 고르고 ▶ (Cmd+R)
2. 내 아이폰에 설치하려면: 왼쪽에서 GrammarCards 프로젝트 → Signing & Capabilities → Team 에 본인 Apple ID 선택 → 아이폰을 연결하고 기기 선택 후 ▶
3. 테스트 실행: Cmd+U (카드 데이터 읽기, 후리가나 처리, 사이클 구성 확인)

`project.yml` 이나 파일 구성이 바뀌면 `xcodegen generate` 를 다시 실행하면 된다.
`GrammarCards.xcodeproj` 는 생성물이라 git에 올리지 않는다.

## 구조
```
ios/
├── project.yml                 XcodeGen 설정 (데이터는 ../data/n1~n5.json 을 번들에 포함)
├── GrammarCards/
│   ├── GrammarCardsApp.swift   앱 시작점 (SwiftData 컨테이너)
│   ├── Model/
│   │   ├── Models.swift        카드 데이터 모델, 학습 기록(CardProgress, ReviewLog)
│   │   ├── StudySession.swift  사이클 구성(모름 카드 + 새 카드 섞기), 진행 상태
│   │   ├── ContentStore.swift  번들 JSON 읽기
│   │   ├── ProgressRepository.swift  알고 있음/모름 기록 저장
│   │   └── Ruby.swift          {漢字|かんじ} 후리가나 마크업 해석
│   ├── Views/
│   │   ├── HomeView.swift      급수 목록 + 진도
│   │   ├── LevelView.swift     학습 시작 / 모름 복습 / 카드 목록
│   │   ├── StudyView.swift     카드 학습 (스와이프, 뜻 보기) + 결과
│   │   ├── CardFaceView.swift  카드 한 장
│   │   ├── RubyText.swift      후리가나 예문 표시
│   │   └── SettingsView.swift  카드 수, 모름 비율, 표시 설정
│   └── Support/AppSettings.swift
└── GrammarCardsTests/
```
