#!/usr/bin/env python3
"""Build the shipped FTS5/vector database with the same pinned E5 as Flutter.

Install requirements.txt in a Python 3.10+ virtual environment. All artifacts
must already be local; inference and corpus extraction make no network requests.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sqlite3
import time
from pathlib import Path

import numpy as np
import onnxruntime as ort
from tokenizers import Tokenizer

from corpus import load_corpus, normalize_keyword, normalize_reference, semantic_text, sha256
from storage import PACKED_VECTOR_SCHEMA, VECTOR_BLOCK_SIZE, VECTOR_STORAGE, PackedVectorWriter, iter_vectors


MODEL_ID = "intfloat/multilingual-e5-small"
MODEL_REVISION = "614241f622f53c4eeff9890bdc4f31cfecc418b3"
DIMENSIONS = 384
MAX_LENGTH = 512

SCHEMA = """
PRAGMA foreign_keys=ON;
CREATE TABLE metadata(key TEXT PRIMARY KEY, value TEXT NOT NULL);
CREATE TABLE passages(
 id INTEGER PRIMARY KEY, canonical_id TEXT UNIQUE NOT NULL,
 kind TEXT NOT NULL,
 reference TEXT NOT NULL, title TEXT NOT NULL, arabic TEXT NOT NULL,
 translations_json TEXT NOT NULL, grades_json TEXT NOT NULL,
 surah_number INTEGER, ayah_number INTEGER, item_id TEXT,
 body TEXT, route TEXT, language TEXT, source_label TEXT,
 is_user_content INTEGER NOT NULL DEFAULT 0, metadata_json TEXT NOT NULL DEFAULT '{}'
);
CREATE INDEX passages_kind ON passages(kind);
CREATE VIRTUAL TABLE passages_fts USING fts5(
 body, reference, content='', tokenize='unicode61 remove_diacritics 2', prefix='2 3 4'
);
CREATE TABLE reference_aliases(
 alias TEXT NOT NULL, passage_id INTEGER NOT NULL REFERENCES passages(id),
 PRIMARY KEY(alias,passage_id)
);
"""
SCHEMA += PACKED_VECTOR_SCHEMA


class E5Encoder:
    def __init__(self, model: Path, tokenizer: Path, max_length: int = MAX_LENGTH,
                 threads: int = 4, overlap: int = 64):
        self.tokenizer = Tokenizer.from_file(str(tokenizer))
        self.tokenizer.no_padding()
        self.tokenizer.no_truncation()
        self.max_length = max_length
        self.overlap = overlap
        self.bos = self.tokenizer.token_to_id("<s>")
        self.eos = self.tokenizer.token_to_id("</s>")
        self.pad = self.tokenizer.token_to_id("<pad>")
        if (self.bos, self.pad, self.eos) != (0, 1, 2):
            raise ValueError("Expected pinned XLM-R special token IDs 0/1/2")
        options = ort.SessionOptions()
        options.intra_op_num_threads = threads
        options.inter_op_num_threads = 1
        options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
        self.session = ort.InferenceSession(str(model), sess_options=options, providers=["CPUExecutionProvider"])
        self.inputs = {item.name for item in self.session.get_inputs()}
        if not {"input_ids", "attention_mask"}.issubset(self.inputs):
            raise ValueError(f"Unsupported model input contract: {self.inputs}")
        if self.inputs - {"input_ids", "attention_mask", "token_type_ids"}:
            raise ValueError("Model requires unsupported inputs")
        self.output = self.session.get_outputs()[0].name

    def tokenize(self, text: str, kind: str = "query") -> list[int]:
        if kind not in {"query", "passage"}:
            raise ValueError("E5 kind must be query or passage")
        raw = self.tokenizer.encode(f"{kind}: {semantic_text(text)}", add_special_tokens=False).ids
        return [self.bos, *raw[:self.max_length - 2], self.eos]

    def chunks(self, text: str) -> list[list[int]]:
        prefix = self.tokenizer.encode("passage:", add_special_tokens=False).ids
        raw = self.tokenizer.encode(f"passage: {semantic_text(text)}", add_special_tokens=False).ids
        if raw[:len(prefix)] != prefix:
            raise ValueError("Pinned E5 passage prefix tokenization changed")
        body = raw[len(prefix):]
        capacity = self.max_length - len(prefix) - 2
        if not 0 <= self.overlap < capacity:
            raise ValueError("Chunk overlap must be smaller than the token window")
        result = []
        start = 0
        while True:
            result.append([self.bos, *prefix, *body[start:start + capacity], self.eos])
            if start + capacity >= len(body):
                return result
            start += capacity - self.overlap

    def encode_ids(self, batches: list[list[int]]) -> np.ndarray:
        if not batches:
            return np.empty((0, DIMENSIONS), dtype=np.float32)
        length = max(map(len, batches))
        ids = np.full((len(batches), length), self.pad, dtype=np.int64)
        mask = np.zeros_like(ids)
        for index, tokens in enumerate(batches):
            ids[index, :len(tokens)] = tokens
            mask[index, :len(tokens)] = 1
        inputs = {"input_ids": ids, "attention_mask": mask}
        if "token_type_ids" in self.inputs:
            inputs["token_type_ids"] = np.zeros_like(ids)
        output = np.asarray(self.session.run([self.output], inputs)[0], dtype=np.float32)
        if output.shape != (len(batches), length, DIMENSIONS):
            raise ValueError(f"Expected E5 token hidden states [batch,tokens,384], got {output.shape}")
        weights = mask.astype(np.float32)[..., None]
        pooled = np.sum(output * weights, axis=1) / np.sum(weights, axis=1)
        norms = np.linalg.norm(pooled, axis=1, keepdims=True)
        if not np.all(np.isfinite(pooled)) or np.any(norms <= 0):
            raise ValueError("Model emitted non-finite or zero embeddings")
        return np.asarray(pooled / norms, dtype="<f4")

    def query(self, text: str) -> np.ndarray:
        return self.encode_ids([self.tokenize(text)])[0]


def parity_cases(encoder: E5Encoder) -> dict:
    examples = [
        ("english", "query", "I'm worried about my future."),
        ("arabic", "query", "أشعر بالقلق بشأن مستقبلي"),
        ("urdu", "query", "مجھے اپنے مستقبل کی فکر ہے"),
        ("roman_urdu", "query", "Mujhe apne mustaqbil ki fikar hai"),
        ("diacritics", "passage", "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ"),
        ("special_tokens", "query", "<s> </s> <unk> <pad> <mask>"),
        ("unicode", "query", "cafe\u0301 ﬁ ＦＵＬＬ مرحباً 👨‍👩‍👦 🙂"),
        ("unknown", "query", "a\U00011ff0\U00011ff1b"),
        ("literal_metaspace", "query", "▁▁word▁"),
        ("normalized_specials", "query", "＜ｓ＞ ＜／ｓ＞ ＜ｕｎｋ＞"),
        ("combined_accents", "query", "a\u0301\u0327 e\u0301\u0308"),
        ("variation_selectors", "query", "❤\ufe0f ❤️ ☺\ufe0f 👩\u200d💻"),
        ("unicode_spaces", "query", "\u3000hello\u00a0world\u202f\u2009اردو\n\tالعربية\u0085"),
        ("controls_not_whitespace", "query", "\ufeffA\u001cB\u001fC\ufeff"),
        ("empty", "query", ""),
        ("long_query", "query", "future امید مستقبل " * 300),
        ("long_passage", "passage", "guidance صبر ایمان " * 300),
    ]
    return {"model_id": MODEL_ID, "model_revision": MODEL_REVISION,
            "max_length": encoder.max_length, "cases": [
                {"name": name, "input": text, "kind": kind, "input_ids": tokens,
                 "attention_mask": [1] * len(tokens), "token_type_ids": [0] * len(tokens)}
                for name, kind, text in examples
                for tokens in [encoder.tokenize(text, kind)]
            ]}


def build(args) -> dict:
    start = time.perf_counter()
    project = args.project.resolve()
    directory = args.assets.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    model = directory / "model.int8.onnx"
    tokenizer = directory / "tokenizer.json"
    if not model.is_file() or not tokenizer.is_file():
        raise ValueError("Pinned model.int8.onnx and tokenizer.json must already be local")
    passages, provenance = load_corpus(project, args.quran_limit, args.hadith_limit, args.translations)
    print(f"Validated {len(passages)} passages in {','.join(provenance['languages'])}", flush=True)
    encoder = E5Encoder(model, tokenizer, threads=args.threads, overlap=args.overlap)
    target = directory / "search.sqlite"
    # Flutter bundles this entire asset directory. Keep the in-progress DB and
    # its SQLite journal outside it so an unrelated app build cannot ship them.
    staging = project / ".dart_tool/offline_search"
    staging.mkdir(parents=True, exist_ok=True)
    if staging.stat().st_dev != directory.stat().st_dev:
        raise ValueError("Asset and staging directories must share a filesystem for atomic replacement")
    stage_key = hashlib.sha256(str(target).encode()).hexdigest()[:12]
    temporary = staging / f"search-{stage_key}.sqlite.building"
    if temporary.exists():
        temporary.unlink()
    connection = sqlite3.connect(temporary)
    connection.executescript(SCHEMA)
    vector_writer = PackedVectorWriter(connection)
    metadata = {
        "model_id": MODEL_ID, "model_revision": MODEL_REVISION,
        "model_sha256": sha256(model), "tokenizer_sha256": sha256(tokenizer),
        "dimensions": str(DIMENSIONS), "max_length": str(MAX_LENGTH),
        "schema_version": "2", "normalization_version": "1",
        "vector_storage": VECTOR_STORAGE, "vector_block_size": str(VECTOR_BLOCK_SIZE),
        "pooling": "attention_mask_mean_l2", "document_prefix": "passage: ",
        "query_prefix": "query: ", "chunk_overlap": str(args.overlap),
        "vector_encoding": "float32_little_endian", "corpus_sha256": provenance["corpus_sha256"],
        "corpus_provenance_json": json.dumps(provenance, ensure_ascii=False, separators=(",", ":")),
        "languages_json": json.dumps(provenance["languages"]),
    }
    connection.executemany("INSERT INTO metadata VALUES(?,?)", metadata.items())
    # Development-only persistent cache makes interrupted/full-content rebuilds
    # cheap. Keys bind exact token IDs to the model and tokenizer identities.
    cache_path = args.embedding_cache.resolve()
    cache_path.parent.mkdir(parents=True, exist_ok=True)
    cache = sqlite3.connect(cache_path)
    cache.execute("CREATE TABLE IF NOT EXISTS embeddings(key TEXT PRIMARY KEY, embedding BLOB NOT NULL CHECK(length(embedding)=1536))")
    cache_prefix = (metadata["model_sha256"] + metadata["tokenizer_sha256"] + metadata["pooling"]).encode()

    def cache_key(ids):
        return hashlib.sha256(cache_prefix + np.asarray(ids, dtype="<i8").tobytes()).hexdigest()

    # Seed with verified vectors from an older shipped build when its model
    # matches. This preserves existing vectors and avoids recomputing the POC.
    if target.exists() and cache.execute("SELECT count(*) FROM embeddings").fetchone()[0] == 0:
        old = sqlite3.connect(f"file:{target}?mode=ro", uri=True)
        old_metadata = dict(old.execute("SELECT key,value FROM metadata"))
        if all(old_metadata.get(key) == metadata[key] for key in ("model_sha256", "tokenizer_sha256", "pooling", "chunk_overlap")):
            by_id = {item.canonical_id: item for item in passages}
            for old_id, canonical_id, arabic, translations in old.execute("SELECT id,canonical_id,arabic,translations_json FROM passages"):
                passage = by_id.get(canonical_id)
                if passage is None or passage.kind not in {"quran", "hadith"} or arabic != passage.arabic or json.loads(translations) != passage.translations:
                    continue
                expected = [(language, chunk_index, ids) for language, text in passage.language_texts()
                            for chunk_index, ids in enumerate(encoder.chunks(text))]
                vectors = [(row[2], row[3], row[4]) for row in iter_vectors(old, old_id)]
                if [(row[0], row[1]) for row in vectors] != [(row[0], row[1]) for row in expected]:
                    continue
                cache.executemany("INSERT OR IGNORE INTO embeddings VALUES(?,?)", [(cache_key(item[2]), row[2]) for item, row in zip(expected, vectors)])
            cache.commit()
        old.close()
    jobs = []
    vector_count = 0
    reused_count = 0

    def flush():
        nonlocal vector_count, reused_count
        if not jobs:
            return
        # Group similar sequence lengths to avoid padding each short verse to
        # the longest Hadith in its original batch. Keep memory bounded.
        pending = {}
        resolved = {}
        keyed_jobs = []
        for row in jobs:
            key = cache_key(row[3])
            keyed_jobs.append((row, key))
            if key in resolved or key in pending:
                reused_count += 1
                continue
            cached = cache.execute("SELECT embedding FROM embeddings WHERE key=?", (key,)).fetchone()
            if cached is not None:
                resolved[key] = cached[0]
                reused_count += 1
            else:
                pending[key] = row[3]
        ordered = sorted(pending.items(), key=lambda row: len(row[1]))
        for start_index in range(0, len(ordered), args.batch_size):
            batch = ordered[start_index:start_index + args.batch_size]
            embeddings = encoder.encode_ids([row[1] for row in batch])
            entries = [(row[0], vector.tobytes()) for row, vector in zip(batch, embeddings)]
            cache.executemany("INSERT OR IGNORE INTO embeddings VALUES(?,?)", entries)
            resolved.update(entries)
        cache.commit()
        for row, key in keyed_jobs:
            vector_writer.append(row[0], row[1], row[2], resolved[key])
        vector_count += len(jobs)
        jobs.clear()

    try:
        for index, passage in enumerate(passages, 1):
            translations = json.dumps(passage.translations, ensure_ascii=False, separators=(",", ":"))
            grades = json.dumps(passage.grades, ensure_ascii=False, separators=(",", ":"))
            connection.execute("INSERT INTO passages VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", (
                index, passage.canonical_id, passage.kind, passage.reference, passage.title, passage.arabic,
                translations, grades, passage.surah_number, passage.ayah_number, passage.item_id,
                passage.body, passage.route, passage.language, passage.source_label, int(passage.is_user_content),
                json.dumps(passage.metadata, ensure_ascii=False, separators=(",", ":")),
            ))
            body = normalize_keyword(" ".join([passage.title, passage.arabic, passage.body or "",
                *[row["text"] for row in passage.translations],
                *[str(passage.metadata.get(key, "")) for key in ("category_title", "transliteration", "benefit", "notes")]]))
            connection.execute("INSERT INTO passages_fts(rowid,body,reference) VALUES(?,?,?)", (
                index, body, normalize_keyword(" ".join([*passage.aliases(), passage.reference])),
            ))
            connection.executemany("INSERT OR IGNORE INTO reference_aliases VALUES(?,?)", (
                (normalize_reference(alias), index) for alias in passage.aliases()
            ))
            for language, text in passage.language_texts():
                for chunk_index, ids in enumerate(encoder.chunks(text)):
                    jobs.append((index, language, chunk_index, ids))
                    if len(jobs) >= 1024:
                        flush()
            if index % 250 == 0:
                flush()
                connection.commit()
                print(f"Embedded {index}/{len(passages)} passages, {vector_count} vectors ({reused_count} reused), {time.perf_counter() - start:.1f}s", flush=True)
        flush()
        vector_writer.flush()
        connection.executemany("INSERT INTO metadata VALUES(?,?)", {
            "quran_count": str(provenance["selected_quran"]),
            "hadith_count": str(provenance["selected_hadith"]),
            "azkar_count": str(provenance["selected_azkar"]),
            "divine_name_count": str(provenance["selected_divine_names"]),
            "tafsir_count": str(provenance["selected_tafsir"]),
            "surah_count": str(provenance["selected_surahs"]),
            "vector_count": str(vector_count),
        }.items())
        connection.execute("INSERT INTO passages_fts(passages_fts) VALUES('optimize')")
        connection.commit()
        connection.execute("PRAGMA optimize")
        connection.execute("VACUUM")
        if connection.execute("PRAGMA integrity_check").fetchone()[0] != "ok":
            raise ValueError("Database integrity validation failed")
        if connection.execute("PRAGMA foreign_key_check").fetchall():
            raise ValueError("Database contains unresolved source identifiers")
        connection.close()
        cache.close()
        os.replace(temporary, target)
    except BaseException:
        connection.close()
        cache.close()
        temporary.unlink(missing_ok=True)
        raise
    parity = parity_cases(encoder)
    parity_path = directory / "tokenizer_parity.json"
    parity_path.write_text(json.dumps(parity, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    fixture_path = project / "test/fixtures/offline_search/tokenizer_parity.json"
    fixture_path.parent.mkdir(parents=True, exist_ok=True)
    fixture_path.write_text(parity_path.read_text(encoding="utf-8"), encoding="utf-8")
    manifest = {
        "schema_version": 2, "normalization_version": 1,
        "vector_storage": VECTOR_STORAGE, "vector_block_size": VECTOR_BLOCK_SIZE,
        "model_id": MODEL_ID, "model_revision": MODEL_REVISION,
        "dimensions": DIMENSIONS, "max_length": MAX_LENGTH,
        "pooling": "attention_mask_mean_l2", "vector_encoding": "float32_little_endian",
        "corpus": {"quran_count": provenance["selected_quran"], "hadith_count": provenance["selected_hadith"],
                   "azkar_count": provenance["selected_azkar"], "divine_name_count": provenance["selected_divine_names"],
                   "tafsir_count": provenance["selected_tafsir"], "surah_count": provenance["selected_surahs"],
                   "vector_count": vector_count, "languages": provenance["languages"],
                   "sha256": provenance["corpus_sha256"]},
        "build_seconds": round(time.perf_counter() - start, 3),
        "reused_vector_count": reused_count,
        "artifacts": {path.name: {"sha256": sha256(path), "bytes": path.stat().st_size}
                      for path in (model, tokenizer, target, parity_path)},
        "limits": {"quran": args.quran_limit, "hadith": args.hadith_limit},
        "source_policy": "All nonempty reader records, including weak, disputed and ungraded Hadith; original attributed assessments preserved; no independent authentication",
        "translation_coverage": "Bundled Arabic and English reader sources; downloaded language packs are indexed on-device separately",
    }
    manifest_path = directory / "manifest.json"
    manifest_temp = staging / f"manifest-{stage_key}.json.building"
    manifest_temp.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    os.replace(manifest_temp, manifest_path)
    print(json.dumps(manifest, ensure_ascii=False, indent=2), flush=True)
    return manifest


def main():
    project = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=project)
    parser.add_argument("--assets", type=Path, default=project / "assets/offline_search")
    parser.add_argument("--quran-limit", type=int, default=0, help="Zero indexes all 6,236 verses (default)")
    parser.add_argument("--hadith-limit", type=int, default=0, help="Zero indexes every reader-visible Hadith (default)")
    parser.add_argument("--translations", type=Path, action="append", default=[], help="Existing reviewed translation JSONL export")
    parser.add_argument("--batch-size", type=int, default=8)
    parser.add_argument("--threads", type=int, default=4)
    parser.add_argument("--overlap", type=int, default=64)
    parser.add_argument("--embedding-cache", type=Path, default=project / ".dart_tool/offline_search/embedding_cache.sqlite")
    args = parser.parse_args()
    if args.batch_size < 1 or args.threads < 1:
        parser.error("Batch size and threads must be positive")
    build(args)


if __name__ == "__main__":
    main()
