#!/usr/bin/env python3
"""Bundle IndoPak text with the app's Hafs verse keys and verified word positions."""
import ast
import json
import re
import struct
import sys
import unicodedata
from pathlib import Path

from import_hadith_azkar import ROOT, write_json


def letters(text):
    text = re.sub(r"[\uFC00-\uFCFF]", "", text)
    text = unicodedata.normalize("NFKD", text).translate(
        str.maketrans({"\u0671": "\u0627", "\u0649": "\u064a", "\u06cc": "\u064a", "\u06a9": "\u0643"})
    )
    return "".join(char for char in text if "\u0620" <= char <= "\u064a" and unicodedata.category(char) == "Lo")


def word_positions(original, display):
    source_words = [word for word in original.split() if letters(word)]
    target_words = display.split()
    source = [letters(word) for word in source_words]
    target = [letters(word) for word in target_words]
    if len(source) == len(target):
        # A dagger alif and a written alif can represent the same long vowel.
        variants = lambda word: {letters(word), letters(word.replace("\u0670", "\u0627"))}
        return [index + 1 if variants(first) & variants(second) else 0
                for index, (first, second) in enumerate(zip(source_words, target_words))]
    if "".join(source) != "".join(target):
        return [0] * len(target)
    boundaries, offset = {}, 0
    for index, word in enumerate(source):
        boundaries[(offset, offset + len(word))] = index + 1
        offset += len(word)
    result, offset = [], 0
    for word in target:
        result.append(boundaries.get((offset, offset + len(word)), 0))
        offset += len(word)
    return result


def validate_font(texts):
    raw = (ROOT / "assets/fonts/DigitalKhattIndoPak.ttf").read_bytes()
    tables = {raw[12 + i * 16:16 + i * 16]: struct.unpack_from(">II", raw, 20 + i * 16) for i in range(struct.unpack_from(">H", raw, 4)[0])}
    cmap = tables[b"cmap"][0]
    table = cmap + struct.unpack_from(">I", raw, cmap + 8)[0]
    assert struct.unpack_from(">H", raw, table)[0] == 4, "Review updated font cmap format"
    count = struct.unpack_from(">H", raw, table + 6)[0] // 2
    end = table + 14
    start = end + count * 2 + 2
    delta = start + count * 2
    ranges = delta + count * 2
    missing = []
    for char in set("".join(texts)):
        value, glyph = ord(char), 0
        for i in range(count):
            low, high = struct.unpack_from(">H", raw, start + i * 2)[0], struct.unpack_from(">H", raw, end + i * 2)[0]
            if low <= value <= high:
                shift, relative = struct.unpack_from(">h", raw, delta + i * 2)[0], struct.unpack_from(">H", raw, ranges + i * 2)[0]
                glyph = value if relative == 0 else struct.unpack_from(">H", raw, ranges + i * 2 + relative + (value - low) * 2)[0]
                glyph = (glyph + shift) & 0xffff if glyph else 0
                break
        if not glyph and not char.isspace():
            missing.append(f"U+{value:04X}")
    assert not missing, f"IndoPak font missing Quran characters: {sorted(missing)}"


def main():
    chapters = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    layout_source = Path(sys.argv[2]).read_text(encoding="utf-8")
    layout = ast.literal_eval(layout_source[layout_source.index("["):layout_source.rindex("]") + 1])
    basmala = layout[0][1].split("\u06dd", 1)[0].strip()
    fatiha = chapters[0]["verses"]
    assert len(fatiha) == 7 and letters(fatiha[0]["text"]).startswith("\u0627\u0644\u062d\u0645\u062f")
    # The display script changes, not the verse keys used by audio and translations.
    chapters[0]["verses"] = [{"id": 1, "text": basmala}] + [
        {"id": index + 2, "text": fatiha[index]["text"]} for index in range(5)
    ] + [{"id": 7, "text": fatiha[5]["text"] + " " + fatiha[6]["text"]}]
    baseline = Path(sys.argv[3])
    records = {}
    assert [chapter["id"] for chapter in chapters] == list(range(1, 115))
    for chapter in chapters:
        number = chapter["id"]
        source = (baseline / f"surah_{number}.dart").read_text(encoding="utf-8")
        body = source[source.index("{"):source.rindex("}") + 1]
        body = re.sub(r":\s*true\b", ": True", body)
        body = re.sub(r":\s*false\b", ": False", body)
        verses = ast.literal_eval(body)["verses"]
        assert len(verses) == len(chapter["verses"]), f"Verse count differs for surah {number}"
        for original, verse in zip(verses, chapter["verses"]):
            assert original["id"] == verse["id"]
            text = unicodedata.normalize("NFC", verse["text"])
            assert text.strip() and "\u06dd" not in text
            assert not re.search(r"[\u202a-\u202e]", text), "Unexpected bidi override"
            records[f"{number}:{verse['id']}"] = {
                "text": text,
                "positions": word_positions(original["text"], text),
            }
    assert len(records) == 6236
    validate_font(record["text"] for record in records.values())
    write_json(ROOT / "assets/data/quran/indopak.json", records)
    matched = sum(position > 0 for record in records.values() for position in record["positions"])
    words = sum(len(record["positions"]) for record in records.values())
    print(f"Bundled {len(records)} verses; font covers all characters; {matched}/{words} verified word positions")


if __name__ == "__main__":
    main()
