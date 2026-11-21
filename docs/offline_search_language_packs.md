# Precomputed search packs for downloaded editions

The current device index can embed downloaded text locally after its content
provider reports it available. This document defines the next optional delivery
optimization: ship reviewed translations with precomputed search vectors, so a
language download can become semantically searchable without running thousands
of passage embeddings on the phone. The precomputed-pack downloader/importer
described here is an extension contract, not a separately deployed service.

## Source identity

A search pack belongs to one exact edition and revision, not just a language.
Two Urdu editions may have different text, attribution, and retrieval vectors.
Use the runtime provider's stable `sourceId` together with its edition ID and
the SHA-256 of the verified translation payload. Preserve canonical Quran,
Hadith, and Azkar IDs so multiple languages produce one original-source result.

The immutable base currently contains Arabic/English for all 6,236 Quran verses,
30,770 reader-visible Hadith, 287 Azkar, 99 divine names, 6,236 Arabic Tafsir
Al-Muyassar entries, and 114 surah navigation records. Optional language
packs do not replace its original Arabic, reference strings, or recorded grades.
Hadith targets must remain reader-visible under the current app policy.

The app's provider boundary is `SearchContentSource`: `id`, `revision`, and a
stream of document batches. Each `SearchDocument` supplies `id`, `passage`,
`text`, and `language`. The registry lives in
`lib/features/search/data/sources/app_search_sources.dart`; content changes
notify `LocalSearchRevision.changed(source: sourceId)`.

Persisted source revisions use `store-v4:<SHA256>` over actual local snapshots,
with streamed scalar hashing and reuse until the next process mutation.
Completed overlay revisions allow unchanged providers to be skipped across
launches. Expiring providers retain their next expiry deadline. Increment the
adapter/schema version when output structure, source coverage, or visibility
policy changes, even if stored text is unchanged. Older overlays using session
nonces require one synchronization when migrating to stable revisions. Bundled
Azkar packs use a versioned stable revision for their source assets.

Current edition identity examples:

| Provider source ID | Search document ID | Canonical result ID |
| --- | --- | --- |
| `quran-translations` | `translation:<resourceId>:<surah>:<ayah>` | `quran:<surah>:<ayah>` |
| `tafsir` | `tafsir:<resourceId>:<surah>:<ayah>` | Same as document ID |
| `hadith-translations` | `<existing-hadith-id>:translation:<language>` | Existing Hadith ID |
| `hadeethenc` | `hadeethenc:<language>:<id>` | `hadeethenc:<id>` |

`sourceId` scopes a provider snapshot and may cover multiple editions. The
pack's edition ID therefore supplements the source ID; installing one pack
must not replace other editions from that provider. Quran translation metadata
retains `translationResourceId`; tafsir retains `tafsirResourceId` and
`verseKey`. Expiring Quran Foundation content follows its existing cache expiry
and is resynchronized when it expires.

## Artifact contract

Publish the edition's existing downloadable text plus an optional search pack.
The pack is a data artifact; it contains no executable code or new app routes.
Keep route construction in the provider that already knows how to open the
downloaded content.

The manifest needs these fields:

| Field | Validation |
| --- | --- |
| `format`, `format_version` | Known pack format and parser version |
| `source_id`, `edition_id`, `language`, `content_revision` | Exact installed content identity |
| `content_sha256` | Matches the verified original text download |
| `model_id`, `model_revision`, `model_sha256`, `tokenizer_sha256` | Matches the bundled query encoder |
| `dimensions`, `max_length`, `normalization_version`, `pooling`, `vector_encoding`, `chunk_overlap` | 384, 512, 1, `attention_mask_mean_l2`, `float32_little_endian`, 64 |
| `document_count`, `vector_count` | Matches imported records and vector rows |
| `files` | SHA-256 and byte length for each pack file |
| `attribution`, `source_url`, `rights` | Edition's existing source and redistribution information |

Each document record has a canonical target ID, exact translated text,
language/edition attribution, and a text digest. Each vector has the matching
document ID, language, chunk index, input digest, and 384 finite float32 values.
Long text uses the same `passage:` prefix and 512-token windows with 64-token
overlap as `tool/offline_search/build_index.py`. Preserve complete text for
display. Do not truncate the displayed translation to the embedding window.

Build vectors with the pinned E5 model and tokenizer used by the app. The
existing Python extraction/build code, text normalization, and persistent
embedding cache provide the common embedding contract. A pack build should
reuse that code rather than introduce a second tokenizer or pooling algorithm.

## Activation and update sequence

1. Download the edition using its existing content download manager. Validate
   its identity, source coverage, checksum, and actual saved text as usual.
2. Notify the edition's search provider after the text is available. Keyword
   indexing can begin immediately; the app remains usable during vector work.
3. If a matching precomputed pack is available, stage and verify it locally.
   Reject unknown targets, hidden Hadith, duplicate edition/chunk identities,
   incorrect dimensions, non-finite vectors, invalid norms, and incompatible
   model/tokenizer identities. A failed pack leaves the saved text available.
4. Import into the writable overlay in bounded transactions, associated with
   the provider source ID and exact content revision. Activate a completed
   snapshot atomically. Do not expose vectors for text from another revision.
5. If no compatible pack exists, use the existing local embedding queue.
   Persist progress and reuse unchanged text vectors on retries. The user
   should see indexing progress when a large download is still being prepared.
6. On content removal, remove that provider snapshot and its vector/FTS rows.
   Other editions and the immutable base remain available. On replacement,
   index the new content revision and retire the old snapshot after activation.

Cancelled downloads must never activate partial packs. Reconnecting the app
or repeating the download-complete event must be idempotent. A model update
invalidates incompatible vectors while retaining exact source text for keyword
search and background reindexing.

## Content that stays device-local

Personal notes, saved duas, journal entries, collections, and other user-created
content use the same provider/index update lifecycle but are embedded on the
device. They are not sent to a public language-pack build service. Timings and
other computed results use fresh provider data and expiry/revision handling;
they should not be frozen into translation packs. Adding a new content feature
requires registering its provider, stable IDs, change/removal notifications,
and navigation target.

## Acceptance evidence

Before enabling precomputed pack delivery, verify installation, replacement,
removal, cancellation, restart, and model-version mismatch with a real edition.
Check original text/reference preservation and canonical deduplication across
base and downloaded editions. Measure keyword-ready and semantic-ready times,
peak memory, and device storage for a full 6,236-verse language pack. Retrieval
quality still requires reviewed query-to-source judgments for that language.
