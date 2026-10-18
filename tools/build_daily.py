"""일상표현 원고(TSV)를 검증하고 data/daily.json 으로 만든다.

원고: tools/content/daily/*.tsv, 한 줄에 한 표현
    id<TAB>meaning_ko<TAB>sentence_ja<TAB>translation_ko<TAB>highlights(;로 구분)
표현 자체는 data/source/daily_index.json (책 인덱스 전사본) 에서 가져온다.

사용법:
    python3 tools/build_daily.py            # 전체 빌드
    python3 tools/build_daily.py FILE.tsv   # 원고 파일 하나만 검사
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RUBY = re.compile(r"\{([^{}|]+)\|([^{}|]+)\}")
KANJI = re.compile(r"[一-鿿々]")
# 일상표현에는 {3D|スリーディー}, {Wi-Fi|ワイファイ} 처럼 영숫자에 읽기를 단 루비도 있다
RUBY_BASE = re.compile(r"[一-鿿々A-Za-z0-9０-９Ａ-Ｚａ-ｚ]")


def strip_ruby(s):
    return RUBY.sub(lambda m: m.group(1), s)


def reading_of(s):
    """루비를 읽기로 바꾼 전체 읽기 (괄호 속 보충 설명은 뺀다)"""
    s = re.sub(r"[(（][^()（）]*[)）]", "", s)
    return RUBY.sub(lambda m: m.group(2), s).strip()


def validate(i, sentence, highlights):
    errors = []
    if sentence.count("{") != sentence.count("}"):
        errors.append("괄호 짝 안 맞음")
    outside = RUBY.sub("", sentence)
    if KANJI.search(outside):
        errors.append(f"루비 없는 한자: {''.join(KANJI.findall(outside))}")
    for m in RUBY.finditer(sentence):
        if KANJI.search(m.group(2)) or not RUBY_BASE.search(m.group(1)):
            errors.append(f"루비 형식 이상: {m.group(0)}")
    plain = strip_ruby(sentence)
    if not highlights:
        errors.append("강조 없음")
    pos = 0
    for h in highlights:
        k = plain.find(h, pos)
        if k < 0:
            errors.append(f"강조 '{h}' 를 찾을 수 없음")
            break
        pos = k + len(h)
    return [f"#{i}: {e}" for e in errors]


def load(path, index):
    errors, rows = [], {}
    for n, line in enumerate(Path(path).read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip() or line.startswith("id\t"):
            continue
        parts = line.split("\t")
        if len(parts) != 5:
            errors.append(f"{path}:{n}: 필드 수 {len(parts)} (5개여야 함)")
            continue
        i, meaning, sentence, translation, hl = (p.strip() for p in parts)
        if not i.isdigit() or int(i) not in index:
            errors.append(f"{path}:{n}: 목록에 없는 id {i}")
            continue
        i = int(i)
        if i in rows:
            errors.append(f"#{i}: 중복")
        if not meaning or not translation:
            errors.append(f"#{i}: 뜻/해석 비어 있음")
        highlights = [h for h in hl.split(";") if h]
        errors += validate(i, sentence, highlights)
        rows[i] = (meaning, sentence, translation, highlights)
    return rows, errors


def main(args):
    index = {e["id"]: e for e in json.loads((ROOT / "data/source/daily_index.json").read_text())}
    files = [Path(a) for a in args] or sorted((ROOT / "tools/content/daily").glob("*.tsv"))
    rows, errors = {}, []
    for f in files:
        r, e = load(f, index)
        errors += e
        dup = rows.keys() & r.keys()
        errors += [f"#{i}: 여러 파일에 중복" for i in sorted(dup)]
        rows.update(r)
    if errors:
        print("\n".join(errors))
        raise SystemExit(1)
    if args:
        print(f"OK: {len(rows)}개")
        return

    missing = sorted(index.keys() - rows.keys())
    cards = []
    for i in sorted(rows):
        meaning, sentence, translation, highlights = rows[i]
        entry = index[i]
        cards.append({
            "no": i,
            "expression": entry["plain"],
            "reading": reading_of(entry["ruby"]) if KANJI.search(entry["plain"]) else None,
            "category": "",
            "meaning_ko": meaning,
            "connection": "",
            "example": {
                "sentence_ja": sentence,
                "translation_ko": translation,
                "highlights": highlights,
            },
        })
    out = {"version": 1, "level": "DAILY", "grammar": cards}
    (ROOT / "data/daily.json").write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n")
    print(f"일상표현: 카드 {len(cards)}개 작성, 빠진 표현 {len(missing)}개")
    for i in missing[:50]:
        print(f"  빠짐: #{i} {index[i]['plain']}")


if __name__ == "__main__":
    main(sys.argv[1:])
