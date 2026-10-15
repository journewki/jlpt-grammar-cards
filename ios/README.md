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

## 결제(평생 이용권) 테스트
- 무료 사용자는 1사이클만 학습할 수 있다. 무료 사이클은 카드 목록과 진행 상황이 저장되어, 중간에 나갔다 와도 같은 급수에서 이어서 끝까지 할 수 있다. 마지막 카드까지 답하면 무료 체험이 끝난다.
- 시뮬레이터에서는 `Products.storekit`(로컬 테스트용 상품, ₩15,900)이 자동으로 쓰여서 App Store Connect 없이 결제 흐름을 테스트할 수 있다.
- 결제 기록 지우기: Xcode 메뉴 Debug → StoreKit → Manage Transactions 에서 삭제
- 무료 사이클 다시 쓰기: 시뮬레이터에서 앱 삭제 후 재설치

### 실제 출시 때 (App Store Connect)
1. 앱 등록 후 **유료 앱 계약**(비즈니스 → 계약, 세금 및 은행 정보) 완료
2. 앱 내 구입 → **비소모성** 상품 추가, 제품 ID `com.journewki.grammarcards.lifetime`, 가격 ₩15,900
3. 심사용 스크린숏·설명 입력 후 앱 버전과 함께 심사 제출

`project.yml` 이나 파일 구성이 바뀌면 `xcodegen generate` 를 다시 실행하면 된다.
`GrammarCards.xcodeproj` 는 생성물이라 git에 올리지 않는다.

## 구조
```
ios/
├── project.yml                 XcodeGen 설정 (데이터는 ../data/n1~n5.json 을 번들에 포함)
├── Products.storekit           로컬 결제 테스트용 상품 정보
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
│   │   ├── PaywallView.swift   평생 이용권 구매 화면
│   │   └── SettingsView.swift  카드 수, 모름 비율, 표시 설정, 이용권
│   └── Support/
│       ├── AppSettings.swift   설정 키
│       ├── Speaker.swift       일본어 TTS (예문 읽기)
│       ├── Store.swift         평생 이용권 결제 (StoreKit 2)
│       └── RelativeTime.swift  "3일 전" 표시
└── GrammarCardsTests/
```
