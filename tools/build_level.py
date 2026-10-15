"""tools/content/<level>.py 원고를 검증하고 data/<level>.json 으로 만든다.

사용법: python3 tools/build_level.py n5
"""
import importlib.util
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RUBY = re.compile(r"\{([^{}|]+)\|([^{}|]+)\}")
KANJI = re.compile(r"[一-鿿々]")


def strip_ruby(s):
    return RUBY.sub(lambda m: m.group(1), s)


def load_rows(level):
    path = ROOT / "tools" / "content" / f"{level}.py"
    spec = importlib.util.spec_from_file_location(level, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    rows = []
    for line in mod.ROWS.strip().splitlines():
        parts = line.split("|")
        # 루비 안의 | 때문에 split이 깨지므로 루비를 임시 치환 후 다시 나눈다
        masked = RUBY.sub(lambda m: "{" + m.group(1) + "\x00" + m.group(2) + "}", line)
        parts = [p.replace("\x00", "|") for p in masked.split("|")]
        if len(parts) != 8:
            raise SystemExit(f"필드 수 오류 ({len(parts)}): {line}")
        rows.append(parts)
    return mod.LEVEL, rows


def validate_sentence(no, sentence, highlights):
    errors = []
    if sentence.count("{") != sentence.count("}"):
        errors.append("괄호 짝 안 맞음")
    outside = RUBY.sub("", sentence)
    if KANJI.search(outside):
        errors.append(f"루비 없는 한자: {''.join(KANJI.findall(outside))}")
    for m in RUBY.finditer(sentence):
        if KANJI.search(m.group(2)) or not KANJI.search(m.group(1)):
            errors.append(f"루비 형식 이상: {m.group(0)}")
    plain = strip_ruby(sentence)
    pos = 0
    for h in highlights:
        i = plain.find(h, pos)
        if i < 0:
            errors.append(f"강조 '{h}' 를 찾을 수 없음")
            break
        pos = i + len(h)
    return [f"#{no}: {e}" for e in errors]


def main(level):
    book = {e["no"]: e for e in json.loads((ROOT / "data/source/book_index.json").read_text())}
    level_name, rows = load_rows(level)
    errors, cards, seen = [], [], set()
    for no, category, meaning, connection, sentence, translation, hl, reading in rows:
        no = int(no)
        entry = book.get(no)
        if entry is None:
            errors.append(f"#{no}: 책 목록에 없는 번호")
            continue
        if entry["level"] != level_name:
            errors.append(f"#{no}: 책 급수 {entry['level']} ≠ {level_name}")
        if no in seen:
            errors.append(f"#{no}: 중복")
        seen.add(no)
        highlights = [h for h in hl.split(";") if h]
        errors += validate_sentence(no, sentence, highlights)
        cards.append({
            "no": no,
            "expression": entry["expression"],
            "reading": reading or None,
            "category": category,
            "meaning_ko": meaning,
            "connection": connection,
            "example": {
                "sentence_ja": sentence,
                "translation_ko": translation,
                "highlights": highlights,
            },
        })
    if errors:
        print("\n".join(errors))
        raise SystemExit(1)

    skipped = [e for e in book.values() if e["level"] == level_name and e["no"] not in seen]
    out = {"version": 1, "level": level_name, "grammar": sorted(cards, key=lambda c: c["no"])}
    (ROOT / "data" / f"{level}.json").write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n")
    print(f"{level_name}: 카드 {len(cards)}개 작성")
    for e in skipped:
        print(f"  제외: #{e['no']} {e['expression']} ({e['book_chapter']}, p.{e['book_page']})")


if __name__ == "__main__":
    main(sys.argv[1])
