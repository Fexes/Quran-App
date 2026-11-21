"""Derive a compact keyword package without modifying the semantic originals."""

from __future__ import annotations

import argparse
import hashlib
import json
import sqlite3
from pathlib import Path


SEMANTIC_METADATA = {
    "model_id", "model_revision", "model_sha256", "tokenizer_sha256",
    "dimensions", "max_length", "pooling", "document_prefix", "query_prefix",
    "chunk_overlap", "vector_encoding", "vector_count", "vector_storage",
    "vector_block_size",
}
KEYWORD_TABLES = ("passages", "passages_fts", "reference_aliases")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def counts(connection: sqlite3.Connection) -> dict[str, int]:
    return {
        table: connection.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        for table in KEYWORD_TABLES
    }


def build(source: Path, output: Path) -> dict:
    source, output = source.resolve(), output.resolve()
    if source == output:
        raise ValueError("Keep the source semantic package separate from the output.")
    source_manifest = json.loads((source / "manifest.json").read_text())
    if source_manifest["schema_version"] not in (1, 2):
        raise ValueError("Expected an original schema-1 or schema-2 semantic package.")
    source_database = source / "search.sqlite"
    expected = source_manifest["artifacts"]["search.sqlite"]
    source_hash = sha256(source_database)
    if (source_database.stat().st_size != expected["bytes"]
            or source_hash != expected["sha256"]):
        raise ValueError("The source database does not match its manifest.")

    output.mkdir(parents=True, exist_ok=True)
    temporary = output / ".search.sqlite.building"
    manifest_temporary = output / ".manifest.json.building"
    # Only the two final filenames are declared in Flutter's asset manifest.
    temporary.unlink(missing_ok=True)
    manifest_temporary.unlink(missing_ok=True)
    original = sqlite3.connect(source_database.as_uri() + "?mode=ro&immutable=1", uri=True)
    candidate = sqlite3.connect(temporary)
    try:
        before = counts(original)
        original.backup(candidate)
        objects = dict(candidate.execute(
            "SELECT name,type FROM sqlite_master WHERE name IN "
            "('vectors','vector_entries','vector_blocks')"
        ))
        if objects.get("vectors") == "view":
            candidate.execute("DROP VIEW vectors")
        for name in ("vectors", "vector_entries", "vector_blocks"):
            if objects.get(name) == "table":
                candidate.execute(f"DROP TABLE {name}")
        candidate.executemany(
            "DELETE FROM metadata WHERE key=?",
            [(key,) for key in sorted(SEMANTIC_METADATA)],
        )
        candidate.executemany(
            "INSERT OR REPLACE INTO metadata(key,value) VALUES (?,?)",
            [("schema_version", "3"), ("retrieval_mode", "keyword"),
             ("normalization_version", "1")],
        )
        candidate.commit()
        candidate.execute("VACUUM")
        after = counts(candidate)
        if before != after:
            raise ValueError(f"Keyword row counts changed: {before} -> {after}")
        if list(candidate.execute("PRAGMA integrity_check")) != [("ok",)]:
            raise ValueError("Keyword database integrity check failed.")
        if list(candidate.execute("PRAGMA foreign_key_check")):
            raise ValueError("Keyword database contains broken references.")
        vector_objects = list(candidate.execute(
            "SELECT name FROM sqlite_master WHERE name GLOB 'vector*'"
        ))
        if vector_objects:
            raise ValueError(f"Unexpected remaining vector objects: {vector_objects}")
    except Exception:
        candidate.close()
        original.close()
        temporary.unlink(missing_ok=True)
        raise
    else:
        candidate.close()
        original.close()

    corpus = dict(source_manifest["corpus"])
    corpus.pop("vector_count", None)
    manifest = {
        "retrieval_mode": "keyword",
        "schema_version": 3,
        "normalization_version": 1,
        "corpus": corpus,
        "artifacts": {
            "search.sqlite": {
                "sha256": sha256(temporary),
                "bytes": temporary.stat().st_size,
            },
        },
    }
    for key in ("source_policy", "translation_coverage"):
        if key in source_manifest:
            manifest[key] = source_manifest[key]
    manifest_temporary.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
    temporary.replace(output / "search.sqlite")
    manifest_temporary.replace(output / "manifest.json")
    original_bytes = sum(path.stat().st_size for path in source.iterdir() if path.is_file())
    keyword_bytes = sum((output / name).stat().st_size for name in ("manifest.json", "search.sqlite"))
    return {
        "source_database_sha256": source_hash,
        "counts_before": before,
        "counts_after": after,
        "integrity_check": "ok",
        "foreign_key_check": "ok",
        "remaining_vector_objects": 0,
        "original_asset_bytes": original_bytes,
        "keyword_asset_bytes": keyword_bytes,
        "asset_bytes_saved": original_bytes - keyword_bytes,
        "database_sha256": manifest["artifacts"]["search.sqlite"]["sha256"],
    }


def main() -> None:
    project = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=project / "assets/offline_search")
    parser.add_argument("--output", type=Path, default=project / "assets/keyword_search")
    args = parser.parse_args()
    print(json.dumps(build(args.source, args.output), indent=2))


if __name__ == "__main__":
    main()
