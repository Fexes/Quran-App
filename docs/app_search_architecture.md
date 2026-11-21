# App-wide offline search

The default `/search` route combines local semantic retrieval, keyword search, exact references, personal content, feature navigation, and live calculated information. `/quran-search` and `/offline-search` remain compatible entry routes. The original reader/book lists retain their scoped filters.

## Content ownership

| Source | Search behavior |
| --- | --- |
| Complete Quran, bundled Al-Muyassar tafsir, Surah navigation, reader-visible Hadith, base Azkar, divine names | Development-generated SQLite FTS5 and multilingual E5 vectors bundled with the app. See `offline_search_data.md` for exact counts, provenance, and model fingerprints. |
| Downloaded Quran translations, tafsir, word meanings | Store snapshots added automatically after successful cache writes; edition identity and reader route preserved. Expired or removed entries are removed from search. |
| Hadith translation packs and downloaded HadeethEnc material | Local copies only, with original source references and the reader's visibility policy. |
| Notes, bookmarks, collections, plans, memorization, reading history, prayer/fasting records, audio download metadata | Private persistent search records, distinguished from Quran/Hadith source text. Edits, deletions, and backup restoration invalidate their own provider. |
| Tools and widgets | Searchable descriptions open the real app feature. The daily ayah provider refreshes its actual verse by calendar day. |
| Prayer times and calendar | Calculated at query time using actual date/location/settings. Explicit city names resolve through the offline city catalog; ambiguous or unknown places lead to city selection. These values are never stored as semantic facts. |

All inference remains on device. Downloading content still uses each feature's existing download flow; searching an available local copy needs no server or remote AI. Search retrieves source material and calculated app data, without generating religious answers or interpretations.

## Runtime structure

`AppSearchRepository` coordinates:

1. `AppSearchSourceRegistry`, a registry of independent `SearchContentSource` providers.
2. `LocalOfflineSearchRepository`, a single persistent background isolate owning the tokenizer, ONNX session, bundled index, and writable private overlay.
3. `LiveSearchSource`, which reads current app settings and computes timing/calendar results.

A provider declares a stable `id`, a cheap revision string, and an asynchronous stream of bounded `SearchDocument` batches. Documents have a stable representation ID, a canonical content ID, text for retrieval, a language, and a typed passage containing original text, attribution, grades, and navigation metadata.

Multiple translations of one verse share a canonical ID. Different editions retain separate representation IDs. Notes and other personal records retain their own canonical IDs, so a reflection is never silently presented as scripture.

## Changes and deletion

`LocalSearchRevision.changed(source: providerId)` is emitted after a successful store mutation. The coordinator debounces changes, synchronizes changed providers, and checks revisions again before returning results. Queries retry a bounded number of times if edits occur concurrently. Stable hashes of the actual persisted store snapshots allow unchanged sources to reuse completed index revisions after process restart. Hashes are cached until the source changes, and expiry-aware providers also invalidate when cache validity changes.

Provider synchronization is a complete snapshot for that provider, streamed in small batches. Each document fingerprint covers its payload, language, and search text. Unchanged documents keep their embeddings. Changed documents immediately lose their old vectors and update FTS. At successful snapshot completion, IDs absent from that snapshot are deleted, including aliases and vectors. The completed revision is invalidated inside each upsert transaction and recorded only in the successful completion transaction, preventing partial imports from being reused after a crash or restore. Failed snapshots are retried before the coordinator returns search results.

Register a future feature with `AppSearchSourceRegistry.register(source)`. Use the provider's revision key when its store changes. Unregistering schedules an empty snapshot, which removes that provider's private index entries. A new content format needs an adapter that supplies its real source text and destination; search does not scrape arbitrary widget trees or invent content for a feature.

## Background indexing

Bundled reference material is embedded during development. New local content without a matching prebuilt embedding is immediately available to keyword/reference search and queued for on-device semantic indexing. The screen shows a brief progress message while new records are being added.

The worker processes one passage window per scheduled indexing step, giving submitted queries time between jobs. Personal records and tools are prioritized ahead of bulk translation packs. Indexing pauses when the application leaves the foreground and resumes on return. Completed embeddings persist across launches; interrupted documents restart safely.

Local documents use the same E5 `passage:` prefix, 512-token windows, 64-token overlap, attention-mask pooling, and L2 normalization as the bundled encoder. Very long local text is first divided into overlapping windows of at most 8,192 UTF-16 code units, bounding tokenization work before inference and preserving the document tail. Queries use `query:` and retain the tokenizer's model-specific normalization.

Overlay embeddings are bound to the model revision, model SHA-256, tokenizer SHA-256, and indexing format. A changed identity clears incompatible vectors and queues them again, while preserving keyword access to the original local records.

Optional downloadable precomputed embeddings can avoid local bulk indexing. `offline_search_language_packs.md` specifies that future pack format; it is not a claim that a new pack server or importer has been deployed.

## Retrieval and navigation

Exact references are checked against bundled and local sources before similarity retrieval. This includes linked tafsir/personal records when those filters are selected. Missing known references return an empty exact result rather than unrelated passages.

FTS and cosine candidates are deduplicated by canonical content before applying candidate limits. The engine compares lexical coverage across the separate bundled and private FTS databases, then fuses keyword and semantic ranks using configurable reciprocal rank fusion, initially constant 60. Semantic scans operate on bounded vector batches rather than loading the full matrix into Dart memory.

Bundled schema 2 packs the original float32 bytes into blocks of 128 vectors
and uses contentless FTS5 to avoid duplicate indexed text. Schema 1 remains
readable. Storage conversion preserves vector IDs and order, source payloads,
all FTS tokens and positions, document lengths, and BM25. Model/tokenizer
identities, scoring, and the private overlay identity remain unchanged. The
legacy Hadith index is reconstructed from the same local book assets using a
verified compact normalization and ordering manifest, so its large duplicate
JSONL is no longer packaged. All required assets remain bundled for first-use
offline search.

`SearchQueryTerms` supplies a bounded, auditable vocabulary of English, Arabic, Urdu, and common Roman Urdu topic variants. It separates question framing from the requested topic and balances up to 24 keyword terms across recognized concepts. Keyword retrieval tries a bounded conjunction of the requested concepts before broad recall. Lexical evidence counts each topic once, includes proximity, and avoids rewarding repeated synonyms. For questions with at least two recognized concepts, the engine blends the original query embedding (65%) with a focused topic embedding (35%), retaining negation and conditions in the focus. Unknown vocabulary remains available to ordinary lexical and semantic retrieval. RRF remains the base ranking, followed by bounded topic-coverage and proximity adjustments.

`SearchQueryIntent` distinguishes explicit Quran, Hadith, tafsir, and supplication requests from app operations and personal records. Substantive religious questions retrieve source passages; requests to change settings or track fasting retrieve the relevant app feature. Live timing detection rejects normative questions, unsupported prayer types, and congregation-time requests. User-selected source filters take precedence over inferred scope.

The final result hydrates original Quran/Hadith Arabic, references, and grades from the bundled canonical record. A matching downloaded edition keeps its route and edition metadata. Translation selection and source navigation therefore remain connected. Personal/generated app records have an explicit personal-content identity and their actual destination.

## Search presentation

The fixed search composer has a filled search-icon action inside its trailing edge, a Search accessibility label and tooltip, keyboard submission, and a clear action. Horizontal source filters and question examples lead into a lazy result list. After retrieval, source chips show counts of returned references and omit sources with no hits. Selecting a source filters the current result set locally, preserving the other source counts; these counts are not estimated corpus-wide totals. Pre-query scope selectors remain available, and All can expand a scoped result set back to global search. Passage cards show attribution, original Arabic, the matched translation, source grades, and a contiguous excerpt around relevant terms. Expansion restores the complete source text; excerpts never paraphrase or generate an answer. Cards open the same edition that supplied the displayed match.

Live prayer results use clock/schedule cards; calendars show the calculated Gregorian and Hijri dates; app features show widget availability; the Tasbieh card uses the stored counter and target. These values come from structured provider metadata. Live results carry an absolute UTC refresh deadline, so the search cubit refreshes the submitted query at the next-prayer boundary or local midnight while preserving any unsubmitted draft. Foreground resume still refreshes the last submitted query.

## Evidence and limits

Automated checks cover tokenizer parity, multilingual query execution, exact references, canonical deduplication, native model parity, source snapshots, updates/removals/restoration, persistence, language navigation, long-document coverage, and live date/time behavior. Build and device measurements are recorded separately from retrieval-quality evaluation.

No reviewed relevance judgments have been supplied, so Recall@10, Precision@10, MRR@10, and nDCG@10 are not claimed. Roman Urdu quality remains a separate evaluation need. Natural-language retrieval can still rank an irrelevant passage highly; similarity is not religious authority.

The subsequent 24-question before/after diagnostic is recorded in `offline_search_question_diagnostic.json`. It shows improved source relevance for parental kindness, forgotten prayers, and anger questions across several languages, alongside remaining indirect-first results for some nuanced questions. On the local Mac, the scoped Hadith query median fell from 1,686 ms to 164 ms after correcting SQLite vector join order. These are single diagnostic runs per query, not phone latency percentiles or independently reviewed accuracy scores.

The full-corpus diagnostic identified poor raw semantic rankings for some conversational queries, especially short scripture fragments. Fresh vector checks and the official full-precision model reproduced this behavior, so no unproven model-precision or vector-calibration change was shipped. The multilingual lexical vocabulary improves topic retrieval alongside the semantic candidates. See `offline_search_embedding_diagnostics.json` for the diagnostic evidence; broader relevance review is still required.

Audio files are searchable through their existing metadata, not through a newly added speech-transcription system. Live features use the data actually available locally; future content types must register a source adapter. Physical-device measurements only establish performance on the named device and corpus in each report.

Timing queries preserve the saved location and calculation settings. They do not infer a mosque's congregation time from the calculated prayer start time. City/time-zone handling also aligns the solar calculation with the requested civil date near the international date line.

## Initial app-wide integration validation, 14 October 2026

- Full Flutter suite: 280 passing checks. Final native engine suite: 13 passing checks; source/tokenizer/vocabulary changes also passed focused checks. Analyzer and diff checks are clean.
- Data pipeline: 13 passing checks; 43,742 packaged records and 91,272 vectors, with complete source coverage and artifact hashes verified.
- Android debug and normal iOS profile builds succeeded. No simulators were used. Android physical-device performance has not been measured.
- The normal `lib/main.dart` app was restored, launched, and confirmed running on the same iPhone after benchmarking.
- Integrated profile benchmark passed on Farhan's iPhone 17 Pro Max, iOS 27.0. The final corpus and actual app source registry were loaded. See `app_search_ios_cold_benchmark.json` and `app_search_ios_benchmark.json`.
- The migration snapshot took 12,064 ms. A fresh process reopening the saved index initialized in 4,253 ms. Query medians for the tested general searches were 175–296 ms; exact references were below the millisecond timer resolution, and the scoped fasting-tool query had a 10 ms median.
- Repeat-launch RSS was approximately 555 MB after initialization and peaked at 560 MB. This is one high-end phone's measurement, not an Android or low-memory-device guarantee.
- Downloaded material was immediately available to keyword/reference retrieval, while approximately 42,242 local records remained queued for semantic embedding at the end of the repeat check. After Search is first opened in a process, the normal app resumes that queue while in the foreground and pauses it in the background. The packaged corpus was already fully embedded.

The device checks validate execution, source navigation identifiers, live timings, and performance. They do not establish retrieval accuracy or replace review of the source passages. The broader 25-query vocabulary diagnostic is recorded separately in `offline_search_vocabulary_probe.json`.

## Search redesign validation, 14 October 2026

- The existing focused vocabulary, overlay, native engine, page, cubit, and app-source suites passed 55 checks in total. No new tests or simulators were added for this redesign.
- Scoped search analysis and diff checks passed. The normal iOS profile app built successfully.
- Physical review on Farhan's iPhone confirmed the in-field Search action, source filters, Quran cards with original Arabic and matched translations, and the calculated next-prayer card. The parents question surfaced Quran 17:23 first and 6:151 second; the next-prayer question displayed the saved location's actual calculated Asr time.
- This focused validation and the 24-question local diagnostic supplement the earlier integration checks. The complete Flutter suite and integrated device performance benchmark were not rerun for the presentation redesign.
- The follow-up search icon and counted source chips passed the existing 8 page and 7 cubit checks, scoped analysis, and an iOS profile build. Physical review confirmed the icon, hidden zero-result sources, and stable counts while switching from All 20 to Hadith 9 with Quran 4 still shown. A completed content refresh clears a selected facet when its last result disappears, preventing it from unexpectedly reactivating later.
