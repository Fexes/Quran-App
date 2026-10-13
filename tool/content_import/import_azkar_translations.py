#!/usr/bin/env python3
"""Import complete Azkar translations from a local Muslim Data SQLite file."""

import argparse
import hashlib
import json
import sqlite3
from pathlib import Path

from import_hadith_azkar import ASSETS, AZKAR_DB_URL, clean_text, normalize, write_json


LANGUAGES = {
    "ar": ("ar", "Arabic"),
    "ckb": ("ckb", "Kurdish (Sorani)"),
    "ckb-badini": ("ckb_BADINI", "Kurdish (Badini)"),
    "fa": ("fa", "Persian"),
    "ru": ("ru", "Russian"),
}


def import_translations(database):
    manifest_path = ASSETS / "azkar" / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    base_items = {}
    for category in manifest["categories"]:
        path = ASSETS / "azkar" / "categories" / f"{category['id']}.json"
        for item in json.loads(path.read_text(encoding="utf-8"))["items"]:
            if item["id"] in base_items:
                raise ValueError(f"Duplicate bundled item: {item['id']}")
            base_items[item["id"]] = item

    source_hash = hashlib.sha256(database.read_bytes()).hexdigest()
    packs = {}
    with sqlite3.connect(f"{database.resolve().as_uri()}?mode=ro", uri=True) as conn:
        conn.row_factory = sqlite3.Row
        for code, (source_code, label) in LANGUAGES.items():
            rows = conn.execute(
                """
                select i._id, i.item as arabic, t.item_translation as translation,
                       c.chapter_name as title, rt.reference
                from azkar_item i
                join azkar_item_translation t on t.item_id = i._id and t.language = ?
                left join azkar_chapter_translation c
                  on c.chapter_id = i.chapter_id and c.language = ?
                left join azkar_reference r on r.item_id = i._id
                left join azkar_reference_translation rt
                  on rt.reference_id = r._id and rt.language = ?
                order by i._id
                """,
                (source_code, source_code, source_code),
            ).fetchall()
            by_id = {str(row["_id"]): row for row in rows}
            if len(rows) != len(by_id) or len(by_id) != len(base_items):
                raise ValueError(f"{code}: duplicate or missing source items")
            items = {}
            for item_id, base in base_items.items():
                row = by_id.get(item_id.rsplit(":", 1)[1])
                if row is None or clean_text(row["arabic"]) != base["arabic"]:
                    raise ValueError(f"{code}: Arabic does not match {item_id}")
                text = clean_text(row["translation"])
                if not text:
                    raise ValueError(f"{code}: missing translation for {item_id}")
                items[item_id] = {
                    "translation": text,
                    "title": clean_text(row["title"]),
                    "reference": clean_text(row["reference"]),
                }
            packs[code] = {
                "version": 1,
                "languageCode": code,
                "languageName": label,
                "sourceId": "muslim_data_android",
                "sourceUrl": AZKAR_DB_URL,
                "sourceSha256": source_hash,
                "itemCount": len(items),
                "items": items,
            }

    for path in (ASSETS / "azkar" / "translations").glob("*.json"):
        code = path.stem
        if code not in packs:
            pack = json.loads(path.read_text(encoding="utf-8"))
            if not set(pack["items"]).issubset(base_items):
                raise ValueError(f"{code}: translation IDs no longer match the corpus")
            packs[code] = pack
    save_translation_packs(base_items, packs)
    print(f"Imported {len(packs)} packs for {len(base_items)} items; existing IDs and Arabic unchanged.")


def save_translation_packs(base_items, packs):
    manifest_path = ASSETS / "azkar" / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    # All packs are validated before any production asset is replaced.
    for code, pack in packs.items():
        write_json(ASSETS / "azkar" / "translations" / f"{code}.json", pack)
    manifest["translationLanguages"] = ["en", *sorted(packs)]
    write_json(manifest_path, manifest)

    index_path = ASSETS / "azkar" / "search_index.jsonl"
    records = [json.loads(line) for line in index_path.read_text().splitlines() if line]
    for record in records:
        item_id = record["targetId"]
        base = base_items[item_id]
        record["normalizedText"] = normalize(" ".join([
            base["title"], base["arabic"], base["translation"], base["reference"],
            *(" ".join(str(pack["items"].get(item_id, {}).get(field, "")) for field in ("translation", "title", "reference")) for pack in packs.values()),
        ]))
    index_path.write_text("\n".join(
        json.dumps(record, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
        for record in records
    ) + "\n", encoding="utf-8")

    sources_path = ASSETS / "content_sources" / "hadith_azkar_sources.json"
    sources = json.loads(sources_path.read_text(encoding="utf-8"))
    for source in sources["sources"]:
        if source["id"] == "muslim_data_android":
            source["languages"] = manifest["translationLanguages"]
            source["description"] = "Bundled offline Azkar with complete Arabic, English, Persian, Russian, Sorani and Badini Kurdish translations."
            if "ur" in packs:
                source["translationSources"] = [packs["ur"]["translationSource"]]
                source["description"] += (
                    " Urdu translations cover all bundled entries."
                    if packs["ur"]["itemCount"] == len(base_items)
                    else " Published Urdu translations are available for part of the corpus."
                )
    write_json(sources_path, sources)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("database", type=Path, help="Local Muslim Data v2.5.1 SQLite file")
    import_translations(parser.parse_args().database)
