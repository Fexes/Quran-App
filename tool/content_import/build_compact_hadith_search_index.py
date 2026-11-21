#!/usr/bin/env python3
"""Build a lossless book-reference replacement for the legacy Hadith JSONL.

Uses local assets only. Keep search_index.jsonl as import/build provenance,
then run build_compact_hadith_search_index.dart before packaging this asset.
"""

import hashlib
import itertools
import json
import re
import subprocess
import unicodedata
from pathlib import Path

from import_hadith_azkar import ARABIC_MARKS, clean_text, normalize, preview

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "assets" / "data" / "hadith"
FIELDS = ["reference", "cleanReference", "grade", "arabic", "translation"]
FOLD = str.maketrans({
    "ʿ": "", "ʾ": "", "ʼ": "", "ʻ": "", "’": "", "‘": "",
    "`": "", "´": "", "ß": "ss", "æ": "ae", "œ": "oe",
})


def character_mapping(character):
    value = ARABIC_MARKS.sub("", character.lower()).replace("\u0640", "")
    value = unicodedata.normalize("NFKD", value)
    value = "".join(ch for ch in value if not unicodedata.combining(ch))
    return re.sub(r"[^\w\u0600-\u06FF:]+", " ", value.translate(FOLD))


def derived_record(hadith):
    return {
        "id": hadith["id"],
        "category": "hadith",
        "title": hadith.get("reference", ""),
        "subtitle": hadith.get("grade", ""),
        "primaryPreview": preview(hadith.get("arabic", "")),
        "secondaryPreview": preview(hadith.get("translation", "")),
        "normalizedText": normalize(" ".join(hadith.get(f, "") for f in FIELDS)),
        "targetType": "hadith",
        "targetId": hadith["id"],
        "bookId": hadith["bookId"],
        "sourceId": hadith.get("sourceId", ""),
        "grades": hadith.get("grades") or [],
    }


def main(*, verify_runtime=True):
    source = ASSETS / "search_index.jsonl"
    records = [json.loads(line) for line in source.read_text().splitlines() if line.strip()]
    groups = []
    characters = {" "}
    book_hashes = {}
    override_count = 0
    for slug, grouped in itertools.groupby(records, key=lambda item: item["bookId"]):
        grouped = list(grouped)
        book_path = ASSETS / "books" / f"{slug}.json"
        book_hashes[slug] = hashlib.sha256(book_path.read_bytes()).hexdigest()
        hadiths = json.loads(book_path.read_text())["hadiths"]
        by_id = {hadith["id"]: hadith for hadith in hadiths}
        group = {"book": slug, "fields": FIELDS}
        if [record["targetId"] for record in grouped] != [hadith["id"] for hadith in hadiths]:
            prefix = f"hadith:{slug}:"
            if any(not record["targetId"].startswith(prefix) for record in grouped):
                raise ValueError(f"Unexpected target ID prefix for {slug}")
            group["records"] = [record["targetId"][len(prefix):] for record in grouped]
        overrides = {}
        for record in grouped:
            hadith = by_id[record["targetId"]]
            text = clean_text(" ".join(hadith.get(f, "") for f in FIELDS))
            characters.update(text)
            derived = derived_record(hadith)
            if set(derived) != set(record):
                raise ValueError(f"Unexpected index fields: {record['targetId']}")
            changes = {key: value for key, value in record.items() if derived[key] != value}
            if changes:
                overrides[record["targetId"]] = changes
            if {**derived, **changes} != record:
                raise ValueError(f"Reconstruction changed {record['targetId']}")
        if overrides:
            group["overrides"] = overrides
        override_count += len(overrides)
        groups.append(group)
    compact = {
        "version": 1,
        "recordCount": len(records),
        "sourceSha256": hashlib.sha256(source.read_bytes()).hexdigest(),
        "bookSha256": book_hashes,
        "normalization": {character: character_mapping(character) for character in sorted(characters)},
        "groups": groups,
    }
    destination = ASSETS / "search_index.compact.json"
    previous = destination.read_bytes() if destination.exists() else None
    destination.write_text(json.dumps(compact, ensure_ascii=False, separators=(",", ":")))
    print(json.dumps({
        "records": len(records),
        "overriddenRecords": override_count,
        "sourceBytes": source.stat().st_size,
        "compactBytes": destination.stat().st_size,
        "savedBytes": source.stat().st_size - destination.stat().st_size,
        "verifiedRawFields": True,
    }, indent=2))
    if verify_runtime:
        try:
            subprocess.run(
                ["dart", "run", "tool/content_import/build_compact_hadith_search_index.dart", "--verify-only"],
                cwd=ROOT,
                check=True,
            )
        except (OSError, subprocess.CalledProcessError):
            if previous is None:
                destination.unlink()
            else:
                destination.write_bytes(previous)
            raise


if __name__ == "__main__":
    main()
