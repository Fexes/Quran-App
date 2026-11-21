# Hadith visibility metadata

After importing or modifying bundled Hadith books, regenerate the compact
display-availability index from the repository root:

```sh
dart run tool/content_import/build_hadith_visibility.dart
```

Commit `assets/data/hadith/visibility.json` with the imported books. The generator
uses the same `HadithAuthenticityPolicy` as the reader. Library counts and search
use this metadata without parsing every book on startup. Individual book reads
still apply the policy independently.

Version 2 includes every record with nonempty Arabic or translation, including
weak, disputed, scoped, and ungraded records. The reader and search display
original attributed assessments separately. Visibility is not independent
religious authentication of the corpus.
