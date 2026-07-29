#!/usr/bin/env python3
from collections import defaultdict, deque
import json

from import_hadith_azkar import (
    ASSETS,
    UMMAH_HADITHS,
    clean_text,
    grade_text,
    normalize,
    number_sort_key,
    number_text,
    preview,
    write_json,
)


UMMAH_BOOKS = (
    "abudawud",
    "bukhari",
    "ibnmajah",
    "muslim",
    "nasai",
    "tirmidhi",
)


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def translation_key(value):
    return clean_text(value)


def rebuild_ummah_book(book_slug, current):
    source = read_json(UMMAH_HADITHS / f"eng-{book_slug}.json")
    current_by_translation = defaultdict(deque)
    for hadith in current.get("hadiths", []):
        current_by_translation[translation_key(hadith.get("translation"))].append(hadith)

    chapter_counts = defaultdict(int)
    chapter_numbers = defaultdict(list)
    rebuilt = []
    matched_arabic = 0
    for source_hadith in source.get("hadiths", []):
        number = number_text(source_hadith.get("number"))
        text = clean_text(source_hadith.get("text"))
        candidates = current_by_translation[translation_key(text)]
        previous = candidates.popleft() if candidates else {}
        reference_data = source_hadith.get("reference") or {}
        book_number = int(reference_data.get("book") or 0)
        local_number = number_text(reference_data.get("hadith") or number)
        grades = source_hadith.get("grades") or []
        reference = f"{source['name']} {local_number}"

        arabic = clean_text(previous.get("arabic"))
        arabic_number = number_text(previous.get("arabicNumber"))
        if "." in number:
            arabic = ""
            arabic_number = ""
        elif arabic:
            matched_arabic += 1

        item = dict(previous)
        item.update(
            {
                "id": f"hadith:{book_slug}:{number}",
                "bookId": book_slug,
                "bookSlug": book_slug,
                "chapterId": f"{book_slug}_{book_number}",
                "chapterNumber": book_number,
                "bookNumber": book_number,
                "hadithNumber": number,
                "arabicNumber": arabic_number,
                "arabic": arabic,
                "translation": text,
                "grade": grade_text(grades),
                "grades": grades,
                "reference": reference,
                "cleanReference": reference,
                "collectionName": source["name"],
                "englishEdition": source["collectionId"],
                "arabicEdition": previous.get("arabicEdition", f"ara-{book_slug}"),
                "sourceId": "ummah_library_hadith",
            }
        )
        rebuilt.append(item)
        chapter_counts[book_number] += 1
        chapter_numbers[book_number].append(number)

    previous_chapters = {
        int(chapter.get("number") or 0): chapter
        for chapter in current.get("chapters", [])
    }
    chapters = []
    for raw_number, title in sorted(
        source.get("sections", {}).items(), key=lambda pair: int(pair[0])
    ):
        number = int(raw_number)
        if chapter_counts[number] == 0:
            continue
        old = previous_chapters.get(number, {})
        numbers = chapter_numbers[number]
        chapters.append(
            {
                "id": f"{book_slug}_{number}",
                "bookId": book_slug,
                "number": number,
                "englishTitle": clean_text(title),
                "arabicTitle": old.get("arabicTitle", ""),
                "hadithCount": chapter_counts[number],
                "startHadithNumber": numbers[0],
                "endHadithNumber": numbers[-1],
            }
        )

    ids = [item["id"] for item in rebuilt]
    if len(ids) != len(set(ids)):
        raise RuntimeError(f"Duplicate Hadith IDs remain in {book_slug}")
    if len(rebuilt) != len(source.get("hadiths", [])):
        raise RuntimeError(f"Incomplete Ummah Library sync for {book_slug}")

    return (
        {
            "provenance": {
                "ingestionProject": "Ummah Library",
                "upstream": source.get("source", {}),
                "datasetVersion": source.get("version", ""),
            },
            "chapters": chapters,
            "hadiths": rebuilt,
        },
        source["name"],
        matched_arabic,
    )


def remove_empty_chapters(data):
    populated = {item.get("chapterId") for item in data.get("hadiths", [])}
    data["chapters"] = [
        chapter
        for chapter in data.get("chapters", [])
        if chapter.get("id") in populated
    ]
    return data


def search_record(hadith):
    return {
        "id": hadith["id"],
        "category": "hadith",
        "title": hadith.get("reference", ""),
        "subtitle": hadith.get("grade", ""),
        "primaryPreview": preview(hadith.get("arabic", "")),
        "secondaryPreview": preview(hadith.get("translation", "")),
        "normalizedText": normalize(
            " ".join(
                [
                    hadith.get("reference", ""),
                    hadith.get("cleanReference", ""),
                    hadith.get("grade", ""),
                    hadith.get("arabic", ""),
                    hadith.get("translation", ""),
                ]
            )
        ),
        "targetType": "hadith",
        "targetId": hadith["id"],
        "bookId": hadith["bookId"],
    }


def update_sources():
    path = ASSETS / "content_sources" / "hadith_azkar_sources.json"
    data = read_json(path)
    for source in data.get("sources", []):
        if source.get("id") == "fawaz_hadith_api":
            source["license"] = (
                "Upstream repository: Unlicense; translation rights vary by edition"
            )
    data["sources"] = [
        source
        for source in data.get("sources", [])
        if source.get("id") != "ummah_library_hadith"
    ]
    data["sources"].insert(
        1,
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
    )
    write_json(path, data)


def main():
    books_dir = ASSETS / "hadith" / "books"
    manifest_path = ASSETS / "hadith" / "manifest.json"
    manifest = read_json(manifest_path)
    search_records = []

    for book in manifest.get("books", []):
        slug = book["slug"]
        path = books_dir / f"{slug}.json"
        current = read_json(path)
        if slug in UMMAH_BOOKS:
            data, english_name, matched_arabic = rebuild_ummah_book(slug, current)
            book["englishName"] = english_name
            book["sourceId"] = "ummah_library_hadith"
            print(
                f"{slug}: {len(data['hadiths'])} hadiths, "
                f"{matched_arabic} matched Arabic texts"
            )
        else:
            data = remove_empty_chapters(current)

        book["hadithCount"] = len(data["hadiths"])
        book["chapterCount"] = len(data["chapters"])
        write_json(path, data)
        search_records.extend(search_record(item) for item in data["hadiths"])

    manifest["version"] = 2
    write_json(manifest_path, manifest)
    search_path = ASSETS / "hadith" / "search_index.jsonl"
    search_path.write_text(
        "\n".join(
            json.dumps(record, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
            for record in search_records
        )
        + "\n",
        encoding="utf-8",
    )
    update_sources()
    print(f"search index: {len(search_records)} unique Hadith records")


if __name__ == "__main__":
    main()
