"""data/<level>.json → review/<level>.md 검수표 생성. 사용법: python3 tools/review_table.py n5"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RUBY = re.compile(r"\{([^{}|]+)\|([^{}|]+)\}")


def main(level):
    deck = json.loads((ROOT / "data" / f"{level}.json").read_text())
    book = {e["no"]: e for e in json.loads((ROOT / "data/source/book_index.json").read_text())}
    lines = [
        f"# {deck['level']} 카드 검수표 ({len(deck['grammar'])}개)\n",
        "표현·급수는 책 그대로, 뜻·접속·예문은 새로 작성. 강조 부분은 **굵게**. "
        "급수에 *가 붙은 것은 책에 급수 표시가 없어 지정한 항목.\n",
        "| # | 책 쪽 | 분류 | 표현 | 뜻 | 접속 | 예문 | 해석 |",
        "|---|---|---|---|---|---|---|---|",
    ]
    for g in deck["grammar"]:
        s, pos = RUBY.sub(lambda m: m.group(1), g["example"]["sentence_ja"]), 0
        for h in g["example"]["highlights"]:
            i = s.find(h, pos)
            s = s[:i] + f"**{h}**" + s[i + len(h):]
            pos = i + len(h) + 4
        b = book[g["no"]]
        expr = g["expression"] + (f" ({g['reading']})" if g["reading"] else "") + ("*" if b.get("level_assigned") else "")
        lines.append(f"| {g['no']} | {b['book_page']} | {g['category']} | {expr} | {g['meaning_ko']} | "
                     f"{g['connection']} | {s} | {g['example']['translation_ko']} |")
    (ROOT / "review" / f"{level}.md").write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main(sys.argv[1])
