# 출시 체크리스트

## A. 앱 준비 (저장소에서 완료됨)
- [x] 앱 아이콘 (ios/GrammarCards/Assets.xcassets)
- [x] 개인정보 매니페스트 (ios/PrivacyInfo.xcprivacy)
- [x] 암호화 수출 규정 (ITSAppUsesNonExemptEncryption = NO)
- [x] 앱 이름·설명·키워드 초안 (docs/app-store-listing.md)
- [x] 개인정보처리방침 초안 (docs/privacy-policy.md)
- [ ] 예문 검수 (review/n1~n5.md)

## B. 웹에 올려 둘 것 (URL 필요)
- [ ] 개인정보처리방침 페이지 → Notion 등에 docs/privacy-policy.md 내용을 공개 페이지로 게시
- [ ] 지원(Support) URL → 같은 페이지에 문의 이메일 적어서 사용해도 됨

## C. App Store Connect (https://appstoreconnect.apple.com)
1. [ ] 비즈니스 → **유료 앱 계약** 동의 + 은행 계좌·세금 정보 입력 (앱 내 구입 판매에 필수, 처리에 며칠 걸릴 수 있음)
2. [ ] 나의 앱 → + → 신규 앱: iOS, 이름, 기본 언어 한국어, 번들 ID `com.journewki.grammarcards`, SKU
   - 번들 ID가 목록에 없으면 developer.apple.com → Identifiers 에서 먼저 등록 (Xcode에서 서명하면 자동 등록되기도 함)
3. [ ] 수익화 → 앱 내 구입 → 비소모성 상품 추가 (docs/app-store-listing.md 표 참고)
4. [ ] 앱 정보: 카테고리, 연령 등급, 개인정보처리방침 URL
5. [ ] 앱 개인정보 보호: 데이터를 수집하지 않음
6. [ ] 가격 및 사용 가능 여부: 무료, 판매 국가 선택

## D. 빌드 업로드 (Mac, Xcode)
1. [ ] `cd ios && xcodegen generate && open GrammarCards.xcodeproj`
2. [ ] Signing & Capabilities → Team 선택, Automatically manage signing 체크
3. [ ] 상단 기기 선택을 **Any iOS Device (arm64)** 로 변경
4. [ ] 메뉴 Product → **Archive**
5. [ ] Organizer 창 → **Distribute App** → App Store Connect → Upload
6. [ ] 10~30분 뒤 App Store Connect → TestFlight 에 빌드가 나타남
- 다시 올릴 때는 project.yml 의 `CURRENT_PROJECT_VERSION` 을 1씩 올린다 (같은 번호는 업로드 불가)

## E. 실기기 테스트 (TestFlight — 케이블 불필요)
1. [ ] 아이폰에 TestFlight 앱 설치
2. [ ] App Store Connect → TestFlight → 내부 테스트 그룹에 본인 Apple ID 추가
3. [ ] 아이폰 TestFlight 앱에서 설치 → 학습·소리·결제(샌드박스, 실제 결제 안 됨) 확인

## F. 심사 제출
1. [ ] 스크린샷: 6.9인치(iPhone 16 Pro Max 시뮬레이터) 최소 1장, 최대 10장
   - 시뮬레이터에서 Cmd+S 로 저장. 홈 / 학습 카드 / 뜻 보기 / 결제 화면 추천
2. [ ] 설명·키워드·홍보 문구·지원 URL 입력
3. [ ] 빌드 선택, 앱 내 구입 상품을 이 버전에 포함
4. [ ] 심사 메모 입력 → **심사에 제출** (보통 1~3일)
5. [ ] 승인 후 출시 (자동 또는 수동)
