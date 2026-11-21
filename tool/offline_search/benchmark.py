#!/usr/bin/env python3
"""Measure host-only retrieval latency and report actual retrieved source IDs.

These smoke queries are not relevance judgments. Retrieval quality is evaluated
separately using evaluate.py with a reviewed qrels file.
"""

import argparse
import json
import platform
import resource
import statistics
import time
from pathlib import Path

from corpus import sha256
from evaluate import LocalSearch, percentile


QUERIES = [
    ("en", "I'm worried about my future."),
    ("ur", "مجھے اپنے مستقبل کی فکر ہے"),
    ("ar", "أشعر بالقلق بشأن مستقبلي"),
    ("roman_ur", "Mujhe apne mustaqbil ki fikar hai"),
    ("en", "What helps when life is difficult?"),
    ("en", "Dua when leaving the house"),
    ("en", "Names of Allah about compassion and mercy"),
    ("exact", "2:255"),
    ("exact", "Sahih al-Bukhari 1"),
]


def benchmark(args) -> dict:
    start = time.perf_counter()
    search = LocalSearch(args.assets, args.threads)
    initialize_ms = (time.perf_counter() - start) * 1000
    search.search(QUERIES[0][1], args.candidates)
    results = []
    for language, query in QUERIES:
        timings = []
        ranking = None
        for _ in range(args.repeats):
            ranking, timing = search.search(query, args.candidates)
            timings.append(timing)
        measures = {name: {"median": statistics.median(row.get(name, 0) for row in timings),
                           "p95": percentile([row.get(name, 0) for row in timings], .95)}
                    for name in timings[0]}
        results.append({"language": language, "query": query, "timing_ms": measures,
                        "keyword_ids": ranking["keyword"][:10], "semantic_ids": ranking["semantic"][:10],
                        "hybrid_ids": ranking["hybrid"][:10]})
    max_rss = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    if platform.system() != "Darwin":
        max_rss *= 1024
    return {"environment": {"platform": platform.platform(), "machine": platform.machine(),
                            "python": platform.python_version(), "threads": args.threads,
                            "repeats": args.repeats, "candidates": args.candidates},
            "model_sha256": sha256(args.assets / "model.int8.onnx"),
            "database_sha256": sha256(args.assets / "search.sqlite"),
            "initialize_ms": initialize_ms, "process_peak_rss_bytes": max_rss,
            "corpus_counts": dict(search.connection.execute("SELECT kind,count(*) FROM passages GROUP BY kind")),
            "vectors": len(search.vector_ids), "queries": results,
            "limitations": "Development-host CPU measurements, not representative phone measurements. Python vector loading and NumPy retrieval differ from Flutter. Retrieved IDs are smoke evidence, not verified relevance judgments. No Recall/Precision/MRR/nDCG claims are made."}


def main():
    project = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--assets", type=Path, default=project / "assets/offline_search")
    parser.add_argument("--output", type=Path, default=project / "docs/offline_search_host_benchmark.json")
    parser.add_argument("--threads", type=int, default=4)
    parser.add_argument("--repeats", type=int, default=5)
    parser.add_argument("--candidates", type=int, default=80)
    args = parser.parse_args()
    if args.repeats < 1:
        parser.error("Repeats must be positive")
    report = benchmark(args)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"initialize_ms": report["initialize_ms"], "process_peak_rss_bytes": report["process_peak_rss_bytes"],
                      "queries": [{"language": row["language"], "timing_ms": row["timing_ms"]} for row in report["queries"]]}, indent=2))


if __name__ == "__main__":
    main()
