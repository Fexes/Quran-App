"""Extract immutable search passages from the application's real local sources.

No network requests or generated religious text are used. Existing published
tafsir is retrieved verbatim. The visibility manifest matches the reader policy.
"""

from __future__ import annotations

import hashlib
import json
import re
import unicodedata
from dataclasses import asdict, dataclass, field
from pathlib import Path
from urllib.parse import quote, unquote, urlparse


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def normalize_keyword(value: str) -> str:
    """Match the Flutter keyword normalizer, without modifying display text."""
    value = unicodedata.normalize("NFKC", value).lower()
    value = re.sub(r"[\u0610-\u061a\u064b-\u065f\u0670\u06d6-\u06ed\u0640]", "", value)
    value = value.translate(str.maketrans("أإآٱىیک", "ااااييك"))
    value = "".join(char if unicodedata.category(char)[0] in "LNM" else " " for char in value)
    return " ".join(value.split())


def normalize_reference(value: str) -> str:
    value = unicodedata.normalize("NFKC", value).lower()
    value = value.translate(str.maketrans("٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹", "01234567890123456789"))
    value = re.sub(r"\s*:\s*", ":", value)
    return " ".join(value.split())


def semantic_text(value: str) -> str:
    return re.sub(r"[\u0009-\u000d\u0020\u0085\u00a0\u1680\u2000-\u200a\u2028\u2029\u202f\u205f\u3000]+", " ", value).strip(" ")


class DartLiteralReader:
    """Parse the package's data-only Dart maps without evaluating source code."""

    def __init__(self, text: str):
        self.text = text
        self.pos = 0

    def skip(self) -> None:
        while self.pos < len(self.text):
            if self.text[self.pos].isspace():
                self.pos += 1
            elif self.text.startswith("//", self.pos):
                end = self.text.find("\n", self.pos)
                self.pos = len(self.text) if end < 0 else end + 1
            else:
                return

    def value(self):
        self.skip()
        if self.pos >= len(self.text):
            raise ValueError("Truncated Dart data literal")
        char = self.text[self.pos]
        if char in "\"'":
            return self.string()
        if char in "[{":
            return self.collection(char)
        match = re.match(r"-?\d+(?:\.\d+)?|true\b|false\b|null\b", self.text[self.pos:])
        if not match:
            raise ValueError(f"Unsupported Dart data at offset {self.pos}")
        self.pos += len(match[0])
        if match[0] in {"true", "false", "null"}:
            return {"true": True, "false": False, "null": None}[match[0]]
        return float(match[0]) if "." in match[0] else int(match[0])

    def string(self) -> str:
        quote = self.text[self.pos]
        self.pos += 1
        result = []
        escapes = {"n": "\n", "r": "\r", "t": "\t", "b": "\b", "f": "\f"}
        while self.pos < len(self.text):
            char = self.text[self.pos]
            self.pos += 1
            if char == quote:
                return "".join(result)
            if char == "\\":
                if self.pos >= len(self.text):
                    break
                char = self.text[self.pos]
                self.pos += 1
                if char == "u":
                    if self.text[self.pos] == "{":
                        end = self.text.index("}", self.pos)
                        result.append(chr(int(self.text[self.pos + 1:end], 16)))
                        self.pos = end + 1
                    else:
                        result.append(chr(int(self.text[self.pos:self.pos + 4], 16)))
                        self.pos += 4
                else:
                    result.append(escapes.get(char, char))
            elif char == "$":
                raise ValueError("Interpolated Dart text cannot be used as source data")
            else:
                result.append(char)
        raise ValueError("Unterminated Dart string")

    def collection(self, opener: str):
        closer = "]" if opener == "[" else "}"
        self.pos += 1
        result = [] if opener == "[" else {}
        while True:
            self.skip()
            if self.pos >= len(self.text):
                raise ValueError("Unterminated Dart collection")
            if self.text[self.pos] == closer:
                self.pos += 1
                return result
            key = self.value()
            if opener == "{":
                self.skip()
                if self.text[self.pos] != ":":
                    raise ValueError("Expected Dart map colon")
                self.pos += 1
                if key in result:
                    raise ValueError(f"Duplicate Dart map key: {key}")
                result[key] = self.value()
            else:
                result.append(key)
            self.skip()
            if self.text[self.pos] == ",":
                self.pos += 1
            elif self.text[self.pos] != closer:
                raise ValueError("Expected Dart collection separator")


@dataclass(frozen=True)
class Passage:
    canonical_id: str
    kind: str
    reference: str
    title: str
    arabic: str
    translations: list[dict[str, str]]
    grades: list[dict[str, str]]
    surah_number: int | None = None
    ayah_number: int | None = None
    item_id: str | None = None
    body: str | None = None
    route: str | None = None
    language: str | None = None
    source_label: str | None = None
    is_user_content: bool = False
    metadata: dict = field(default_factory=dict)

    def language_texts(self):
        if self.arabic.strip():
            yield "ar", self.arabic
        if self.body and self.body.strip():
            yield self.language or "en", self.body
        for translation in self.translations:
            text = translation["text"]
            if self.kind not in {"quran", "hadith"}:
                text = f"{self.title}\n{text}"
            yield translation["language"], text

    def aliases(self):
        yield self.canonical_id
        if self.kind == "quran":
            yield self.reference
            yield f"{self.surah_number}:{self.ayah_number}"
            yield f"quran {self.surah_number}:{self.ayah_number}"
        elif self.kind == "hadith":
            _, slug, number = self.canonical_id.split(":", 2)
            canonical_reference = f"{self.title} {number}"
            yield canonical_reference
            # Existing recorded references use chapter-local numbers in some
            # editions. Their exact text remains displayed, but an ambiguous
            # chapter-local label must not alias a different global source ID.
            if normalize_reference(self.reference) == normalize_reference(canonical_reference):
                yield self.reference
            yield f"{slug} {number}"
            yield f"{slug}:{number}"
            yield f"hadith {slug} {number}"
        elif self.kind == "tafsir":
            yield self.title
            yield f"{self.surah_number}:{self.ayah_number}"
            yield f"quran {self.surah_number}:{self.ayah_number}"
        elif self.kind == "surah":
            yield str(self.surah_number)
            yield f"surah {self.surah_number}"
            yield self.title
            yield self.arabic
            yield normalize_keyword(self.arabic)
            yield "".join(char for char in unicodedata.normalize("NFKD", self.title) if not unicodedata.combining(char))
        elif self.kind == "divine_name":
            # A bare name such as Allah is also a broad scripture topic. Only
            # an explicit Names navigation query should bypass semantic search.
            yield f"divine name {self.item_id}"
        else:
            yield self.title


def package_root(project: Path, name: str) -> Path:
    config = project / ".dart_tool/package_config.json"
    data = json.loads(config.read_text(encoding="utf-8"))
    package = next((entry for entry in data["packages"] if entry["name"] == name), None)
    if package is None:
        raise ValueError(f"Missing {name}; run flutter pub get first")
    uri = urlparse(package["rootUri"])
    if uri.scheme == "file":
        return Path(unquote(uri.path))
    if uri.scheme:
        raise ValueError("Only locally resolved Dart packages can be indexed")
    return (config.parent / unquote(package["rootUri"])).resolve()


def read_dart_map(path: Path) -> dict:
    source = path.read_text(encoding="utf-8")
    start = source.index("=", source.index("const Map")) + 1
    result = DartLiteralReader(source[start:]).value()
    if not isinstance(result, dict):
        raise ValueError(f"Expected source map: {path}")
    return result


def read_quran(project: Path, sources: dict[str, str]) -> list[Passage]:
    root = package_root(project, "quran_with_tafsir")
    metadata_path = root / "lib/data/meta/surah_metadata_list.dart"
    metadata = metadata_path.read_text(encoding="utf-8")
    sources[str(metadata_path)] = sha256(metadata_path)
    surahs = []
    for block in re.findall(r"SurahMetadata\((.*?)\)", metadata, re.S):
        number = re.search(r"number:\s*(\d+)", block)
        count = re.search(r"ayahCount:\s*(\d+)", block)
        name = re.search(r"nameEn:\s*", block)
        if not (number and count and name):
            raise ValueError("Incomplete local Quran surah metadata")
        surahs.append((int(number[1]), int(count[1]), DartLiteralReader(block[name.end():]).value()))
    if [row[0] for row in surahs] != list(range(1, 115)) or sum(row[1] for row in surahs) != 6236:
        raise ValueError("Local Quran metadata must contain 114 surahs and 6,236 verses")
    arabic_path = project / "assets/data/quran/qpc_hafs.json"
    sources[str(arabic_path)] = sha256(arabic_path)
    arabic = json.loads(arabic_path.read_text(encoding="utf-8"))
    if len(arabic) != 6236:
        raise ValueError("Incomplete bundled QPC Hafs Quran")
    passages = []
    global_index = 0
    for number, count, name in surahs:
        english_path = root / f"lib/data/quran/english/surah_{number}.dart"
        sources[str(english_path)] = sha256(english_path)
        english = read_dart_map(english_path)
        if english["id"] != number or len(english["verses"]) != count:
            raise ValueError(f"Incomplete English source for surah {number}")
        for verse, translation in enumerate(english["verses"], 1):
            text, position = arabic[global_index]
            global_index += 1
            if position != global_index or not isinstance(text, str) or not text.strip():
                raise ValueError(f"Invalid bundled Arabic verse {number}:{verse}")
            if translation["id"] != verse or translation["surah"] != number:
                raise ValueError(f"Mismatched English verse {number}:{verse}")
            if not isinstance(translation["text"], str) or not translation["text"].strip():
                raise ValueError(f"Missing English verse {number}:{verse}")
            passages.append(Passage(
                canonical_id=f"quran:{number}:{verse}", kind="quran",
                reference=f"{number}:{verse}", title=name, arabic=text,
                translations=[{"language": "en", "text": translation["text"],
                               "source": "quran_with_tafsir_saheeh_international"}],
                grades=[], surah_number=number, ayah_number=verse,
            ))
    return passages


def should_show(item: dict) -> bool:
    """Mirror reader display eligibility, independently of recorded grading.

    Weak, disputed, scoped, and ungraded records remain readable with their
    actual source assessments. Display eligibility is not authentication.
    Exact parity is checked against the Dart-generated visibility manifest.
    """
    return any(isinstance(item.get(key), str) and item[key].strip()
               for key in ("arabic", "translation"))


def read_hadith(project: Path, sources: dict[str, str]) -> list[list[Passage]]:
    root = project / "assets/data/hadith"
    manifest_path = root / "manifest.json"
    visibility_path = root / "visibility.json"
    policy_path = project / "lib/features/hadith/domain/services/hadith_authenticity_policy.dart"
    for path in (manifest_path, visibility_path, policy_path):
        sources[str(path)] = sha256(path)
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    visibility = json.loads(visibility_path.read_text(encoding="utf-8"))
    if visibility.get("version") != 2 or visibility.get("policy") != "nonempty-arabic-or-translation":
        raise ValueError("Stale Hadith display policy; regenerate visibility.json")
    books = []
    for book in sorted(manifest["books"], key=lambda item: item["sortOrder"]):
        path = root / "books" / f"{book['slug']}.json"
        sources[str(path)] = sha256(path)
        data = json.loads(path.read_text(encoding="utf-8"))
        visible = visibility["books"][book["slug"]]
        visible_ids = set(visible["ids"])
        if len(visible_ids) != visible["hadithCount"]:
            raise ValueError(f"Duplicate or invalid visibility IDs: {book['slug']}")
        accepted = [item for item in data["hadiths"] if should_show(item)]
        accepted_ids = {item["id"] for item in accepted}
        if accepted_ids != visible_ids or len(accepted) != len(accepted_ids):
            raise ValueError(f"Stale Hadith visibility/policy mismatch: {book['slug']}; regenerate visibility.json")
        passages = []
        for item in accepted:
            if item["id"] != f"hadith:{book['slug']}:{item['hadithNumber']}":
                raise ValueError(f"Non-canonical Hadith ID: {item['id']}")
            grades = []
            for grade in item.get("grades", []):
                if isinstance(grade, dict) and isinstance(grade.get("grade"), str):
                    recorded = grade["grade"]
                    grader = grade.get("name") or grade.get("grader") or ""
                    if recorded.strip():
                        grades.append({"grader": str(grader), "grade": recorded})
                elif isinstance(grade, str) and grade.strip():
                    # Keep attributed string assessments byte-for-byte. The
                    # shared grading model interprets their scope and names.
                    grades.append({"grader": "", "grade": grade})
            if not grades and isinstance(item.get("grade"), str) and item["grade"].strip():
                grades.append({"grader": "", "grade": item["grade"]})
            translations = []
            if item.get("translation", "").strip():
                translations.append({"language": "en", "text": item["translation"],
                                     "source": item.get("englishEdition") or item["sourceId"]})
            passages.append(Passage(
                canonical_id=item["id"], kind="hadith", reference=item["reference"],
                title=item.get("collectionName") or book["englishName"], arabic=item["arabic"],
                translations=translations, grades=grades, item_id=item["id"],
                source_label=item["sourceId"],
                metadata={"bookId": item["bookId"], "sourceId": item["sourceId"],
                          "arabicEdition": item.get("arabicEdition", ""),
                          "englishEdition": item.get("englishEdition", "")},
            ))
        if passages:
            books.append(passages)
    return books


def select_quran(passages: list[Passage], limit: int) -> list[Passage]:
    if limit <= 0 or limit >= len(passages):
        return passages
    # Fixed references cover all chapters and a few concrete reference smoke checks.
    must = {"quran:2:255", "quran:94:5", "quran:94:6", "quran:13:28", "quran:65:3"}
    firsts = [index for index, passage in enumerate(passages) if passage.ayah_number == 1]
    anchors = [index for index, passage in enumerate(passages) if passage.canonical_id in must]
    selected = set((anchors + firsts)[:limit])
    remaining = limit - len(selected)
    if remaining:
        candidates = [index for index in range(len(passages)) if index not in selected]
        selected.update(candidates[(step * len(candidates)) // remaining] for step in range(remaining))
    return [passages[index] for index in sorted(selected)]


def read_static_content(project: Path, sources: dict[str, str]) -> list[Passage]:
    """Read every bundled Azkar and divine name from the same reader sources.

    Optional language packs belong to the device's downloaded-content overlay;
    the shipped base stores the reader's default Arabic/English edition only.
    """
    root = project / "assets/data/azkar"
    manifest_path = root / "manifest.json"
    sources[str(manifest_path)] = sha256(manifest_path)
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    result = []
    for category in sorted(manifest["categories"], key=lambda item: item["sortOrder"]):
        path = root / "categories" / f"{category['id']}.json"
        sources[str(path)] = sha256(path)
        items = json.loads(path.read_text(encoding="utf-8"))["items"]
        if len(items) != category["itemCount"]:
            raise ValueError(f"Azkar manifest count mismatch: {category['id']}")
        for item in items:
            if item["categoryId"] != category["id"] or not item["arabic"].strip():
                raise ValueError(f"Invalid Azkar reader source: {item['id']}")
            translations = [{"language": "en", "text": item["translation"], "source": item["sourceId"]}] if item.get("translation", "").strip() else []
            result.append(Passage(
                canonical_id=item["id"], kind="azkar", reference=item["reference"],
                title=item["title"], arabic=item["arabic"], translations=translations,
                grades=[], item_id=item["id"],
                route=f"/library/azkar/{quote(category['id'], safe='')}?item={quote(item['id'], safe='')}",
                source_label=item["sourceId"],
                metadata={"category_id": category["id"], "category_title": category["englishName"],
                          "repeat_count": item["repeatCount"], "transliteration": item.get("transliteration", ""),
                          "benefit": item.get("benefit", ""), "notes": item.get("notes", "")},
            ))
    path = project / "assets/data/worship/asma.json"
    sources[str(path)] = sha256(path)
    data = json.loads(path.read_text(encoding="utf-8"))
    names = [item for item in data["names"] if item["number"] > 0 and item["arabic"]]
    if len(names) != 99:
        raise ValueError("The bundled Names dataset is incomplete")
    for item in names:
        meaning = item["meaning"]
        if item.get("description"):
            meaning += "\n" + item["description"]
        result.append(Passage(
            canonical_id=f"divine_name:{item['number']}", kind="divine_name",
            reference=", ".join(item.get("references", [])), title=item["transliteration"],
            arabic=item["arabic"], translations=[{"language": "en", "text": meaning, "source": data["source"]}],
            grades=[], item_id=str(item["number"]), route="/worship-tools/names",
            source_label=data["source"], metadata={"number": item["number"]},
        ))
    return result


def read_bundled_quran_reference(project: Path, quran: list[Passage], sources: dict[str, str]) -> list[Passage]:
    """Preserve the reader's bundled Al-Muyassar commentary and surah metadata."""
    root = package_root(project, "quran_with_tafsir")
    for name in ("README.md", "pubspec.yaml"):
        sources[str(root / name)] = sha256(root / name)
    version = re.search(r"^version:\s*(\S+)", (root / "pubspec.yaml").read_text(), re.M).group(1)
    tafsir_source = f"Tafsir Al-Muyassar (King Fahd Complex; quran_with_tafsir {version})"
    by_surah = {number: [item for item in quran if item.surah_number == number] for number in range(1, 115)}
    result = []
    for number in range(1, 115):
        path = root / f"lib/data/tafsir/arabic/tafsir_{number}.dart"
        sources[str(path)] = sha256(path)
        data = read_dart_map(path)
        verses = data["verses"]
        if data["id"] != number or [item["id"] for item in verses] != list(range(1, len(by_surah[number]) + 1)):
            raise ValueError(f"Incomplete bundled Tafsir source for surah {number}")
        for item in verses:
            verse = item["id"]
            text = item["text"]
            if not isinstance(text, str) or not text.strip():
                raise ValueError(f"Missing bundled Tafsir {number}:{verse}")
            result.append(Passage(
                canonical_id=f"tafsir:bundled:{number}:{verse}", kind="tafsir",
                reference=f"Quran {number}:{verse}", title=f"Tafsir Al-Muyassar: {number}:{verse}",
                arabic="", translations=[], grades=[], surah_number=number, ayah_number=verse,
                body=text, language="ar", source_label=tafsir_source,
                route=f"/quran/{number}?ayah={verse}&tafsir=bundled",
                metadata={"tafsirSource": "bundled", "verseKey": f"{number}:{verse}"},
            ))
    path = root / "lib/data/meta/surah_metadata_list.dart"
    sources[str(path)] = sha256(path)
    for block in re.findall(r"SurahMetadata\((.*?)\)", path.read_text(), re.S):
        number = int(re.search(r"number:\s*(\d+)", block)[1])
        count = int(re.search(r"ayahCount:\s*(\d+)", block)[1])
        values = {key: DartLiteralReader(block[re.search(rf"{key}:\s*", block).end():]).value()
                  for key in ("nameEn", "nameAr", "revelationType")}
        if count != len(by_surah[number]):
            raise ValueError(f"Surah navigation metadata mismatch: {number}")
        result.append(Passage(
            canonical_id=f"surah:{number}", kind="surah", reference=f"Surah {number}",
            title=values["nameEn"], arabic=values["nameAr"], translations=[], grades=[],
            surah_number=number, item_id=str(number),
            body=f"{values['nameEn']}. Surah {number}. {count} verses. {values['revelationType']}.", language="en",
            source_label=f"Tanzil.net (quran_with_tafsir {version})", route=f"/quran/{number}",
            metadata={"ayahCount": count, "revelationType": values["revelationType"]},
        ))
    return result


def select_hadith(books: list[list[Passage]], limit: int) -> list[Passage]:
    all_count = sum(len(book) for book in books)
    target = all_count if limit <= 0 else min(limit, all_count)
    selected = []
    offset = 0
    while len(selected) < target:
        for book in books:
            if offset < len(book):
                selected.append(book[offset])
                if len(selected) == target:
                    break
        offset += 1
    return selected


def add_translations(passages: list[Passage], paths: list[Path], sources: dict[str, str]) -> list[Passage]:
    """Import existing, reviewed local translation exports; never synthesize text."""
    indexed = {passage.canonical_id: passage for passage in passages}
    additions: dict[str, list[dict[str, str]]] = {}
    for path in paths:
        sources[str(path)] = sha256(path)
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if not line.strip():
                continue
            data = json.loads(line)
            if set(data) != {"canonical_id", "language", "text", "source"}:
                raise ValueError(f"Translation export requires canonical_id/language/text/source: {path}:{number}")
            if data["canonical_id"] not in indexed:
                raise ValueError(f"Unknown or hidden translation target: {data['canonical_id']}")
            if not all(isinstance(data[key], str) and data[key].strip() for key in data):
                raise ValueError(f"Empty translation fields: {path}:{number}")
            if data["language"] == "ar":
                raise ValueError("Translation exports cannot replace original Arabic")
            additions.setdefault(data["canonical_id"], []).append({key: data[key] for key in ("language", "text", "source")})
    result = []
    for passage in passages:
        translations = passage.translations + additions.get(passage.canonical_id, [])
        identities = [(row["language"], row["source"]) for row in translations]
        if len(identities) != len(set(identities)):
            raise ValueError(f"Duplicate translation edition: {passage.canonical_id}")
        values = asdict(passage)
        values["translations"] = translations
        result.append(Passage(**values))
    return result


def load_corpus(project: Path, quran_limit: int = 0, hadith_limit: int = 0,
                translation_paths: list[Path] | None = None,
                include_static: bool = True) -> tuple[list[Passage], dict]:
    if quran_limit < 0 or hadith_limit < 0:
        raise ValueError("Limits must be nonnegative; zero includes the complete corpus")
    hashes: dict[str, str] = {}
    quran = read_quran(project, hashes)
    hadith = read_hadith(project, hashes)
    static = (read_static_content(project, hashes) + read_bundled_quran_reference(project, quran, hashes)) if include_static else []
    combined = add_translations(quran + [item for book in hadith for item in book] + static, translation_paths or [], hashes)
    by_id = {passage.canonical_id: passage for passage in combined}
    if len(by_id) != len(combined):
        raise ValueError("Duplicate canonical source identifiers")
    selected = select_quran(quran, quran_limit) + select_hadith(hadith, hadith_limit) + static
    selected = [by_id[item.canonical_id] for item in selected]
    # Include attribution manifests in the corpus fingerprint.
    for relative in ("assets/data/content_sources/quran_sources.json", "assets/data/content_sources/hadith_azkar_sources.json"):
        path = project / relative
        hashes[str(path)] = sha256(path)
    # Portable identity uses source hashes, independent of the pub-cache location.
    corpus_digest = hashlib.sha256("\n".join(sorted(hashes.values())).encode()).hexdigest()
    return selected, {
        "corpus_sha256": corpus_digest, "source_files": hashes,
        "available_quran": len(quran), "available_hadith": sum(len(book) for book in hadith),
        "selected_quran": sum(item.kind == "quran" for item in selected),
        "selected_hadith": sum(item.kind == "hadith" for item in selected),
        "selected_azkar": sum(item.kind == "azkar" for item in selected),
        "selected_divine_names": sum(item.kind == "divine_name" for item in selected),
        "selected_tafsir": sum(item.kind == "tafsir" for item in selected),
        "selected_surahs": sum(item.kind == "surah" for item in selected),
        "languages": sorted({language for item in selected for language, _ in item.language_texts()}),
        "selection": "Complete Quran and reader-visible Hadith when limits are zero; all bundled Azkar, divine names, Tafsir Al-Muyassar, and surah metadata",
    }
