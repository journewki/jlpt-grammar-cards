"""SessionBuilder 알고리즘(ios/StudySession.swift) 시뮬레이션.
가상 학습자가 카드를 70% 확률로 '알고 있음' 누른다고 가정하고 사이클을 반복한다."""
import random

def build(grammar, progress, size, ratio, rng):
    st = lambda n: progress.get(n, {}).get("status", "new")
    key = lambda n: (progress.get(n, {}).get("last", -1), -progress.get(n, {}).get("uc", 0), n)
    unknown = sorted([g for g in grammar if st(g) == "unknown"], key=key)
    fresh = sorted([g for g in grammar if st(g) == "new"])
    known = sorted([g for g in grammar if st(g) == "known"], key=key)
    picked = []
    def take(pool, n):
        k = min(max(n, 0), len(pool)); picked.extend(pool[:k]); del pool[:k]
    take(unknown, round(size * ratio))
    take(fresh, size - len(picked))
    take(unknown, size - len(picked))
    take(known, size - len(picked))
    rng.shuffle(picked)
    return picked

def main():
    rng = random.Random(0)
    grammar = list(range(1, 61))          # 한 급수에 문법 60개
    progress, t = {}, 0
    for cycle in range(1, 9):
        cards = build(grammar, progress, 20, 0.4, rng)
        assert len(cards) == len(set(cards)) == min(20, len(grammar))
        kinds = [progress.get(n, {}).get("status", "new") for n in cards]
        for n in cards:
            t += 1
            p = progress.setdefault(n, {"uc": 0})
            p["last"] = t
            if rng.random() < 0.7: p["status"] = "known"
            else: p["status"] = "unknown"; p["uc"] += 1
        c = {s: sum(1 for p in progress.values() if p["status"] == s) for s in ("known", "unknown")}
        print(f"사이클 {cycle}: 새 {kinds.count('new'):2d} / 모름복습 {kinds.count('unknown'):2d} / 아는카드 {kinds.count('known'):2d}"
              f"  → 누적 알고있음 {c['known']:2d}, 모름 {c['unknown']:2d}, 안본카드 {60-len(progress):2d}")

if __name__ == "__main__":
    main()
