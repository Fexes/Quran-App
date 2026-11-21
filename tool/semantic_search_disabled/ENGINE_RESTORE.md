# Paused semantic engine sources

Archived on 21 November 2026 before keyword-only search replaced the semantic worker. Every original file is preserved byte-for-byte, including the obsolete semantic-engine test. The `.dart.disabled` suffix keeps this restoration material out of active Dart analysis and compilation. Hashes and original paths are in `engine_archive_manifest.json`.

The original semantic asset directory remains `assets/offline_search/`; it is excluded from the app by the active asset declaration. Do not rely on Git restore for these originally untracked assets or sources.

To restore semantic search intentionally, first restore the archived source files to their recorded paths, restore the model package declaration and ONNX package dependency, and restore the matching native asset-loading contract. All three must change together. The active keyword package instead uses schema 3, retrieval_mode keyword, and only manifest.json plus search.sqlite.

The active LocalOfflineSearchRepository API and isolate lifecycle are retained. Exact-reference search, lexical ranking, filters, translation/grade enrichment and local source snapshots continue to use SQLite. Background embedding and model initialization are absent, semanticAvailable is always false, and pendingDocuments is zero. Source synchronization still commits keyword updates before results are returned.

Existing user overlay data remains in search_overlay.sqlite. The new keyword model identity clears only generated vector rows through the existing overlay migration, preserving document records and keyword indexes. The old generated desktop package cache can be removed after the replacement assets are prepared; it is separate from the user overlay.

Validation performed: formatting and analysis of the two active owned Dart files. No tests were added, written or run; no simulators were run. App packaging and native compilation are handled by the parent task.
