# Hadith grading data audit

Audit date: 2026-10-14T13:33:38.365789+00:00

All 36,108 bundled records were checked against Arabic and English editions at [source commit df57907be352](https://github.com/fawazahmed0/hadith-api/tree/df57907be35291c91ad6a6691180e22ca9920784). The six Ummah Library collections were additionally checked against their local import snapshots.

This confirms exact dataset transport and attribution. It does not independently certify the scholar's published assessment, scholarly consensus, or religious authenticity. There are no primary-source-certified weak records in this audit. Imported judgments must be presented with their scholar and dataset source, with disagreements and scope visible.

- Records with structured assessments: 21,001.
- Records without an individual imported assessment: 15,107.
- Exact transport checks passed: 36,108.
- Records with transport issues: 0.
- Source-empty Arabic records: 4.

Every upstream record with a nonempty Arabic or English passage is present in the bundle. 404 source placeholders empty in both languages are omitted. 11 bundled records retain Arabic and assessments but have no English text in the source; no English translation was invented.

| Collection | Records | With grades | Missing grades | Transport issues |
|---|---:|---:|---:|---:|
| abudawud | 5,272 | 5,272 | 0 | 0 |
| bukhari | 7,580 | 0 | 7,580 | 0 |
| dehlawi | 40 | 0 | 40 | 0 |
| ibnmajah | 4,340 | 4,338 | 2 | 0 |
| malik | 1,829 | 1,829 | 0 | 0 |
| muslim | 7,360 | 0 | 7,360 | 0 |
| nasai | 5,679 | 5,672 | 7 | 0 |
| nawawi | 42 | 0 | 42 | 0 |
| qudsi | 40 | 0 | 40 | 0 |
| tirmidhi | 3,926 | 3,890 | 36 | 0 |

## Repairs

Repaired 1,829 Malik display-grade strings that previously retained only the scholar's name. The structured grades were unchanged.

Repaired 53 Arabic joins using the same collection, edition and exact canonical number. Restored 74 source-available Arabic passages. Every changed ID has before/after numbers and Arabic SHA256 hashes in the JSON report. The source file URLs, commit and SHA256 hashes are pinned. No translations, raw assessments, IDs or canonical Hadith numbers changed.

Corrected 34,566 display citations that previously used a chapter-local number after the collection name. Every display citation now uses the canonical Hadith number. The original edition's book and Hadith reference remains stored as `sourceEditionReference` without altering chapter metadata. Changed IDs, original edition references and prior display strings are listed in the JSON report.

The sync importer now verifies the English passage and all raw assessments against the same pinned source number before attaching Arabic. It rejects duplicate numbers and divergent English/grade data, and retains missing or empty Arabic as a reported source limitation.

## Judgment boundaries

Isnaad/Sanad labels describe the chain; Mauquf/Maqtu labels describe other report scopes. A weak chain must not automatically become a blanket weak-Hadith label. Unknown labels, missing attributions and conflicting judgments cannot be promoted to confirmed weak. A collection title does not replace an individual assessment.

Run the audit with the saved source cache:

```sh
python3 tool/content_import/audit_hadith_grades.py --source-cache /path/to/source-cache
```

Use `--fetch-upstream` to create or refresh the pinned cache. Assets are read-only by default. The explicit `--repair-arabic` option applies only unambiguous, nonempty exact-number source joins. `--repair-references` corrects canonical display citations while preserving the edition reference.
