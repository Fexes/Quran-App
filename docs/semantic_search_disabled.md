# Semantic search disabled for now

The app now packages a keyword and reference index separately from the preserved semantic package. SQLite remains available for FTS5, exact references, and the local content index. The ONNX Flutter dependency is removed. This is a reversible packaging change, not deletion of the original model or corpus.

## Bundled package

Only these search assets are declared in `pubspec.yaml`:

- `assets/keyword_search/manifest.json`
- `assets/keyword_search/search.sqlite`

The manifest and database identify `retrieval_mode=keyword`, `schema_version=3`, and `normalization_version=1`. The manifest retains corpus counts, languages, provenance hash, source policy, and the database size/SHA-256. Model, tokenizer, and vector metadata are omitted.

| Raw asset payload | Bytes |
| --- | ---: |
| Previous semantic directory | 463,717,865 |
| New keyword database | 165,048,320 |
| New keyword manifest | 852 |
| New combined package | 165,049,172 |
| Reduction | **298,668,693** |

The asset reduction is **284.83 MiB**. This excludes any additional native ONNX library savings and does not predict compressed store-download size.

## Rebuilding and verification

Run `python3 tool/offline_search/build_keyword_package.py`. The script verifies the original database against its manifest, opens it read-only, copies it, removes the vector view/tables and their indexes, updates metadata, and compacts the new database. The original package is never modified.

Verified during generation:

- Passages: **49,080 before and after**.
- FTS rows: **49,080 before and after**.
- Reference aliases: **225,725 before and after**.
- SQLite integrity and foreign-key checks pass; no vector objects remain.
- All four original semantic artifacts still match their original manifest hashes.
- Offline Flutter dependency resolution passed. Generated dependencies omit `onnxruntime_plus` and retain `sqlite3`.

New database SHA-256: `bb04986cd8aba8b53226ac02d5a5619e0f2e4e0ae0c6d1b533a258b9aa254b0e`.

## Native asset loaders

Android and iOS retain the `quran/offline_search_assets` channel, returning only `manifest.json` and `search.sqlite` from `assets/keyword_search/`.

Android extracts into `offline_search_bundle/<lastUpdateTime>-keyword-v3`, so an older semantic cache cannot be reused for the new payload. After successful preparation, it removes older numeric semantic cache directories and older named keyword cache directories. The Qibla, audio, and external-map handlers are unchanged by this switch.

## Restoration pointers

- Full original assets remain in `assets/offline_search/`, including the original database, model, tokenizer, parity data, notice, and manifest.
- Semantic Dart implementation snapshots are in `tool/semantic_search_disabled/` with `.dart.disabled` extensions. Existing semantic build/evaluation tools remain in `tool/offline_search/`.
- Restore the engine/database/embedder together from those snapshots, preserving any subsequent unrelated edits. The original semantic engine test is archived alongside them.
- Re-add `onnxruntime_plus: 1.5.0` and the intended original search asset declarations in `pubspec.yaml`, then regenerate dependencies and native build integration.
- Selectively change the two native search loaders back to the original asset path and five-file list: manifest, database, model, tokenizer, and tokenizer parity. Use a distinct cache identity for the restored payload. Do not revert the entire native files, which contain unrelated handlers and edits.

The original search assets and several semantic source files were not tracked by Git at the time of this change. Preserve these local restoration copies; do not rely on a blanket `git restore`.

Packaging checks did not run tests or simulators. Native build verification is handled separately after the keyword engine integration is complete.

## Final application verification

Full lib analysis and whitespace checks passed. Unsigned iOS build passed (311.5 MB app bundle); Android arm64 release build passed (130.5 MB APK). Both artifacts contain the hash-verified keyword database and exclude the semantic asset files and ONNX runtime. The iOS incremental output retains an empty old directory only, with no old files. Keyword queries and Quran 2:255 reference lookups returned the expected source records. Native device interaction was not run. No tests or simulators were run. Details are in `semantic_search_disabled_validation.json`.

The Learn tile corner-arrow block was removed; whole-card navigation and accessibility remain. Search copy now describes words and references, and no background semantic-indexing notice is shown.
