#!/usr/bin/env python3
"""Match locally downloaded published Urdu chapters by Arabic, never numbering."""

import argparse
import hashlib
import json
import re
import sqlite3
import unicodedata
from html.parser import HTMLParser
from pathlib import Path

from import_hadith_azkar import ASSETS, clean_text
from import_azkar_translations import save_translation_packs


SUPPLEMENT = Path(__file__).parent / "sources" / "azkar_urdu_supplement.json"


class Element:
    def __init__(self, tag="", attrs=()):
        self.tag, self.attrs, self.children = tag, dict(attrs), []

    def text(self, skip_references=False):
        return "".join(
            child if isinstance(child, str) else "" if skip_references and "reference" in child.attrs.get("class", "").split() else child.text(skip_references)
            for child in self.children
        )

    def walk(self):
        yield self
        for child in self.children:
            if isinstance(child, Element):
                yield from child.walk()


class BookParser(HTMLParser):
    def __init__(self, text):
        super().__init__(convert_charrefs=True)
        self.root = Element()
        self.stack = [self.root]
        self.feed(text)

    def handle_starttag(self, tag, attrs):
        node = Element(tag, attrs)
        self.stack[-1].children.append(node)
        if tag not in {"br", "img", "input", "meta", "link", "hr", "source", "area", "wbr", "embed"}:
            self.stack.append(node)

    def handle_endtag(self, tag):
        for index in range(len(self.stack) - 1, 0, -1):
            if self.stack[index].tag == tag:
                del self.stack[index:]
                return

    def handle_data(self, text):
        self.stack[-1].children.append(text)


def arabic_key(text):
    text = re.sub(r"\s+", " ", text).strip()
    text = re.sub(r"\[(?:سور[ةۃ]|صحيح|سنن|مختصر)[^\]]*\]", "", text)
    text = re.sub(r"\(?سور[ةۃ]\s+(?:آل\s*عمران|آلعمران|الاخلاص|الإخلاص|الفلق|الناس|البقرة|الحديد)\)?", "", text)
    text = re.sub(r"\(\s*(?:(?:ثلاث|أربع|سبع|مائة|مئة|\d+)\s+(?:مرات|مرة)|باسمه|بِاسْمِهِ)\s*\)", "", text)
    text = text.replace("صلى الله عليه وسلم", "").replace("صَلَّى الله عَلَيْهِ وَسَلَّمَ", "")
    text = unicodedata.normalize("NFKD", text).translate(str.maketrans("أإآٱىؤئہکھیۃ", "اااايويهكهية"))
    return "".join(c for c in text if "\u0600" <= c <= "\u06ff" and unicodedata.category(c).startswith("L") and not "\u06d6" <= c <= "\u06ed" and c != "\u0640")


def import_urdu(folder, morning_database):
    records = []
    hashes = {}
    chapters = sorted(folder.glob("chapter-*.html"))
    if len(chapters) != 134:
        raise ValueError("Expected all 134 published chapter pages")
    for path in chapters:
        raw = path.read_bytes()
        hashes[path.name] = hashlib.sha256(raw).hexdigest()
        arabic = None
        for node in BookParser(raw.decode("utf-8-sig")).root.walk():
            classes = node.attrs.get("class", "").split()
            if "hadith_arabic" in classes and node.attrs.get("id", "").endswith("_with"):
                arabic = clean_text(node.text())
            elif node.tag == "div" and {"hadith_urdu", "fonturdu"}.issubset(classes):
                translation = clean_text(node.text(skip_references=True))
                if arabic and translation:
                    records.append({"arabic": arabic, "translation": translation, "sourceUrl": f"https://islamicurdubooks.com/hadith/ad.php?bsc_id={path.stem.split('-')[1]}"})
                    arabic = None
    with sqlite3.connect(f"{morning_database.resolve().as_uri()}?mode=ro", uri=True) as database:
        for arabic, translation in database.execute("select supplication,supplication_translation_ur from supplication_detail"):
            records.append({"arabic": clean_text(arabic), "translation": clean_text(translation), "sourceUrl": "https://github.com/islamstatus360/me_azkar"})
    hashes[morning_database.name] = hashlib.sha256(morning_database.read_bytes()).hexdigest()
    supplement = json.loads(SUPPLEMENT.read_text(encoding="utf-8"))
    if supplement.get("version") != 1 or not supplement.get("sources"):
        raise ValueError("Invalid published Urdu supplement")
    source_urls = {source["sourceUrl"] for source in supplement["sources"]}
    for record in supplement["exactRecords"]:
        if not record.get("arabic") or not record.get("translation") or record.get("sourceUrl") not in source_urls:
            raise ValueError("Invalid exact Urdu source record")
        records.append(record)
    hashes[SUPPLEMENT.name] = hashlib.sha256(SUPPLEMENT.read_bytes()).hexdigest()
    indexed = {}
    for record in records:
        key = arabic_key(record["arabic"])
        if key:
            indexed.setdefault(key, record)
    base = {}
    for path in (ASSETS / "azkar" / "categories").glob("*.json"):
        for item in json.loads(path.read_text(encoding="utf-8"))["items"]:
            if item["id"] in base:
                raise ValueError("Duplicate existing Azkar ID")
            base[item["id"]] = item
    items, missing = {}, []
    for item_id, item in sorted(base.items()):
        match = indexed.get(arabic_key(item["arabic"]))
        if match is None:
            missing.append(item_id)
            continue
        if not match["translation"] or not re.search(r"[پچژگٹڈڑںھہےی]", match["translation"]):
            raise ValueError(f"Missing Urdu text: {item_id}")
        items[item_id] = {"translation": match["translation"], "sourceArabic": match["arabic"], "sourceUrl": match["sourceUrl"]}

    # Narrated/composite passages need explicit review, never a fuzzy match.
    for item_id, record in supplement["reviewedItems"].items():
        item = base.get(item_id)
        if item is None or hashlib.sha256(item["arabic"].encode("utf-8")).hexdigest() != record.get("expectedArabicSha256"):
            raise ValueError(f"Reviewed Urdu Arabic changed: {item_id}")
        if record.get("sourceUrl") not in source_urls or not record.get("sourceExcerpt") or not record.get("matchNote"):
            raise ValueError(f"Missing Urdu review provenance: {item_id}")
        if not isinstance(record.get("translation"), str) or not re.search(r"[پچژگٹڈڑںھہےی]", record["translation"]):
            raise ValueError(f"Missing reviewed Urdu text: {item_id}")
        items[item_id] = dict(record)
    missing = sorted(set(base) - set(items))
    if missing or len(items) != len(base):
        raise ValueError(f"Urdu source coverage changed: {len(items)} matches from {len(records)} records; review before importing")
    packs = {path.stem: json.loads(path.read_text(encoding="utf-8")) for path in (ASSETS / "azkar" / "translations").glob("*.json")}
    packs["ur"] = {
        "version": 1, "languageCode": "ur", "languageName": "Urdu",
        "sourceId": "muslim_data_android", "itemCount": len(items),
        "corpusItemCount": len(base), "coverage": "complete", "missingItemIds": missing,
        "translationSource": {
            "name": "Published Urdu Hisnul Muslim editions", "author": "Hafiz Zubair Ali Zai (Islamic Urdu Books edition)",
            "sourceUrl": "https://islamicurdubooks.com/hadith/index.php?bookid=19",
            "supplementUrl": "https://github.com/islamstatus360/me_azkar",
            "matching": "Exact normalized Arabic plus reviewed full narrated/composite passages guarded by Arabic SHA256; no fuzzy or numbering joins",
            "sourceFileSha256": hashes, "additionalSources": supplement["sources"],
        }, "items": items,
    }
    save_translation_packs(base, packs)
    print(f"Urdu imported: {len(items)} matched translations; {len(missing)} unavailable; Arabic and IDs unchanged.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("chapters", type=Path)
    parser.add_argument("morning_database", type=Path)
    args = parser.parse_args()
    import_urdu(args.chapters, args.morning_database)
