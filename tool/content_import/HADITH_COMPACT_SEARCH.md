# Compact Hadith search asset

The app bundles `assets/data/hadith/search_index.compact.json` and reconstructs
legacy search records from the canonical book assets. Keep `search_index.jsonl`
on disk for content-import provenance and index-building tools, but exclude it
from Flutter assets.

After changing canonical books or the source JSONL, run from the repository root:

```sh
dart run tool/content_import/build_compact_hadith_search_index.dart
```

Both Hadith import workflows regenerate and verify the compact asset
automatically. No model inference or remote downloads are needed for this build.
The build verifies every source field and every visible search record, including
grading summaries and record order, using the same reconstruction code as the app.
The visibility metadata remains controlled by `build_hadith_visibility.dart`.

For read-only validation of existing assets:

```sh
dart run tool/content_import/build_compact_hadith_search_index.dart --verify-only
```

The compact asset stores the legacy normalization's compiled Unicode character
mapping and book order. Per-record overrides and ordering references are stored
only when they differ from the canonical books. Source and book hashes record
which inputs produced the compact asset. Runtime loading processes one book at
a time without retaining book-source strings, while reconstructed search records
use the same lifetime and scoring as before.
