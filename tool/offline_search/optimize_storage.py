#!/usr/bin/env python3
"""Optimize an existing index losslessly, without reembedding or loading sources.

The baseline must be an independently retained copy of the current database.
Staging and rollback files stay outside bundled assets. Without --apply this
only writes a validated candidate database, manifest, and evidence report.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import sqlite3
import time
from itertools import zip_longest
from pathlib import Path

from storage import PACKED_VECTOR_SCHEMA, VECTOR_BLOCK_SIZE, VECTOR_STORAGE, PackedVectorWriter, iter_vectors


KEYWORD_MATCHES = [
    '"mercy"*', '"merciful"*', '"future"* OR "worried"*',
    '"difficult"* OR "life"*', '"prayer"*', '"patience"*',
    '"compassion"* OR "forgiveness"*', '"house"* OR "leaving"*',
    '"allah"*', '"dua"*', '"fasting"*', '"bukhari"*',
    '"2" OR "255"*', '"الله"*', '"رحمه"*', '"الصلاه"*',
    '"صبر"* OR "ايمان"*', '"مستقبل"*', '"مجھے"* OR "فکر"*',
    '"اميد"*', '"mustaqbil"* OR "fikar"*', '"mercy forgiveness"',
    'body:"merciful"*', 'reference:"bukhari"*',
]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def compare_rows(left, right, name: str) -> int:
    sentinel = object()
    count = 0
    for count, (before, after) in enumerate(zip_longest(left, right, fillvalue=sentinel), 1):
        if before != after:
            raise ValueError(f"Lossless validation failed for {name} at row {count}")
    return count


def vocabulary_digest(connection: sqlite3.Connection) -> tuple[str, int]:
    # Instance vocabulary records every token's row, column, and position.
    # Temporary vocabulary tables do not alter the read-only source database.
    connection.execute("CREATE VIRTUAL TABLE temp.validation_vocab USING fts5vocab(main, passages_fts, instance)")
    digest = hashlib.sha256()
    count = 0
    for row in connection.execute("SELECT term,doc,col,offset FROM temp.validation_vocab ORDER BY term,doc,col,offset"):
        digest.update(json.dumps(row, ensure_ascii=False, separators=(",", ":")).encode("utf-8"))
        digest.update(b"\n")
        count += 1
    connection.execute("DROP TABLE temp.validation_vocab")
    return digest.hexdigest(), count


def validate(source: sqlite3.Connection, target: sqlite3.Connection) -> dict:
    if target.execute("PRAGMA integrity_check").fetchone()[0] != "ok":
        raise ValueError("Optimized database failed SQLite integrity validation")
    if target.execute("PRAGMA foreign_key_check").fetchall():
        raise ValueError("Optimized database contains missing references")
    target.execute("INSERT INTO passages_fts(passages_fts) VALUES('integrity-check')")
    target.commit()
    counts = {}
    for table, ordering in (("passages", "id"), ("reference_aliases", "alias,passage_id")):
        counts[table] = compare_rows(source.execute(f"SELECT * FROM {table} ORDER BY {ordering}"),
                                    target.execute(f"SELECT * FROM {table} ORDER BY {ordering}"), table)
    expected_metadata = dict(source.execute("SELECT key,value FROM metadata"))
    expected_metadata.update(schema_version="2", vector_storage=VECTOR_STORAGE,
                             vector_block_size=str(VECTOR_BLOCK_SIZE))
    if dict(target.execute("SELECT key,value FROM metadata")) != expected_metadata:
        raise ValueError("Optimized database changed model, tokenizer, corpus, or scoring metadata")
    counts["vectors"] = compare_rows(iter_vectors(source), iter_vectors(target), "vector IDs, metadata and all float32 bytes")
    if counts["vectors"] != int(expected_metadata["vector_count"]):
        raise ValueError("Vector count disagrees with corpus metadata")
    counts["fts_rows"] = compare_rows(source.execute("SELECT rowid FROM passages_fts ORDER BY rowid"),
                                     target.execute("SELECT rowid FROM passages_fts ORDER BY rowid"), "keyword row IDs")
    if counts["fts_rows"] != counts["passages"]:
        raise ValueError("Keyword index does not cover every passage")
    for table, ordering in (("passages_fts_docsize", "id"), ("passages_fts_config", "k")):
        counts[table] = compare_rows(source.execute(f"SELECT * FROM {table} ORDER BY {ordering}"),
                                    target.execute(f"SELECT * FROM {table} ORDER BY {ordering}"), table)
    compare_rows(source.execute("SELECT id,block FROM passages_fts_data WHERE id=1"),
                 target.execute("SELECT id,block FROM passages_fts_data WHERE id=1"), "keyword corpus token counts")
    before_vocabulary = vocabulary_digest(source)
    after_vocabulary = vocabulary_digest(target)
    if before_vocabulary != after_vocabulary:
        raise ValueError("Keyword tokens, document IDs, columns or positions changed")
    keyword_rankings = []
    for match in KEYWORD_MATCHES:
        query = ("SELECT p.canonical_id,bm25(passages_fts) FROM passages_fts "
                 "JOIN passages p ON p.id=passages_fts.rowid WHERE passages_fts MATCH ? "
                 "ORDER BY bm25(passages_fts),p.id")
        count = compare_rows(source.execute(query, (match,)), target.execute(query, (match,)), f"keyword rankings for {match}")
        keyword_rankings.append({"match": match, "identical_ranked_results": count})
    return {"counts": counts, "float32_vectors_identical": True,
            "passages_and_aliases_identical": True, "model_and_corpus_metadata_identical": True,
            "fts_token_instances": before_vocabulary[1], "fts_token_instances_sha256": before_vocabulary[0],
            "fts_token_positions_identical": True, "fts_docsize_config_and_corpus_counts_identical": True,
            "keyword_rankings_and_bm25_identical": keyword_rankings}


def optimize(args) -> dict:
    start = time.perf_counter()
    assets = args.assets.resolve()
    database = assets / "search.sqlite"
    manifest_path = assets / "manifest.json"
    baseline = args.baseline.resolve()
    output = args.output.resolve()
    if output == assets or output.is_relative_to(assets):
        raise ValueError("Staging files must remain outside bundled assets")
    if not baseline.is_file() or baseline == database:
        raise ValueError("A separate retained baseline database is required")
    source_hash = sha256(database)
    if sha256(baseline) != source_hash:
        raise ValueError("Current database changed after the retained baseline was captured")
    original_manifest_bytes = manifest_path.read_bytes()
    manifest = json.loads(original_manifest_bytes)
    if manifest["artifacts"][database.name]["sha256"] != source_hash:
        raise ValueError("Current database and manifest hashes disagree")
    output.mkdir(parents=True, exist_ok=True)
    candidate = output / "search.sqlite"
    temporary = output / "search.sqlite.building"
    if candidate == baseline or temporary == baseline:
        raise ValueError("Candidate cannot overwrite the retained baseline")
    temporary.unlink(missing_ok=True)
    source = sqlite3.connect(f"file:{database}?mode=ro", uri=True)
    target = sqlite3.connect(temporary)
    try:
        source.execute("BEGIN")
        metadata = dict(source.execute("SELECT key,value FROM metadata"))
        if metadata.get("schema_version") != "1" or metadata.get("vector_encoding") != "float32_little_endian":
            raise ValueError("Converter requires the existing schema1 float32 index")
        for name in ("model", "tokenizer"):
            asset = assets / ("model.int8.onnx" if name == "model" else "tokenizer.json")
            if metadata[f"{name}_sha256"] != sha256(asset):
                raise ValueError(f"Current database and {name} identities disagree")
        target.execute("PRAGMA foreign_keys=ON")
        for table in ("metadata", "passages", "reference_aliases"):
            statement = source.execute("SELECT sql FROM sqlite_master WHERE type='table' AND name=?", (table,)).fetchone()
            if not statement:
                raise ValueError(f"Missing source table {table}")
            target.execute(statement[0])
        target.executescript(PACKED_VECTOR_SCHEMA)
        fts_schema = source.execute("SELECT sql FROM sqlite_master WHERE name='passages_fts'").fetchone()[0]
        if re.search(r"\bcontent\s*=", fts_schema, re.IGNORECASE):
            raise ValueError("Existing keyword index already has a content storage override")
        fts_schema, replacements = re.subn(r"\bfts5\s*\(", "fts5(content='', ", fts_schema, count=1, flags=re.IGNORECASE)
        if replacements != 1:
            raise ValueError("Unrecognized source keyword index schema")
        target.execute(fts_schema)
        for statement, in source.execute("SELECT sql FROM sqlite_master WHERE type='index' AND tbl_name IN ('passages','reference_aliases') AND sql IS NOT NULL"):
            target.execute(statement)
        for table in ("metadata", "passages", "reference_aliases"):
            columns = len(source.execute(f"PRAGMA table_info({table})").fetchall())
            placeholders = ",".join("?" for _ in range(columns))
            target.executemany(f"INSERT INTO {table} VALUES({placeholders})", source.execute(f"SELECT * FROM {table}"))
        target.executemany("INSERT OR REPLACE INTO metadata VALUES(?,?)", {
            "schema_version": "2", "vector_storage": VECTOR_STORAGE,
            "vector_block_size": str(VECTOR_BLOCK_SIZE),
        }.items())
        target.executemany("INSERT INTO passages_fts(rowid,body,reference) VALUES(?,?,?)",
                           source.execute("SELECT rowid,body,reference FROM passages_fts ORDER BY rowid"))
        writer = PackedVectorWriter(target)
        for vector_id, passage_id, language, chunk_index, embedding in iter_vectors(source):
            writer.append(passage_id, language, chunk_index, embedding, vector_id=vector_id)
        writer.flush()
        target.execute("INSERT INTO passages_fts(passages_fts) VALUES('optimize')")
        target.commit()
        target.execute("PRAGMA optimize")
        target.execute("VACUUM")
        print("Packed float32 vectors and rebuilt contentless keyword index; validating exact preservation", flush=True)
        report = validate(source, target)
        target.close()
        source.close()
        if sha256(database) != source_hash or manifest_path.read_bytes() != original_manifest_bytes:
            raise ValueError("Current assets changed during conversion; candidate was not applied")
        os.replace(temporary, candidate)
    except BaseException:
        source.close()
        target.close()
        temporary.unlink(missing_ok=True)
        raise
    manifest.update(schema_version=2, vector_storage=VECTOR_STORAGE, vector_block_size=VECTOR_BLOCK_SIZE)
    manifest["artifacts"][database.name] = {"sha256": sha256(candidate), "bytes": candidate.stat().st_size}
    staged_manifest = output / "manifest.json"
    staged_manifest.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    report.update({"source_sha256": source_hash, "optimized_sha256": manifest["artifacts"][database.name]["sha256"],
                   "source_bytes": database.stat().st_size, "optimized_bytes": candidate.stat().st_size,
                   "saved_bytes": database.stat().st_size - candidate.stat().st_size,
                   "vector_storage": VECTOR_STORAGE, "vector_block_size": VECTOR_BLOCK_SIZE,
                   "conversion_seconds": round(time.perf_counter() - start, 3), "applied": False})
    if args.apply:
        if output.stat().st_dev != assets.stat().st_dev:
            raise ValueError("Staging and assets must share a filesystem for atomic replacement")
        if sha256(database) != source_hash or manifest_path.read_bytes() != original_manifest_bytes:
            raise ValueError("Current assets changed before application; candidate was not applied")
        rollback = output / "rollback"
        rollback.mkdir(exist_ok=True)
        shutil.copy2(database, rollback / database.name)
        (rollback / manifest_path.name).write_bytes(original_manifest_bytes)
        # Retain the candidate and complete rollback outside assets. Only the two
        # committed final files enter Flutter's bundled asset directory.
        install_database = output / "search.sqlite.installing"
        install_manifest = output / "manifest.json.installing"
        shutil.copy2(candidate, install_database)
        shutil.copy2(staged_manifest, install_manifest)
        try:
            os.replace(install_database, database)
            os.replace(install_manifest, manifest_path)
        except BaseException:
            shutil.copy2(rollback / database.name, install_database)
            shutil.copy2(rollback / manifest_path.name, install_manifest)
            os.replace(install_database, database)
            os.replace(install_manifest, manifest_path)
            raise
        report["applied"] = True
        report["rollback_directory"] = str(rollback)
    (output / "validation.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2), flush=True)
    return report


def main() -> None:
    project = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--assets", type=Path, default=project / "assets/offline_search")
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=project / ".dart_tool/offline_search/size-optimized")
    parser.add_argument("--apply", action="store_true")
    optimize(parser.parse_args())


if __name__ == "__main__":
    main()
