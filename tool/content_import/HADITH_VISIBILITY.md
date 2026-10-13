# Hadith visibility metadata

After importing or modifying bundled Hadith books, regenerate the compact
authenticity index from the repository root:

```sh
dart run tool/content_import/build_hadith_visibility.dart
```

Commit `assets/data/hadith/visibility.json` with the imported books. The generator
uses the same `HadithAuthenticityPolicy` as the reader. Library counts and search
use this metadata without parsing every book on startup. Individual book reads
still apply the policy independently.

This is filtering based on the source's recorded grades and narration text,
not an independent religious authentication of the corpus.
