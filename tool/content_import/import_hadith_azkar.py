#!/usr/bin/env python3
import html
import json
import re
import sqlite3
import unicodedata
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "assets" / "data"
UMMAH_HADITHS = (
    ROOT.parent
    / "ummah-library-main"
    / "packages"
    / "data"
    / "datasets"
    / "hadiths"
)

HADITH_BASE = "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1"
AZKAR_DB_URL = (
    "https://raw.githubusercontent.com/my-prayers/muslim-data-android/main/"
    "muslim-data/src/main/assets/database/muslim_db_v2.5.1.db"
)

HADITH_ARABIC_NAMES = {
    "abudawud": "سنن أبي داود",
    "bukhari": "صحيح البخاري",
    "dehlawi": "الأربعون حديثا لشاه ولي الله الدهلوي",
    "ibnmajah": "سنن ابن ماجه",
    "malik": "موطأ مالك",
    "muslim": "صحيح مسلم",
    "nasai": "سنن النسائي",
    "nawawi": "الأربعون النووية",
    "qudsi": "الأربعون القدسية",
    "tirmidhi": "جامع الترمذي",
}

HADITH_DESCRIPTIONS = {
    "bukhari": "Canonical sahih collection compiled by Imam al-Bukhari.",
    "muslim": "Canonical sahih collection compiled by Imam Muslim.",
    "abudawud": "One of the six canonical Sunni hadith books.",
    "tirmidhi": "One of the six canonical Sunni hadith books.",
    "nasai": "One of the six canonical Sunni hadith books.",
    "ibnmajah": "One of the six canonical Sunni hadith books.",
    "malik": "Early hadith and fiqh collection by Imam Malik.",
    "nawawi": "The famous Forty Hadith collection of Imam an-Nawawi.",
    "qudsi": "Forty Hadith Qudsi collection.",
    "dehlawi": "Forty Hadith collection of Shah Waliullah Dehlawi.",
}

AZKAR_ICON_KEYS = {
    "morning-evening": "sunny",
    "home-family": "home",
    "food-drink": "restaurant",
    "joy-distress": "favorite",
    "travel": "travel",
    "prayer": "prayer",
    "praising-allah": "tasbieh",
    "hajj-umrah": "kaaba",
    "good-etiquette": "etiquette",
    "nature": "nature",
    "sickness-death": "health",
}

ARABIC_MARKS = re.compile(r"[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]")
TAG_RE = re.compile(r"<[^>]+>")


def fetch_json(url):
    with urllib.request.urlopen(url, timeout=60) as response:
        return json.loads(response.read().decode("utf-8"))


def fetch_bytes(url):
    with urllib.request.urlopen(url, timeout=120) as response:
        return response.read()


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(data, ensure_ascii=False, sort_keys=True, separators=(",", ":")),
        encoding="utf-8",
    )


def slugify(value):
    value = value.lower().replace("&", "and")
    value = re.sub(r"[^a-z0-9]+", "-", value).strip("-")
    return value or "item"


def clean_text(value):
    if value is None:
        return ""
    text = html.unescape(str(value))
    text = TAG_RE.sub(" ", text)
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def normalize(value):
    text = clean_text(value).lower()
    text = ARABIC_MARKS.sub("", text).replace("\u0640", "")
    text = unicodedata.normalize("NFKD", text)
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    text = text.translate(
        str.maketrans(
            {
                "ʿ": "",
                "ʾ": "",
                "ʼ": "",
                "ʻ": "",
                "’": "",
                "‘": "",
                "`": "",
                "´": "",
                "ß": "ss",
                "æ": "ae",
                "œ": "oe",
            }
        )
    )
    text = re.sub(r"[^\w\u0600-\u06FF:]+", " ", text, flags=re.UNICODE)
    return re.sub(r"\s+", " ", text).strip()


def preview(value, limit=240):
    text = clean_text(value).replace("\n", " ")
    if len(text) <= limit:
        return text
    return text[: limit - 1].rstrip() + "…"


def edition_for(collection, prefix):
    for edition in collection:
        if edition["name"].startswith(prefix):
            return edition
    return None


def grade_text(grades):
    if not grades:
        return ""
    pieces = []
    for grade in grades:
        if isinstance(grade, dict):
            name = grade.get("name") or grade.get("grade") or ""
            graded_by = grade.get("graded_by") or grade.get("scholar") or ""
            text = " ".join(part for part in [name, graded_by] if part)
            if text:
                pieces.append(text)
        elif grade:
            pieces.append(str(grade))
    return "; ".join(pieces)


def number_text(value):
    if value is None:
        return ""
    if isinstance(value, float):
        return format(value, ".15g")
    return str(value).strip()


def number_sort_key(value):
    return tuple(int(part) for part in number_text(value).split(".") if part)


def ummah_english_data(book_slug):
    path = UMMAH_HADITHS / f"eng-{book_slug}.json"
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def import_hadith():
    editions = fetch_json(f"{HADITH_BASE}/editions.min.json")
    books_dir = ASSETS / "hadith" / "books"
    search_path = ASSETS / "hadith" / "search_index.jsonl"
    books_dir.mkdir(parents=True, exist_ok=True)
    search_path.parent.mkdir(parents=True, exist_ok=True)

    manifest_books = []
    search_lines = []

    for sort_order, book_slug in enumerate(sorted(editions.keys()), start=1):
        info = editions[book_slug]
        collection = info["collection"]
        arabic_edition = edition_for(collection, f"ara-{book_slug}")
        english_edition = edition_for(collection, f"eng-{book_slug}")
        if arabic_edition is None or english_edition is None:
            raise RuntimeError(f"Missing Arabic or English edition for {book_slug}")

        arabic_data = fetch_json(arabic_edition["linkmin"])
        english_data = fetch_json(english_edition["linkmin"])
        ummah_data = ummah_english_data(book_slug)
        metadata = english_data.get("metadata") or arabic_data.get("metadata") or {}
        sections = (ummah_data or {}).get("sections") or metadata.get("sections") or {}

        arabic_by_number = {
            number_text(item["hadithnumber"]): item
            for item in arabic_data.get("hadiths", [])
            if item.get("hadithnumber") is not None
        }
        if ummah_data is None:
            english_items = english_data.get("hadiths", [])
        else:
            english_items = [
                {
                    "hadithnumber": item.get("number"),
                    "text": item.get("text"),
                    "grades": item.get("grades") or [],
                    "reference": item.get("reference") or {},
                }
                for item in ummah_data.get("hadiths", [])
            ]
        english_items = sorted(
            english_items,
            key=lambda item: number_sort_key(item.get("hadithnumber") or 0),
        )

        book_name = (ummah_data or {}).get("name") or info["name"]
        source_id = (
            "ummah_library_hadith" if ummah_data is not None else "fawaz_hadith_api"
        )
        chapter_counts = {}
        hadiths = []
        for item in english_items:
            number = number_text(item.get("hadithnumber"))
            if not number or number_sort_key(number) <= (0,):
                continue
            arabic = arabic_by_number.get(number, {})
            ref = item.get("reference") or {}
            book_number = int(ref.get("book") or 0)
            local_hadith = number_text(ref.get("hadith") or number)
            chapter_id = f"{book_slug}_{book_number or 0}"
            reference = f"{book_name} {local_hadith}"
            grades = item.get("grades") or []
            grade = grade_text(grades)
            arabic_text = clean_text(arabic.get("text"))
            translation_text = clean_text(item.get("text"))
            chapter_counts[book_number] = chapter_counts.get(book_number, 0) + 1
            hadith = {
                "id": f"hadith:{book_slug}:{number}",
                "bookId": book_slug,
                "bookSlug": book_slug,
                "chapterId": chapter_id,
                "chapterNumber": book_number,
                "bookNumber": book_number,
                "hadithNumber": number,
                "arabicNumber": number_text(arabic.get("hadithnumber") or number),
                "arabic": arabic_text,
                "translation": translation_text,
                "grade": grade,
                "grades": grades,
                "reference": reference,
                "cleanReference": reference,
                "collectionName": book_name,
                "englishEdition": english_edition["name"],
                "arabicEdition": arabic_edition["name"],
                "sourceId": source_id,
            }
            hadiths.append(hadith)
            search_lines.append(
                {
                    "id": hadith["id"],
                    "category": "hadith",
                    "title": reference,
                    "subtitle": grade,
                    "primaryPreview": preview(hadith["arabic"]),
                    "secondaryPreview": preview(hadith["translation"]),
                    "normalizedText": normalize(
                        " ".join(
                            [
                                reference,
                                grade,
                                hadith["arabic"],
                                hadith["translation"],
                            ]
                        )
                    ),
                    "targetType": "hadith",
                    "targetId": hadith["id"],
                    "bookId": book_slug,
                }
            )

        chapters = []
        for raw_number, title in sorted(sections.items(), key=lambda pair: int(pair[0])):
            number = int(raw_number)
            if chapter_counts.get(number, 0) == 0:
                continue
            chapters.append(
                {
                    "id": f"{book_slug}_{number}",
                    "bookId": book_slug,
                    "number": number,
                    "englishTitle": clean_text(title),
                    "arabicTitle": "",
                    "hadithCount": chapter_counts.get(number, 0),
                    "startHadithNumber": "",
                    "endHadithNumber": "",
                }
            )

        available_languages = sorted(
            {edition.get("language", "") for edition in collection if edition.get("language")}
        )
        manifest_books.append(
            {
                "id": book_slug,
                "slug": book_slug,
                "englishName": book_name,
                "arabicName": HADITH_ARABIC_NAMES.get(book_slug, book_name),
                "shortName": book_name.replace("Sunan ", "").replace("Sahih ", ""),
                "description": HADITH_DESCRIPTIONS.get(book_slug, ""),
                "hadithCount": len(hadiths),
                "chapterCount": len(chapters),
                "sortOrder": sort_order,
                "availableLanguages": available_languages,
                "sourceId": source_id,
            }
        )
        write_json(books_dir / f"{book_slug}.json", {"chapters": chapters, "hadiths": hadiths})

    write_json(
        ASSETS / "hadith" / "manifest.json",
        {
            "version": 1,
            "books": manifest_books,
        },
    )
    search_path.write_text(
        "\n".join(
            json.dumps(line, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
            for line in search_lines
        )
        + "\n",
        encoding="utf-8",
    )


def import_azkar():
    tmp_db = Path("/tmp/muslim_data_android.db")
    tmp_db.write_bytes(fetch_bytes(AZKAR_DB_URL))
    conn = sqlite3.connect(tmp_db)
    conn.row_factory = sqlite3.Row

    categories_dir = ASSETS / "azkar" / "categories"
    search_path = ASSETS / "azkar" / "search_index.jsonl"
    categories_dir.mkdir(parents=True, exist_ok=True)
    search_path.parent.mkdir(parents=True, exist_ok=True)

    categories = []
    search_lines = []
    category_rows = conn.execute(
        """
        select c._id as id,
               en.category_name as english_name,
               ar.category_name as arabic_name
        from azkar_category c
        join azkar_category_translation en on en.category_id = c._id and en.language = 'en'
        left join azkar_category_translation ar on ar.category_id = c._id and ar.language = 'ar'
        order by c._id
        """
    ).fetchall()

    for sort_order, category in enumerate(category_rows, start=1):
        category_id = int(category["id"])
        slug = slugify(category["english_name"])
        rows = conn.execute(
            """
            select i._id as item_id,
                   i.item as arabic,
                   i.chapter_id as chapter_id,
                   en_item.item_translation as translation,
                   ar_ch.chapter_name as arabic_title,
                   en_ch.chapter_name as english_title,
                   en_ref.reference as reference
            from azkar_item i
            join azkar_chapter ch on ch._id = i.chapter_id
            left join azkar_item_translation en_item
              on en_item.item_id = i._id and en_item.language = 'en'
            left join azkar_chapter_translation en_ch
              on en_ch.chapter_id = i.chapter_id and en_ch.language = 'en'
            left join azkar_chapter_translation ar_ch
              on ar_ch.chapter_id = i.chapter_id and ar_ch.language = 'ar'
            left join azkar_reference r on r.item_id = i._id
            left join azkar_reference_translation en_ref
              on en_ref.reference_id = r._id and en_ref.language = 'en'
            where ch.category_id = ?
            order by i.chapter_id, i._id
            """,
            (category_id,),
        ).fetchall()
        items = []
        for item_order, row in enumerate(rows, start=1):
            repeat = repeat_count_for(row["translation"], row["english_title"])
            item_id = f"azkar:{slug}:{row['item_id']}"
            dhikr = {
                "id": item_id,
                "categoryId": slug,
                "title": clean_text(row["english_title"]),
                "arabic": clean_text(row["arabic"]),
                "translation": clean_text(row["translation"]),
                "transliteration": "",
                "reference": clean_text(row["reference"]),
                "repeatCount": repeat,
                "notes": "",
                "benefit": "",
                "categorySortOrder": sort_order,
                "itemSortOrder": item_order,
                "sourceId": "muslim_data_android",
            }
            if not dhikr["arabic"]:
                raise RuntimeError(f"Empty Arabic text for {item_id}")
            items.append(dhikr)
            search_lines.append(
                {
                    "id": item_id,
                    "category": "azkar",
                    "title": dhikr["title"] or category["english_name"],
                    "subtitle": f"Repeat {repeat}x",
                    "primaryPreview": preview(dhikr["arabic"]),
                    "secondaryPreview": preview(dhikr["translation"]),
                    "normalizedText": normalize(
                        " ".join(
                            [
                                dhikr["title"],
                                dhikr["arabic"],
                                dhikr["translation"],
                                dhikr["reference"],
                            ]
                        )
                    ),
                    "targetType": "azkar",
                    "targetId": item_id,
                    "categoryId": slug,
                }
            )

        categories.append(
            {
                "id": slug,
                "slug": slug,
                "englishName": category["english_name"],
                "arabicName": category["arabic_name"] or "",
                "description": "",
                "itemCount": len(items),
                "sortOrder": sort_order,
                "iconKey": AZKAR_ICON_KEYS.get(slug, "favorite"),
                "sourceId": "muslim_data_android",
            }
        )
        write_json(categories_dir / f"{slug}.json", {"items": items})

    write_json(ASSETS / "azkar" / "manifest.json", {"version": 1, "categories": categories})
    search_path.write_text(
        "\n".join(
            json.dumps(line, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
            for line in search_lines
        )
        + "\n",
        encoding="utf-8",
    )


def repeat_count_for(*values):
    text = " ".join(clean_text(value).lower() for value in values if value)
    match = re.search(r"(\d+)\s*(?:times|x)", text)
    if match:
        return int(match.group(1))
    if "one hundred" in text:
        return 100
    if "thirty-three" in text or "33" in text:
        return 33
    if "three times" in text or "3 times" in text:
        return 3
    return 1


def write_sources():
    write_json(
        ASSETS / "content_sources" / "hadith_azkar_sources.json",
        {
            "sources": [
                {
                    "id": "fawaz_hadith_api",
                    "name": "Hadith API static JSON",
                    "attribution": "Hadith content imported from fawazahmed0/hadith-api.",
                    "description": "Bundled offline Arabic and English hadith editions.",
                    "sourceUrl": "https://github.com/fawazahmed0/hadith-api",
                    "license": (
                        "Upstream repository: Unlicense; translation rights vary by edition"
                    ),
                },
                {
                    "id": "ummah_library_hadith",
                    "name": "Ummah Library Hadith datasets",
                    "attribution": (
                        "English Hadith datasets normalized by Ummah Library from "
                        "fawazahmed0/hadith-api. Full grader labels are retained."
                    ),
                    "description": (
                        "Build-time offline datasets for six canonical collections. "
                        "Translation rights vary by edition and require review before distribution."
                    ),
                    "sourceUrl": "https://github.com/fawazahmed0/hadith-api",
                    "license": (
                        "Ummah Library code: AGPL-3.0; upstream repository: Unlicense; "
                        "translation rights vary by collection"
                    ),
                },
                {
                    "id": "muslim_data_android",
                    "name": "Muslim Data Android",
                    "attribution": "Azkar content imported from my-prayers/muslim-data-android.",
                    "description": "Bundled offline Hisnul Muslim style Azkar data.",
                    "sourceUrl": "https://github.com/my-prayers/muslim-data-android",
                    "license": "Apache-2.0",
                },
            ]
        },
    )


def validate_assets():
    hadith_manifest = json.loads((ASSETS / "hadith" / "manifest.json").read_text())
    azkar_manifest = json.loads((ASSETS / "azkar" / "manifest.json").read_text())
    if len(hadith_manifest["books"]) != 10:
        raise RuntimeError("Expected 10 Hadith books")
    if len(azkar_manifest["categories"]) < 10:
        raise RuntimeError("Expected at least 10 Azkar categories")
    for book in hadith_manifest["books"]:
        data = json.loads((ASSETS / "hadith" / "books" / f"{book['slug']}.json").read_text())
        if not data["chapters"] or not data["hadiths"]:
            raise RuntimeError(f"Invalid book asset {book['slug']}")
    for category in azkar_manifest["categories"]:
        data = json.loads(
            (ASSETS / "azkar" / "categories" / f"{category['slug']}.json").read_text()
        )
        if not data["items"]:
            raise RuntimeError(f"Invalid Azkar category {category['slug']}")


def main():
    import_hadith()
    import_azkar()
    write_sources()
    from import_azkar_translations import import_translations
    import_translations(Path('/tmp/muslim_data_android.db'))
    validate_assets()


if __name__ == "__main__":
    main()
