-- GrammarCards DB schema (SQLite)
--
-- 설계 원칙
--   * 콘텐츠(문법/예문)와 사용자 학습 기록을 분리한다.
--     콘텐츠는 앱 번들에 읽기 전용 DB로 넣고, 학습 기록은 기기(SwiftData/iCloud)에 저장.
--     → 책 내용 수정/추가로 콘텐츠 DB를 교체해도 사용자 진도가 날아가지 않음.
--   * 연결 키는 책의 문법 번호(grammar.no)를 그대로 쓴다. 번호는 절대 재사용하지 않는다.

------------------------------------------------------------
-- 1. 콘텐츠 (읽기 전용, 번들)
------------------------------------------------------------

CREATE TABLE grammar (
    no            INTEGER PRIMARY KEY,    -- 책에 매겨진 문법 번호 (안정적 ID)
    expression    TEXT NOT NULL,          -- 카드 앞면: 〜ばかりに
    reading       TEXT,                   -- 한자 포함 표현일 때 읽기: 〜方 → かた
    category      TEXT NOT NULL,          -- 같은 모양 구분용 분류: 명사 / な형용사 / 동사 て형 …
    meaning_ko    TEXT NOT NULL,          -- 뜻 (직접 작성)
    connection    TEXT NOT NULL,          -- 접속 (직접 작성)
    jlpt_level    TEXT NOT NULL CHECK (jlpt_level IN ('N5','N4','N3','N2','N1'))  -- 급수별 덱 분리 기준
);
-- 표현·급수의 출처(책 쪽수/단원)는 data/source/book_index.json 에 따로 보관 (검수용, 앱에는 안 들어감)

CREATE TABLE example (
    id            INTEGER PRIMARY KEY,
    grammar_no    INTEGER NOT NULL REFERENCES grammar(no),
    sentence_ja   TEXT NOT NULL,          -- 루비 마크업: {油断|ゆだん}した
    translation_ko TEXT NOT NULL,
    highlights    TEXT NOT NULL,          -- 강조할 문법 부분 JSON 배열 (예: ["に","があります"])
    is_primary    INTEGER NOT NULL DEFAULT 1,  -- 카드에 쓰는 대표 예문 (지금은 문법당 1개)
    UNIQUE (grammar_no, is_primary)
);

CREATE INDEX idx_grammar_level   ON grammar(jlpt_level);

------------------------------------------------------------
-- 2. 사용자 학습 기록 (기기 저장 — 실제 앱에선 SwiftData 모델, 아래는 참고용)
------------------------------------------------------------

CREATE TABLE card_progress (
    grammar_no      INTEGER PRIMARY KEY,  -- grammar.no
    jlpt_level      TEXT NOT NULL,        -- 급수별 진도/복습 조회용
    status          TEXT NOT NULL DEFAULT 'new'
                    CHECK (status IN ('new','unknown','known')),
    unknown_count   INTEGER NOT NULL DEFAULT 0,   -- "모름" 누른 횟수 (취약 문법 정렬용)
    last_reviewed_at TEXT,
    is_bookmarked   INTEGER NOT NULL DEFAULT 0
);

-- 사이클 구성 규칙 (ios/StudySession.swift: SessionBuilder)
--   한 사이클 = cards_per_session장, 선택한 급수 안에서만 뽑음
--   1) unknown 카드 round(N * review_ratio)장 (오래전에 본 순 → 모름 횟수 많은 순)
--   2) new 카드로 나머지 (책 번호 순)
--   3) 모자라면 unknown → known(오래된 순)으로 채운 뒤 셔플
--   모름 → 다음 사이클들에 계속 섞여 나옴, 알고 있음 누르면 졸업

CREATE TABLE review_log (                -- 통계/잔디용
    id          INTEGER PRIMARY KEY,
    grammar_no  INTEGER NOT NULL,
    result      TEXT NOT NULL CHECK (result IN ('known','unknown')),
    reviewed_at TEXT NOT NULL
);
