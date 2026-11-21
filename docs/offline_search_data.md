# Offline search corpus and development tools

The bundled index covers the complete local reader corpus: **6,236 Quran verses,
36,108 reader-visible Hadith, 287 Azkar, 99 divine names, 6,236 bundled Tafsir
Al-Muyassar entries, and 114 surah navigation records**. Each source has
precomputed 384-dimensional vectors for its actual available source languages.
Downloaded editions and personal content are indexed separately on the device.
Search retrieves existing text and does not generate religious answers,
translations, interpretations, or rulings.

The app-wide provider, local overlay, context, and update lifecycle are described
in [`app_search_architecture.md`](app_search_architecture.md). The current
physical-device harness runs the integrated app repository and writes
`app_search_benchmark.json` in app support storage, recorded as
`docs/app_search_ios_benchmark.json`. Its report includes corpus counts and
pending indexing documents. The older `offline_search_ios_benchmark.json`
remains historical POC evidence.

## Source formats and coverage

| Source | Local format | Available content |
| --- | --- | --- |
| `assets/data/quran/qpc_hafs.json` | Array of `[original Arabic text, one-based global verse number]` | 6,236 verses |
| Resolved `quran_with_tafsir` package | `lib/data/meta/surah_metadata_list.dart`, `lib/data/quran/english/surah_1.dart` through `surah_114.dart` | 114 surah metadata records; all 6,236 English Saheeh International translations |
| `assets/data/hadith/manifest.json` | Book metadata including slug, name, order, edition catalogs | 10 imported books |
| `assets/data/hadith/books/<slug>.json` | `hadiths` array, `chapters` array, provenance | 36,108 raw Hadith records |
| `assets/data/hadith/visibility.json` | Per-book canonical IDs and text-availability counts | 36,108 reader-visible records across 10 books |
| `assets/data/azkar/manifest.json` and `categories/*.json` | Category metadata and exact Arabic/English reader items | 287 Azkar across 11 categories |
| `assets/data/worship/asma.json` | Arabic name, transliteration, English meaning, recorded references | 99 divine names |
| Resolved `quran_with_tafsir` package | `lib/data/tafsir/arabic/tafsir_1.dart` through `tafsir_114.dart` | 6,236 verbatim Arabic Tafsir Al-Muyassar entries |
| Resolved `quran_with_tafsir` package | `lib/data/meta/surah_metadata_list.dart` | 114 surah names, verse counts, and revelation types |

Quran IDs are `quran:<surah>:<verse>`. Hadith IDs are the existing
`hadith:<book>:<hadithNumber>`, used directly for reader navigation. The canonical
identifier is the deduplication key across languages and token chunks.

The Quran package is located through `.dart_tool/package_config.json`; run
`flutter pub get` before indexing. Its Dart data literals are read without
evaluating code. Quran Arabic is taken from the app's QPC Hafs asset, rather than
reconstructed from translation or search text. Original Arabic, English text,
and recorded references are stored unchanged, including source verse markers.
Bundled Tafsir Al-Muyassar is indexed separately as published commentary.
Its package README attributes the text to King Fahd Complex. The exact
commentary stays in `body` with language `ar`, rather than in the original
Quran Arabic field. No commentary is generated. Quran verses and commentary
retain distinct canonical identities and source labels.

The imported Hadith visible counts are: Abu Dawud 5,272; Bukhari 7,580; Dehlawi
40; Ibn Majah 4,340; Malik 1,829; Muslim 7,360; Nasai 5,679; Nawawi 42; Qudsi 40;
Tirmidhi 3,926.

The reader and search retain every record with nonempty Arabic or translation.
Weak, disputed, scoped, and ungraded records are readable and keep their original
source assessments. The indexer recomputes text availability for every imported
record and verifies exact agreement with version 2 of `visibility.json`. It
stops on disagreement or duplicate IDs. Display eligibility does not authenticate
a narration, and a narration marker does not establish authenticity.

Original grades and scholar names are preserved without replacing them with an
inferred grade. Imported named assessments are attributed reports, not a claim
of independent verification. The shared grading model distinguishes whole-report
grades from chain-only or partial-text grades and preserves differing opinions.
Daily suggestions use a separate conservative policy: a clear attributed
Sahih/Hasan whole-report assessment or eligible Bukhari/Muslim collection context.
Missing individual grades stay identified as missing, including Nawawi and Qudsi.
Downloaded Hadith search snapshots carry a grading presentation revision so
existing installs rebuild assessment metadata without modifying downloaded text
or stored grades.

Some imported Hadith `reference` strings use the edition's chapter-local Hadith
number, while `hadithNumber` is the collection-wide canonical number. The
importer in `tool/content_import/sync_ummah_hadith.py` retains the chapter number
as `bookNumber` and creates the recorded label from `reference.hadith`. Such
labels can repeat across chapters. The original label remains stored unchanged.
Exact human aliases use collection name plus canonical collection-wide number,
and canonical/slug IDs remain unambiguous. For example, `Sahih al-Bukhari 1`
resolves to `hadith:bukhari:1`; the same recorded label on another chapter's item
does not create an alias to that other item. Displaying canonical IDs alongside
recorded labels preserves both identities.

The immutable base index contains Arabic and English. Optional Azkar packs
(ar, ur, fa, ru, ckb, ckb-badini), downloaded Quran/Hadith editions, and other
device-local sources belong to the writable search overlay. Their availability
and removal follow the content provider, rather than the bundled base database.
Hadith manifest catalogs alone do not make an edition available for indexing. Urdu queries use
the multilingual model against existing Arabic/English vectors. No Urdu source
text is manufactured. Optional additional editions must be actual, reviewed
local exports with source attribution and appropriate redistribution rights.
Runtime translation caches with expiration policies should not be silently
converted into permanent bundled search content.

Existing attribution manifests are retained in the corpus fingerprint:
`assets/data/content_sources/quran_sources.json` and
`assets/data/content_sources/hadith_azkar_sources.json`. The Quran manifest records
`review_required` redistribution status and edition-specific rights. Existing
source review remains necessary before distributing an expanded corpus.

## Rebuilding

Use Python 3.10 or newer. The dependencies are pinned in
`tool/offline_search/requirements.txt`.

```sh
python3 -m venv /tmp/quran-offline-e5-env
/tmp/quran-offline-e5-env/bin/pip install -r tool/offline_search/requirements.txt
/tmp/quran-offline-e5-env/bin/python tool/offline_search/build_index.py
```

The builder requires the already downloaded pinned `model.int8.onnx` and
`tokenizer.json` in `assets/offline_search/`. It makes no network requests. Model
identity is `intfloat/multilingual-e5-small`, upstream revision
`614241f622f53c4eeff9890bdc4f31cfecc418b3`. The ONNX artifact is the upstream
INT8 model; its exact SHA-256 is stored in both SQLite metadata and the artifact
manifest. Document and query inference must use matching model/tokenizer hashes,
384 dimensions, max length 512, normalization version 1, and masked mean pooling
with L2 normalization.

To reproduce the model download during development, run
`python tool/offline_search/prepare_model.py`. This downloads approximately
135 MB from the pinned official revision, streams to temporary files, and
checks exact byte sizes and SHA-256 before replacement. It reuses already
verified local files. The upstream INT8 ONNX export was available, so an
additional conversion or quantization step was unnecessary. Its filename
mentions AVX512, but inspection found only portable standard ONNX opset 11
operators, including `DynamicQuantizeLinear` and `MatMulInteger`.

The default build indexes all 114 Quran chapters, every reader-visible Hadith,
all bundled Azkar and divine names, bundled Tafsir, and surah metadata. Optional nonzero `--quran-limit` and
`--hadith-limit` values reproduce deterministic smaller development samples.
Full corpus defaults are equivalent to:

```sh
/tmp/quran-offline-e5-env/bin/python tool/offline_search/build_index.py \
  --quran-limit 0 --hadith-limit 0
```

Long passages are split into 512-token windows with 64-token overlap. Each window
retains the E5 `passage:` prefix and XLM-R boundary tokens. Each available language
is embedded separately. The full original passage is retained for display.
SQLite stores normalized float32 little-endian vector blobs for exact cosine
retrieval in a background worker. FTS5 has Unicode tokenization and prefix
indexes. Canonical results aggregate the maximum similarity over their windows
and languages, then combine keyword and semantic ranks with RRF constant 60.

The build is staged under `.dart_tool/offline_search`, outside Flutter's
bundled asset directory, checked for integrity and
unresolved foreign keys, and atomically replaces the previous database after
completion. The manifest records model/tokenizer/database/parity hashes and
sizes. All source files are fingerprinted in database provenance. A failed build
does not replace the previous finished database. Embeddings are cached under
`.dart_tool/offline_search/embedding_cache.sqlite`, keyed by model/tokenizer
hashes, pooling contract, and exact token IDs. Unchanged sources, duplicate
chunks, and interrupted rebuilds reuse cached vectors. This cache is a build
artifact and is not bundled in the app. The first expanded build can seed it
from unchanged vectors in the existing database. Bounded batches group similar
sequence lengths to reduce padding overhead.

For a reviewed local translation JSONL export, pass `--translations <path>`.
Each line must contain exactly `canonical_id`, `language`, `text`, and `source`.
Targets must already exist in the visible corpus. Original Arabic cannot be
overridden, and duplicate language/source editions are rejected. The export must
be reviewed before inclusion; the tool checks structure and provenance, not
religious or licensing correctness.

The optional precomputed download-pack contract is documented in
[`offline_search_language_packs.md`](offline_search_language_packs.md). It
describes how verified edition downloads can provide matching vectors while
retaining on-device indexing as a fallback.

## Tests and evaluation

```sh
/tmp/quran-offline-e5-env/bin/python -m unittest discover \
  -s tool/offline_search/tests -v
/tmp/quran-offline-e5-env/bin/python tool/offline_search/benchmark.py \
  --output tool/offline_search/host_benchmark.json
```

The tests check real-source counts and byte-exact Arabic preservation,
reader-visible IDs, deterministic coverage, exact aliases, SQLite integrity,
multilingual tokenization/inference, finite unit embeddings, complete long
passage chunks, mask/padding invariance, no-network query inference, and metric
formulas. The generated parity fixture includes Arabic, Urdu, English, Roman
Urdu, combining accents, compatibility forms, unknown characters, literal
special tokens, emoji, Unicode whitespace, and truncation at 512 tokens.

Retrieval quality needs human-verified judgments. `evaluate.py` computes
Recall@10, Precision@10, MRR@10, and nDCG@10 for keyword, semantic, and hybrid
search, including separate language aggregates. It requires a qrels JSON file
with a nonempty `verified_by` field and queries containing `id`, `text`,
`language`, and `relevance` mapping canonical IDs to nonnegative integer grades.
It rejects judgments outside the indexed corpus. It never creates judgments.

```sh
/tmp/quran-offline-e5-env/bin/python tool/offline_search/evaluate.py \
  --qrels /path/to/reviewed-qrels.json --output /path/to/retrieval-report.json
```

No verified qrels were supplied for this implementation, so no retrieval-quality
metric is claimed. Roman Urdu and short natural-language queries need separate
review. The model's ranked source IDs are smoke evidence, not proof of relevance
or religious authority. RRF can lower a semantically useful result when its
keyword rank is poor; tune weights only against reviewed judgments.

## Recorded measurements

The original iPhone and native-host reports below used the **1,500-passage
proof of concept**, not the expanded corpus. They remain historical evidence
and must not be cited as full-corpus performance. Full-corpus host results are
saved separately in `docs/offline_search_full_host_benchmark.json`.

The initial real POC embedding build took approximately 162 seconds on the
development Mac. `tool/offline_search/host_benchmark.json` contains reproducible
host CPU measurements and actual returned IDs. The Python baseline measured
approximately 0.06-0.29 ms median keyword retrieval, 1.8-2.2 ms short-query
embedding, 0.6-0.7 ms vector scanning, and 2.6-3.1 ms total natural-language search.
Exact references bypass embedding. These numbers measure the Python development
baseline, not Flutter or a representative smartphone.

The Python baseline process peaked around 0.79 GB RSS. A separate phase check
measured approximately 43 MB after imports, 448 MB after the Hugging Face Rust
tokenizer was loaded, and 754 MB after adding the ONNX Runtime session. The
benchmark does not load all 36,108 Hadith source records. Flutter's tokenizer and
runtime memory behavior differ and require independent measurement.

The physical iPhone profile report is saved in
`docs/offline_search_ios_benchmark.json`. It passed semantic inference in all
four query languages, exact and missing citations, and source filters across
five trials per query. Median warm searches took 6-8 ms, including 2-3 ms
embedding and 3-4 ms vector scans. First initialization took 1,107 ms. The
benchmark app used approximately 483 MB RSS after initialization and peaked
around 490 MB. That memory remains material for mid-range devices; this is not
a low-memory acceptance result. The recorded OS is iOS 27.0, and the test used
the connected physical iPhone in profile mode.

Actual Android-device latency, representative mid-range iOS behavior, long
queries, battery use, airplane-mode operation, and low-memory handling remain
unaccepted. The full corpus and additional local translation editions need their own
physical-device performance and reviewed relevance validation before release. Native-device timing success does not establish retrieval quality.

## Extensible database contract

`metadata.schema_version` is `2` for the lossless packed storage layout. Runtime
readers also accept legacy schema `1` indexes. Nullable passage columns preserve
the original Quran/Hadith payloads.
`passages.kind` is unrestricted so new content providers can add source types.
All existing source columns and vector encoding remain compatible.

`vector_entries` retains each vector ID, passage ID, language, and chunk index,
with a block ID and byte offset. `vector_blocks` stores up to 128 concatenated
384-dimensional float32 vectors. No values are rounded or recomputed. The
`vectors` compatibility view exposes each original 1,536-byte embedding for
existing host tools. The runtime reads bounded blocks directly, preserving
vector iteration, cosine arithmetic, and ranking tie breaks. The writable
private overlay keeps its existing embedding identity and does not reindex
personal content merely because bundled storage changes.

The bundled FTS5 index is contentless. Tokenization, prefix indexes, token
positions, document lengths, and BM25 remain unchanged; display text stays in
`passages`. Original book assets also reconstruct the legacy Hadith search
records through `assets/data/hadith/search_index.compact.json`. The original
JSONL is retained as local import provenance but excluded from Flutter assets.
Import scripts regenerate the compact asset and verify exact reconstruction.

To losslessly upgrade an existing schema 1 database, retain an independent
baseline outside bundled assets and run `tool/offline_search/optimize_storage.py`
with `--baseline`, `--output`, and `--apply`. The converter compares every source
row and float32 byte, every FTS token position and document length, and complete
rankings and BM25 values for representative expressions. It retains rollback
files outside bundled assets. New builds emit schema 2 directly.

| Added passage column | Meaning |
| --- | --- |
| `body TEXT` | Exact primary content for sources without Arabic |
| `route TEXT` | Local app destination for the original content |
| `language TEXT` | Language of `body`, when present |
| `source_label TEXT` | Recorded source/provider attribution |
| `is_user_content INTEGER NOT NULL DEFAULT 0` | Distinguishes personal content from published reader sources |
| `metadata_json TEXT NOT NULL DEFAULT '{}'` | Provider-specific stable identifiers and context |

Azkar IDs use the reader's `azkar:<category>:<item>` identity and navigate to
`/library/azkar/<category>?item=<encoded-id>`. Metadata retains category, repeat
count, transliteration, notes, and benefits. The original reference remains
unchanged. Divine names use `divine_name:<number>` and
`/worship-tools/names`, retaining the dataset's source attribution. Empty
references remain empty; no Quran or Hadith citation is invented.

Bundled Tafsir IDs are `tafsir:bundled:<surah>:<ayah>` and open
`/quran/<surah>?ayah=<ayah>&tafsir=bundled`. Exact verse aliases can return both
the Quran verse and its separately labeled commentary when searching All;
source filters narrow those results. Surah navigation IDs are `surah:<number>`
and support actual Arabic/English chapter names and chapter numbers. Divine
names use explicit navigation aliases so a broad topic such as Allah still
uses source retrieval. Original recorded references are included in FTS text
without making ambiguous Hadith chapter-local labels exact aliases.

The immutable bundled database is rebuilt when shipped content changes.
Downloaded translations and personal content belong in a separate writable
overlay, associated with their provider and canonical source, so changes and
deletions can update the search index without altering published text.

## Bundled corpus validation history

Before the grading display update, the completed database contained 43,742
passages and 91,272 vectors and was
373,276,672 bytes. The first complete Quran/Hadith/Azkar/name build took
2,232.623 seconds on the development host. Adding the bundled tafsir and surah
records reused 84,822 vectors and took 74.812 seconds. These are build times,
not phone search times. Build counts, hashes, staging checks, and timing evidence
are recorded in `docs/offline_search_full_build_report.json`.

All 13 pipeline checks passed after that earlier build. They verify source
preservation, reader visibility, exact aliases, tokenizer contract, SQLite
integrity, and every vector's finite values and unit norm. Every shipped
artifact's size and SHA-256 were checked against the manifest. No in-progress
database or SQLite journal remains inside the bundled asset directory.

`docs/offline_search_full_host_benchmark.json` records five trials for nine
queries against the full corpus: initialization was 720.346 ms, and natural
query median end-to-end times ranged from 36.16 to 57.39 ms. The Python process
peaked at 1,248,444,416 bytes because it loads all vectors into NumPy arrays.
These host measurements do not represent the bounded Flutter vector scan or
phone memory use. The current integrated physical-device report is documented
in `app_search_architecture.md`.

Quality smoke observations are in `docs/offline_search_full_smoke.json` and
`docs/offline_search_embedding_diagnostics.json`. Base semantic-only results
remain weak for several natural queries, especially Roman Urdu. Short isolated
Arabic fragments can rank above more useful source passages. Fresh-vector
checks and a temporary official FP32 comparison reproduced that behavior, so
changing precision alone does not fix it. INT8 embeddings vary slightly with
batch composition; controlled FP32 batching produced identical embeddings.
No calibration, language suppression, or unverified precision change was
applied. The integrated app's general query vocabulary and lexical reranking
must be assessed separately from these base semantic-only observations.
A separate 25-query probe of the shared multilingual vocabulary is saved in
`docs/offline_search_vocabulary_probe.json`. It uses the actual Dart keyword and
coverage functions, the unchanged base semantic query, 75 candidates per
method, and equal-weight RRF with constant 60. Topic expansion brought existing
grief/anxiety Azkar into the leading Urdu and Roman Urdu worry candidates,
parent-care passages into the English parents query, and anger-management
Hadith into the Arabic anger query. These are qualitative source observations,
not reviewed relevance labels or claims about every language.

The probe also exposed remaining limits: ambiguous Arabic words and incidental
matches in long narrations can dominate lexical coverage, while unrecognized
phrases such as losing a loved one remain weak. A trial additional
`0.02 * coverage` score suppressed semantic fragments but wrongly promoted a
pumpkin-meal narration over the before-eating Azkar. That additional score was
rejected. The app keeps bounded topic expansion, informative-word filtering,
coverage within the lexical ranking, and ordinary RRF. The report covers only
the immutable base; app feature providers, personal context, and downloaded
editions require their integrated measurements. No Recall, Precision, MRR, or
nDCG claim is made without reviewed judgments.

## Original POC implementation and validation

The details and acceptance counts in this historical section describe the
initial POC. App-wide integration and the expanded corpus require their own
validation results.


Existing app architecture is retained: GetIt dependency registration,
Bloc/Cubit presentation state, go_router navigation, the existing source
readers, and Hive user preferences/content caches. Existing keyword search
across notes, tafsir, azkar, and downloaded content remains accessible. Its
search page now has an action opening the separate offline source-search page
at `/offline-search`. This page submits explicitly, supports All/Quran/Hadith,
shows unchanged Arabic plus an available translation, preserves grades and
recorded references, and opens the original reader by canonical ID.

`LocalOfflineSearchRepository` is an app-scoped singleton. A persistent isolate
owns SQLite, tokenizer, and the ONNX session. Query tensors are int64; attention
masks exclude padding from mean pooling and pooled output is L2 normalized.
Session CPU inference uses two threads and is initialized once. Native tensors
are released after every run and native session/database resources are closed
on shutdown. Startup and shutdown are bounded; repeated submissions have a
bounded queue, and stale UI responses are rejected. Model failures produce an
explicit keyword-only warning instead of silently claiming semantic search.

Android native asset preparation streams bundled files to a versioned cache
using a background executor and atomic temporary files. iOS returns direct,
read-only paths inside App.framework, avoiding duplicate model copies and
large platform-message transfers. The worker verifies each packaged artifact's
hash/size and checks database/model/tokenizer version identity before opening
the search engine. Android minimum API is 24 because that is required by the
selected ONNX native binaries; the existing iOS minimum remains 15.0.

The tokenizer uses the pinned Hugging Face JSON's precompiled normalization,
Metaspace boundaries, added tokens, Float64 Unigram scoring, unknown handling,
and BOS/EOS-preserving truncation. A compact packed vocabulary is approximately
6.8 MB. This avoids retaining the third-party tokenizer's large object trie.
The implementation passed all 17 pinned golden cases and 178 additional
development parity checks. Every startup verifies the bundled golden cases.

The compatible package versions are `onnxruntime_plus` 1.5.0 and `sqlite3` 3.5.2.
The latter bundles FTS5 through native asset hooks and avoids this Flutter SDK's
dependency conflict with newer SQLite packages. The ONNX package uses 1.22.0
on Android and 1.15.1 on CocoaPods iOS/macOS. Real macOS FFI query embeddings
matched the Python indexing runtime 1.22.0 with cosine similarity over 0.99999,
and their top-ten vector candidates agreed.

Exact Quran citations, Arabic/Persian reference digits, canonical Hadith IDs,
and collection-number aliases bypass approximate retrieval. Missing recognized
citations return an empty result with a source-filter/sample notice. Canonical
deduplication occurs before RRF, including all language/chunk vectors. The
default retrieves 75 candidates per method and uses constant 60 with equal
weights. `OfflineSearchConfig` exposes candidate count, weights, batch size,
and inference threads. Vector scans use bounded batches of 256 float32 blobs
and exact cosine dot products; no native SQLite vector extension is required
for this POC. Full-corpus scans require their own device measurements.

Validation commands:

```sh
flutter analyze --no-pub
flutter test --no-pub test/features/search/ \
  test/features/quran/presentation/quran_search_bloc_test.dart test/core/
flutter build apk --debug --no-pub
flutter run --profile --no-pub -d <physical-device-id> \
  -t tool/offline_search_device_benchmark.dart
```

The native host test loads the ONNX package's actual macOS library because
Flutter's test host does not link CocoaPods. It uses the real model/database,
blocks HTTP, checks all four query languages, RRF, canonical deduplication,
filters, exact references, query/index embedding parity, and persistent worker
startup/shutdown. 41 new/existing Flutter search checks and 13 Python source,
index, and model checks passed. Both Android debug and iOS profile builds
compiled successfully. `docs/offline_search_native_benchmark.json` records
host-core timings and test-process memory, which include a JIT test host and
must not be treated as representative smartphone results.

For physical-device benchmarking, the standalone entry point writes
`offline_search_benchmark.json` in the app support directory and emits one
development log. It runs five trials per query and verifies semantic inference,
exact citations, missing references, and source filters. Run with airplane mode
or otherwise disabled network to measure fully disconnected operation. After
using that entry point, restore/install the regular `lib/main.dart` build.
No simulator is needed. Use real mid-range Android and iOS devices for final
latency, peak RAM, battery, and low-memory acceptance.
