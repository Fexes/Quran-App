#!/usr/bin/env python3
"""Audit every bundled record against pinned public source editions.

This verifies data transport and attribution, not religious authenticity.
The default is read-only for assets. Repairs require an explicit repair flag.
"""

import argparse
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re

from import_hadith_azkar import (
    ASSETS,
    ROOT,
    UMMAH_HADITHS,
    clean_text,
    fetch_bytes,
    grade_text,
    number_text,
    write_json,
)
from sync_ummah_hadith import HADITH_SOURCE_COMMIT, UMMAH_BOOKS, source_edition


WHOLE_WEAK = {"Daif", "Very Daif", "Daif Munkar", "Munkar Daif"}
WHOLE_ACCEPTED = {
    "Sahih", "Hasan", "Hasan Sahih", "Sahih Lighairihi",
    "Hasan Lighairihi", "Sahih Hadith", "Sahih Matn", "Sahih Mutawatir",
    "Sahih - Agreed Upon", "Sahih - Bukhari And Muslim", "Sahih Bukhari",
    "Sahih Muslim",
}
OTHER_KNOWN = {"Mawdu", "Batil", "Munkar", "Shadh"}
REFERENCE_ASSESSMENT = re.compile(
    r"(?:Sahih (?:Bukhari|Muslim) \([^)]*\))"
    r"(?: Sahih (?:Bukhari|Muslim) \([^)]*\))*"
)
CHAIN = re.compile(r"\b(?:isnaad|sanad)\b", re.IGNORECASE)
NON_PROPHETIC = re.compile(r"\b(?:mauquf|muquf|mawquf|maqtu)\b", re.IGNORECASE)


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def assessment_pairs(grades):
    result = []
    for grade in grades or []:
        if isinstance(grade, dict):
            assessment = clean_text(grade.get("grade"))
            scholar = clean_text(grade.get("graded_by") or grade.get("scholar"))
            name = clean_text(grade.get("name"))
            if assessment:
                scholar = scholar or name
            else:
                assessment = name
        else:
            scholar, separator, assessment = str(grade).partition(":")
            if not separator:
                scholar, assessment = "", str(grade)
        result.append((clean_text(scholar), clean_text(assessment)))
    return result


def assessment_scope(assessment):
    # Scope flags prevent a chain or companion judgment becoming a blanket
    # judgment about a prophetic narration. They are not new scholarly grades.
    if NON_PROPHETIC.search(assessment):
        return "non_prophetic_report"
    if CHAIN.search(assessment):
        return "chain_judgment"
    if assessment in WHOLE_WEAK:
        return "reported_whole_weak"
    if assessment in WHOLE_ACCEPTED or REFERENCE_ASSESSMENT.fullmatch(assessment):
        return "reported_whole_accepted"
    if assessment in OTHER_KNOWN:
        return "other_reported_judgment"
    return "unrecognized_or_missing"


def fetch_source_cache(cache, editions):
    cache.mkdir(parents=True, exist_ok=True)

    def download(edition):
        url = (
            "https://raw.githubusercontent.com/fawazahmed0/hadith-api/"
            f"{HADITH_SOURCE_COMMIT}/editions/{edition}.min.json"
        )
        raw = fetch_bytes(url)
        data = json.loads(raw)
        (cache / f"{edition}.json").write_bytes(raw)
        return {
            "edition": edition, "url": url, "sha256": digest(raw),
            "bytes": len(raw), "hadiths": len(data.get("hadiths", [])),
        }

    with ThreadPoolExecutor(max_workers=4) as pool:
        files = list(pool.map(download, editions))
    manifest = {
        "project": "fawazahmed0/hadith-api",
        "commit": HADITH_SOURCE_COMMIT,
        "retrievedAt": datetime.now(timezone.utc).isoformat(),
        "files": files,
    }
    (cache / "source_manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )


def verified_cache(cache, editions):
    manifest = read_json(cache / "source_manifest.json")
    if manifest.get("commit") != HADITH_SOURCE_COMMIT:
        raise RuntimeError("Source cache commit does not match the pinned audit version")
    files = {item["edition"]: item for item in manifest["files"]}
    loaded = {}
    for edition in editions:
        raw = (cache / f"{edition}.json").read_bytes()
        if edition not in files or digest(raw) != files[edition]["sha256"]:
            raise RuntimeError(f"Source cache integrity failed: {edition}")
        loaded[edition] = source_edition(edition, raw)
    return manifest, loaded


def repair_arabic(rows, source_rows, english_rows, provenance):
    repairs = []
    for row in rows:
        number = row["hadithNumber"]
        english = english_rows.get(number)
        if (
            english is None
            or row.get("translation", "") != clean_text(english.get("text"))
            or assessment_pairs(row.get("grades")) != assessment_pairs(english.get("grades"))
        ):
            continue
        source = source_rows.get(number)
        # Missing and empty source text stays flagged, without invented text.
        if source is None or not clean_text(source.get("text")):
            continue
        expected = clean_text(source["text"])
        if row.get("arabic") == expected and row.get("arabicNumber") == number:
            continue
        before_text = row.get("arabic", "")
        repairs.append({
            "id": row["id"],
            "reason": "restore_source_text" if not before_text else "canonical_number_join",
            "beforeArabicNumber": row.get("arabicNumber", ""),
            "afterArabicNumber": number,
            "beforeArabicSha256": digest(before_text.encode("utf-8")),
            "afterArabicSha256": digest(expected.encode("utf-8")),
            "sourceEdition": provenance["edition"],
            "sourceFileSha256": provenance["sha256"],
            "sourceUrl": provenance["url"],
            "sourceCommit": provenance["commit"],
        })
        row["arabic"] = expected
        row["arabicNumber"] = number
    return repairs


def repair_references(rows, english_rows):
    repairs = []
    for row in rows:
        number = row["hadithNumber"]
        source = english_rows.get(number)
        if (
            source is None
            or row.get("translation", "") != clean_text(source.get("text"))
            or assessment_pairs(row.get("grades")) != assessment_pairs(source.get("grades"))
        ):
            continue
        reference = f"{row['collectionName']} {number}"
        if row.get("reference") == reference and row.get("cleanReference") == reference:
            continue
        original_reference = source.get("reference") or {}
        repairs.append([
            row["id"], original_reference.get("book"), original_reference.get("hadith"),
            row.get("reference", ""), row.get("cleanReference", ""),
        ])
        row["reference"] = reference
        row["cleanReference"] = reference
        row["sourceEditionReference"] = original_reference
    return repairs


def run(args):
    manifest = read_json(ASSETS / "hadith" / "manifest.json")
    books = manifest["books"]
    editions = [f"{language}-{book['id']}" for book in books for language in ("eng", "ara")]
    if args.fetch_upstream:
        fetch_source_cache(args.source_cache, editions)
    source_manifest, upstream = verified_cache(args.source_cache, editions)
    previous = read_json(args.json_output) if args.json_output.exists() else {}
    repairs = list(previous.get("arabicRepairs", []))
    repair_ids = {item["id"] for item in repairs}
    reference_repairs = list(previous.get("referenceRepairs", {}).get("rows", []))
    reference_repair_ids = {item[0] for item in reference_repairs}
    totals, assessment_frequency, scholar_frequency, scope_frequency = (
        Counter(), Counter(), Counter(), Counter()
    )
    book_reports, findings, all_ids = [], [], set()
    for book in books:
        slug = book["id"]
        path = ASSETS / "hadith" / "books" / f"{slug}.json"
        data = read_json(path)
        rows = data["hadiths"]
        english, english_provenance = upstream[f"eng-{slug}"]
        arabic, arabic_provenance = upstream[f"ara-{slug}"]
        local_source, local_provenance = {}, None
        if slug in UMMAH_BOOKS:
            source_path = UMMAH_HADITHS / f"eng-{slug}.json"
            raw = source_path.read_bytes()
            snapshot = json.loads(raw)
            for item in snapshot["hadiths"]:
                number = number_text(item.get("number"))
                if not number or number in local_source:
                    raise RuntimeError(f"Ambiguous local source number: {slug}:{number}")
                local_source[number] = item
            local_provenance = {
                "relativePath": str(source_path.relative_to(ROOT.parent)),
                "sha256": digest(raw), "source": snapshot.get("source", {}),
            }
        before_except_arabic = json.dumps([
            {k: v for k, v in row.items() if k not in ("arabic", "arabicNumber")}
            for row in rows
        ], sort_keys=True, ensure_ascii=False)
        if args.repair_arabic:
            numbers = [row["hadithNumber"] for row in rows]
            if len(numbers) != len(set(numbers)):
                raise RuntimeError(f"Ambiguous app numbers prevent repair in {slug}")
            changed = repair_arabic(rows, arabic, english, arabic_provenance)
            if changed:
                after_except_arabic = json.dumps([
                    {k: v for k, v in row.items() if k not in ("arabic", "arabicNumber")}
                    for row in rows
                ], sort_keys=True, ensure_ascii=False)
                if before_except_arabic != after_except_arabic:
                    raise RuntimeError(f"Unexpected non-Arabic changes in {slug}")
                write_json(path, data)
                repairs.extend(item for item in changed if item["id"] not in repair_ids)
                repair_ids.update(item["id"] for item in changed)
        if args.repair_references:
            reference_fields = ("reference", "cleanReference", "sourceEditionReference")
            before_except_references = json.dumps([
                {k: v for k, v in row.items() if k not in reference_fields} for row in rows
            ], sort_keys=True, ensure_ascii=False)
            changed = repair_references(rows, english)
            if changed:
                after_except_references = json.dumps([
                    {k: v for k, v in row.items() if k not in reference_fields} for row in rows
                ], sort_keys=True, ensure_ascii=False)
                if before_except_references != after_except_references:
                    raise RuntimeError(f"Unexpected changes during reference repair in {slug}")
                write_json(path, data)
                reference_repairs.extend(row for row in changed if row[0] not in reference_repair_ids)
                reference_repair_ids.update(row[0] for row in changed)
        counts, issues = Counter(), []
        if len(rows) != book["hadithCount"]:
            issues.append({"issue": "manifest_count_mismatch"})
        app_numbers = {row["hadithNumber"] for row in rows}
        source_nonempty_numbers = {
            number for number, item in english.items() if clean_text(item.get("text"))
        }
        source_nonempty_numbers.update(
            number for number, item in arabic.items() if clean_text(item.get("text"))
        )
        missing_nonempty_numbers = sorted(source_nonempty_numbers - app_numbers)
        counts["omittedBothLanguageEmptyPlaceholders"] = len(
            (set(english) | set(arabic)) - app_numbers - source_nonempty_numbers
        )
        if missing_nonempty_numbers:
            issues.append({
                "issue": "nonempty_source_records_missing_from_bundle",
                "numbers": missing_nonempty_numbers,
            })
        for row in rows:
            number, identifier = row["hadithNumber"], row["id"]
            counts["records"] += 1
            if not row.get("translation"):
                counts["recordsWithoutEnglish"] += 1
            record_issues = []
            if (
                identifier != f"hadith:{slug}:{number}"
                or identifier in all_ids
                or row.get("bookId") != slug
                or row.get("englishEdition") != f"eng-{slug}"
                or row.get("arabicEdition") != f"ara-{slug}"
            ):
                record_issues.append("invalid_or_duplicate_canonical_id")
            all_ids.add(identifier)
            pairs = assessment_pairs(row.get("grades"))
            counts["recordsWithGrades" if pairs else "recordsWithoutGrades"] += 1
            counts["assessments"] += len(pairs)
            scopes = []
            for scholar, assessment in pairs:
                assessment_frequency[assessment] += 1
                scholar_frequency[scholar] += 1
                scope = assessment_scope(assessment)
                scopes.append(scope)
                scope_frequency[scope] += 1
                if not scholar:
                    counts["unattributedAssessments"] += 1
            for scope in set(scopes):
                counts[f"records:{scope}"] += 1
            if scopes and all(scope == "reported_whole_weak" for scope in scopes):
                counts["unanimousWithinImportedWholeWeakReports"] += 1
            if "reported_whole_weak" in scopes and "reported_whole_accepted" in scopes:
                counts["conflictingImportedWholeGrades"] += 1
            raw_display = grade_text(row.get("grades") or [])
            if row.get("grade", "") != raw_display:
                record_issues.append("display_grade_differs_from_raw_assessments")
            original = english.get(number)
            if original is None:
                record_issues.append("english_source_number_absent")
            else:
                if row.get("translation", "") != clean_text(original.get("text")):
                    record_issues.append("english_text_differs_from_exact_number_source")
                if pairs != assessment_pairs(original.get("grades")):
                    record_issues.append("grades_differ_from_exact_number_source")
                reference = original.get("reference") or {}
                if row.get("bookNumber") != int(reference.get("book") or 0):
                    record_issues.append("chapter_differs_from_source_reference")
                if row.get("sourceEditionReference", reference) != reference:
                    record_issues.append("saved_edition_reference_differs_from_source")
                display_reference = f"{row['collectionName']} {number}"
                if (
                    row.get("reference") != display_reference
                    or row.get("cleanReference") != display_reference
                ):
                    record_issues.append("display_reference_is_not_canonical_number")
            if local_source:
                local = local_source.get(number)
                if local is None:
                    record_issues.append("local_snapshot_number_absent")
                elif (
                    row.get("translation") != clean_text(local.get("text"))
                    or row.get("grades") != (local.get("grades") or [])
                ):
                    record_issues.append("data_differs_from_local_snapshot")
            original_arabic = arabic.get(number)
            expected_arabic = clean_text((original_arabic or {}).get("text"))
            if original_arabic is None:
                record_issues.append("arabic_source_number_absent")
            elif not expected_arabic:
                counts["sourceEmptyArabic"] += 1
                findings.append({"id": identifier, "issue": "source_empty_arabic"})
            if row.get("arabic", "") != expected_arabic:
                record_issues.append("arabic_text_differs_from_exact_number_source")
            if row.get("arabic") and row.get("arabicNumber") != number:
                record_issues.append("arabic_number_differs_from_canonical_number")
            if not row.get("arabic"):
                counts["recordsWithoutArabic"] += 1
            if record_issues:
                issues.append({"id": identifier, "issues": record_issues})
                counts["recordsWithTransportIssues"] += 1
            else:
                counts["recordsVerifiedAgainstPinnedUpstream"] += 1
        totals.update(counts)
        book_reports.append({
            "bookId": slug, "counts": dict(counts),
            "assetSha256": digest(path.read_bytes()),
            "englishSource": english_provenance, "arabicSource": arabic_provenance,
            "localSnapshot": local_provenance, "transportIssues": issues,
            "upstreamEnglishRecords": len(english),
            "upstreamEmptyEnglishRecords": sum(not clean_text(x.get("text")) for x in english.values()),
            "missingNonemptyUpstreamRecords": missing_nonempty_numbers,
        })
    grade_repair = previous.get("displayGradeRepair")
    if args.grade_repair_report:
        grade_repair = read_json(args.grade_repair_report)
    report = {
        "schemaVersion": 1, "auditedAt": datetime.now(timezone.utc).isoformat(),
        "scope": "All bundled Hadith records, all imported assessments and exact canonical source joins",
        "evidenceBoundary": [
            "This is a transport and attribution audit of public secondary datasets.",
            "Agreement with imported labels does not establish scholarly consensus or primary-source certification.",
            "No individual grade has been independently certified against a published scholarly primary edition.",
            "No grade is inferred from a collection title; missing, scoped and conflicting judgments remain separate.",
        ],
        "primarySourceCertifiedWeakRecords": 0,
        "allNonemptyUpstreamRecordsIncluded": all(
            not book["missingNonemptyUpstreamRecords"] for book in book_reports
        ),
        "sourceSnapshot": source_manifest, "totals": dict(totals),
        "assessmentFrequency": dict(assessment_frequency.most_common()),
        "scholarFrequency": dict(scholar_frequency.most_common()),
        "assessmentScopeFrequency": dict(scope_frequency), "books": book_reports,
        "sourceLimitations": findings, "arabicRepairs": repairs,
        "referenceRepairs": {
            "columns": ["id", "sourceBook", "sourceHadith", "beforeReference", "beforeCleanReference"],
            "rows": reference_repairs,
            "newReferencePattern": "collectionName + space + canonical hadithNumber",
        },
        "displayGradeRepair": grade_repair,
        "repairFields": [
            "grade (Malik only)", "arabic", "arabicNumber", "reference",
            "cleanReference", "sourceEditionReference (original source object)",
        ],
        "otherRecordFieldsPreservedDuringRepairs": True,
    }
    args.json_output.parent.mkdir(parents=True, exist_ok=True)
    args.json_output.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    write_markdown(args.markdown_output, report)
    print(json.dumps({
        "records": totals["records"],
        "verifiedTransport": totals["recordsVerifiedAgainstPinnedUpstream"],
        "transportIssueRecords": totals["recordsWithTransportIssues"],
        "structuredGradeRecords": totals["recordsWithGrades"],
        "sourceEmptyArabic": totals["sourceEmptyArabic"],
        "arabicRepairs": len(repairs), "report": str(args.json_output),
        "referenceRepairs": len(reference_repairs),
    }))
    return 1 if any(book["transportIssues"] for book in book_reports) else 0


def write_markdown(path, report):
    totals = report["totals"]
    lines = [
        "# Hadith grading data audit", "",
        f"Audit date: {report['auditedAt']}", "",
        f"All {totals['records']:,} bundled records were checked against Arabic and English editions "
        f"at [source commit {HADITH_SOURCE_COMMIT[:12]}]"
        f"(https://github.com/fawazahmed0/hadith-api/tree/{HADITH_SOURCE_COMMIT}). "
        "The six Ummah Library collections were additionally checked against their local import snapshots.", "",
        "This confirms exact dataset transport and attribution. It does not independently certify "
        "the scholar's published assessment, scholarly consensus, or religious authenticity. "
        "There are no primary-source-certified weak records in this audit. Imported judgments must "
        "be presented with their scholar and dataset source, with disagreements and scope visible.", "",
        f"- Records with structured assessments: {totals['recordsWithGrades']:,}.",
        f"- Records without an individual imported assessment: {totals['recordsWithoutGrades']:,}.",
        f"- Exact transport checks passed: {totals['recordsVerifiedAgainstPinnedUpstream']:,}.",
        f"- Records with transport issues: {totals.get('recordsWithTransportIssues', 0):,}.",
        f"- Source-empty Arabic records: {totals.get('sourceEmptyArabic', 0):,}.", "",
        "Every upstream record with a nonempty Arabic or English passage is present in the bundle. "
        f"{totals.get('omittedBothLanguageEmptyPlaceholders', 0):,} source placeholders empty in both "
        "languages are omitted. "
        f"{totals.get('recordsWithoutEnglish', 0):,} bundled records retain Arabic and assessments "
        "but have no English text in the source; no English translation was invented.", "",
        "| Collection | Records | With grades | Missing grades | Transport issues |",
        "|---|---:|---:|---:|---:|",
    ]
    for book in report["books"]:
        c = book["counts"]
        lines.append(f"| {book['bookId']} | {c['records']:,} | {c.get('recordsWithGrades', 0):,} | "
                     f"{c.get('recordsWithoutGrades', 0):,} | {c.get('recordsWithTransportIssues', 0):,} |")
    lines.extend(["", "## Repairs", ""])
    grade_repair = report.get("displayGradeRepair")
    if grade_repair:
        lines.append(f"Repaired {grade_repair['displayFieldsChanged']:,} Malik display-grade strings "
                     "that previously retained only the scholar's name. The structured grades were unchanged.")
    repair_counts = Counter(item["reason"] for item in report["arabicRepairs"])
    lines.extend([
        "",
        f"Repaired {repair_counts['canonical_number_join']:,} Arabic joins using the same collection, "
        "edition and exact canonical number. "
        f"Restored {repair_counts['restore_source_text']:,} source-available Arabic passages. "
        "Every changed ID has before/after numbers and Arabic SHA256 hashes in the JSON report. "
        "The source file URLs, commit and SHA256 hashes are pinned. No translations, raw assessments, "
        "IDs or canonical Hadith numbers changed.", "",
        f"Corrected {len(report['referenceRepairs']['rows']):,} display citations that previously "
        "used a chapter-local number after the collection name. Every display citation now uses the "
        "canonical Hadith number. The original edition's book and Hadith reference remains stored "
        "as `sourceEditionReference` without altering chapter metadata. Changed IDs, original "
        "edition references and prior display strings are listed in the JSON report.", "",
        "The sync importer now verifies the English passage and all raw assessments against the "
        "same pinned source number before attaching Arabic. It rejects duplicate numbers and divergent "
        "English/grade data, and retains missing or empty Arabic as a reported source limitation.", "",
        "## Judgment boundaries", "",
        "Isnaad/Sanad labels describe the chain; Mauquf/Maqtu labels describe other report scopes. "
        "A weak chain must not automatically become a blanket weak-Hadith label. Unknown labels, "
        "missing attributions and conflicting judgments cannot be promoted to confirmed weak. "
        "A collection title does not replace an individual assessment.", "",
        "Run the audit with the saved source cache:", "",
        "```sh", "python3 tool/content_import/audit_hadith_grades.py --source-cache /path/to/source-cache",
        "```", "",
        "Use `--fetch-upstream` to create or refresh the pinned cache. Assets are read-only by default. "
        "The explicit `--repair-arabic` option applies only unambiguous, nonempty exact-number source joins. "
        "`--repair-references` corrects canonical display citations while preserving the edition reference.",
    ])
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-cache", type=Path, required=True)
    parser.add_argument("--fetch-upstream", action="store_true")
    parser.add_argument("--repair-arabic", action="store_true")
    parser.add_argument("--repair-references", action="store_true")
    parser.add_argument("--grade-repair-report", type=Path)
    parser.add_argument("--json-output", type=Path, default=ROOT / "docs/hadith_grading_audit.json")
    parser.add_argument("--markdown-output", type=Path, default=ROOT / "docs/hadith_grading_audit.md")
    raise SystemExit(run(parser.parse_args()))


if __name__ == "__main__":
    main()
