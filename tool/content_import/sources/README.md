# Urdu Azkar Supplement

`azkar_urdu_supplement.json` supplies the 107 entries missing from the first Urdu import. It contains 50 exact normalized-Arabic records and 57 explicitly reviewed composite or narrated passages from the published Alharamain and Osoul Urdu editions.

The reviewed records retain source excerpts, locations, matching notes, and a SHA256 of the app's original Arabic. They are not fuzzy matches or joins by a publisher's entry number. The importer stops if the canonical Arabic changes or any entry loses coverage.

Osoul PDF page 72 was visually checked for the complete blessings-and-peace formula. Page 58 supplies the concluding consultation verse, avoiding a truncated sentence in the web edition. The longer tahajjud prayer omits only published optional clauses absent from the app's Arabic, as documented in its matching note.

Run from the project root with the previously downloaded 134 chapter HTML files and the morning/evening SQLite database:

```sh
python3 tool/content_import/import_azkar_urdu.py <source-directory> <morning-evening-database>
```

Output is the complete 287-entry offline Urdu pack, updated source metadata, and the multilingual search index. Original Arabic, item IDs, and repeat counts are not rewritten. Source matching has been checked during import; independent scholarly review is still recommended before release.
