#!/usr/bin/env python3
"""Evaluate actual local retrieval with human-verified relevance judgments.

Example qrels JSON:
 {"verified_by":"reviewer name", "queries":[
   {"id":"unique-id","text":"query","language":"en",
    "relevance":{"existing canonical ID":2}}
 ]}
Relevance grades are nonnegative integers. This tool never creates judgments.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sqlite3
import statistics
import time
from pathlib import Path

import numpy as np

from build_index import E5Encoder
from corpus import normalize_keyword, normalize_reference, sha256
from storage import iter_vectors


STOPWORDS = {"i", "a", "an", "am", "is", "are", "the", "about", "my", "me", "of", "to", "and", "in", "on", "for", "how", "what", "do", "does", "can", "with", "it", "be", "this", "that"}


def metrics(ranking: list[str], relevance: dict[str, int], k: int = 10) -> dict[str, float]:
    relevant = {key for key, value in relevance.items() if value > 0}
    if not relevant:
        raise ValueError("Every evaluated query needs at least one verified relevant source")
    ranking = list(dict.fromkeys(ranking))[:k]
    hits = [index for index, key in enumerate(ranking, 1) if key in relevant]
    dcg = sum((2 ** relevance.get(key, 0) - 1) / math.log2(index + 1) for index, key in enumerate(ranking, 1))
    ideal = sorted(relevance.values(), reverse=True)[:k]
    idcg = sum((2 ** grade - 1) / math.log2(index + 1) for index, grade in enumerate(ideal, 1))
    return {f"recall@{k}": len(hits) / len(relevant), f"precision@{k}": len(hits) / k,
            f"mrr@{k}": 1 / hits[0] if hits else 0.0, f"ndcg@{k}": dcg / idcg if idcg else 0.0}


def rrf(keyword: list[str], semantic: list[str], constant: int = 60) -> list[str]:
    scores = {}
    for ranking in (keyword, semantic):
        for rank, key in enumerate(dict.fromkeys(ranking), 1):
            scores[key] = scores.get(key, 0.0) + 1 / (constant + rank)
    return sorted(scores, key=lambda key: (-scores[key], key))


class LocalSearch:
    def __init__(self, assets: Path, threads: int = 4):
        self.connection = sqlite3.connect(f"file:{assets / 'search.sqlite'}?mode=ro", uri=True)
        metadata = dict(self.connection.execute("SELECT key,value FROM metadata"))
        for name in ("model", "tokenizer"):
            path = assets / ("model.int8.onnx" if name == "model" else "tokenizer.json")
            if metadata[f"{name}_sha256"] != sha256(path):
                raise ValueError(f"Database/{name} version mismatch")
        self.encoder = E5Encoder(assets / "model.int8.onnx", assets / "tokenizer.json", threads=threads)
        canonical_ids = dict(self.connection.execute("SELECT id,canonical_id FROM passages"))
        rows = list(iter_vectors(self.connection))
        self.vector_ids = [canonical_ids[row[1]] for row in rows]
        self.vectors = np.stack([np.frombuffer(row[4], dtype="<f4") for row in rows])
        if not np.all(np.isfinite(self.vectors)) or not np.allclose(np.linalg.norm(self.vectors, axis=1), 1, atol=1e-4):
            raise ValueError("Database contains corrupt or non-normalized vectors")
        self.ids = {row[0] for row in self.connection.execute("SELECT canonical_id FROM passages")}
        self.hadith_reference_prefixes = set()
        for canonical_id, title in self.connection.execute("SELECT canonical_id,title FROM passages WHERE kind='hadith'"):
            slug = canonical_id.split(":", 2)[1]
            self.hadith_reference_prefixes.update((normalize_reference(title), slug, f"hadith {slug}"))

    def exact(self, query: str) -> list[str] | None:
        alias = normalize_reference(query)
        rows = self.connection.execute("SELECT p.canonical_id FROM reference_aliases a JOIN passages p ON p.id=a.passage_id WHERE a.alias=? ORDER BY p.id", (alias,)).fetchall()
        if rows:
            return [row[0] for row in rows]
        if re.fullmatch(r"(?:quran[: ]\s*)?\d{1,3}\s*:\s*\d{1,3}", alias) or alias.startswith("hadith:"):
            return []
        if any(re.fullmatch(re.escape(prefix) + r"(?:\s+|:)\d+(?:\.\d+)?", alias)
               for prefix in self.hadith_reference_prefixes):
            return []
        return None

    def keyword(self, query: str, limit: int = 80) -> list[str]:
        tokens = [token for token in dict.fromkeys(normalize_keyword(query).split()) if len(token) >= 2 and token not in STOPWORDS]
        if not tokens:
            return []
        match = " OR ".join('"' + token.replace('"', '""') + '"' + ("*" if len(token) >= 3 else "") for token in tokens)
        return [row[0] for row in self.connection.execute("SELECT p.canonical_id FROM passages_fts JOIN passages p ON p.id=passages_fts.rowid WHERE passages_fts MATCH ? ORDER BY bm25(passages_fts),p.id LIMIT ?", (match, limit))]

    def semantic(self, query: str, limit: int = 80) -> tuple[list[str], float, float]:
        start = time.perf_counter()
        vector = self.encoder.query(query)
        embedding_ms = (time.perf_counter() - start) * 1000
        start = time.perf_counter()
        similarities = np.einsum("ij,j->i", self.vectors, vector, optimize=False)
        best = {}
        for key, score in zip(self.vector_ids, similarities):
            best[key] = max(float(score), best.get(key, -math.inf))
        ranking = sorted(best, key=lambda key: (-best[key], key))[:limit]
        return ranking, embedding_ms, (time.perf_counter() - start) * 1000

    def search(self, query: str, limit: int = 80) -> tuple[dict[str, list[str]], dict[str, float]]:
        start = time.perf_counter()
        exact = self.exact(query)
        if exact is not None:
            return {"keyword": exact, "semantic": exact, "hybrid": exact}, {"exact_ms": (time.perf_counter() - start) * 1000}
        keyword = self.keyword(query, limit)
        keyword_ms = (time.perf_counter() - start) * 1000
        semantic, embedding_ms, vector_ms = self.semantic(query, limit)
        return {"keyword": keyword, "semantic": semantic, "hybrid": rrf(keyword, semantic)}, {
            "keyword_ms": keyword_ms, "embedding_ms": embedding_ms, "vector_ms": vector_ms,
            "total_ms": (time.perf_counter() - start) * 1000,
        }


def percentile(values: list[float], quantile: float) -> float:
    if not values:
        return 0.0
    values = sorted(values)
    return values[math.ceil(quantile * len(values)) - 1]


def evaluate(args) -> dict:
    data = json.loads(args.qrels.read_text(encoding="utf-8"))
    if not isinstance(data.get("verified_by"), str) or not data["verified_by"].strip():
        raise ValueError("qrels must identify the human/source reviewer in verified_by")
    queries = data.get("queries", [])
    if not queries:
        raise ValueError("qrels must contain reviewed queries")
    search = LocalSearch(args.assets, args.threads)
    results = []
    seen = set()
    for query in queries:
        if query["id"] in seen:
            raise ValueError("Duplicate evaluation query ID")
        seen.add(query["id"])
        if not isinstance(query["text"], str) or not query["text"].strip() or not query.get("language"):
            raise ValueError("Evaluation queries require nonempty text and language")
        relevance = query["relevance"]
        if not relevance or any(type(value) is not int or value < 0 for value in relevance.values()):
            raise ValueError("Relevance grades must be nonnegative integers")
        missing = set(relevance) - search.ids
        if missing:
            raise ValueError(f"Reviewed sources outside the indexed corpus: {sorted(missing)}")
        rankings, timing = search.search(query["text"], args.candidates)
        results.append({"id": query["id"], "text": query["text"], "language": query["language"],
                        "rankings": {method: ranking[:10] for method, ranking in rankings.items()},
                        "metrics": {method: metrics(ranking, relevance) for method, ranking in rankings.items()},
                        "timing_ms": timing})
    aggregate = {}
    for language in ["all", *sorted({row["language"] for row in results})]:
        subset = [row for row in results if language == "all" or row["language"] == language]
        aggregate[language] = {method: {name: statistics.mean(row["metrics"][method][name] for row in subset)
                                      for name in ("recall@10", "precision@10", "mrr@10", "ndcg@10")}
                               for method in ("keyword", "semantic", "hybrid")}
    return {"verified_by": data["verified_by"], "qrels_sha256": sha256(args.qrels),
            "queries": results, "aggregate": aggregate,
            "limitations": "Host CPU measurements only. Actual Android/iOS latency and memory require physical-device benchmarks. Unjudged results receive zero relevance; review the candidate pool before interpreting precision."}


def main():
    project = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--assets", type=Path, default=project / "assets/offline_search")
    parser.add_argument("--qrels", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--threads", type=int, default=4)
    parser.add_argument("--candidates", type=int, default=80)
    args = parser.parse_args()
    if args.candidates < 10:
        parser.error("At least ten retrieval candidates are required")
    report = evaluate(args)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report["aggregate"], indent=2))


if __name__ == "__main__":
    main()
