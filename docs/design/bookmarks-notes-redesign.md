# Bookmarks And Notes Redesign

Updated: 2026-10-12
Status: Implemented and locally verified; native device review pending.

## Bookmarks

- Unframed saved-ayah summary and a horizontal collection shelf with colors, icons, counts, selected state, and accessible actions.
- Search by Surah name, Arabic text, translation, or verse key. Collection and search filters compose without reloading content.
- Recently saved and Quran-order sorting. Counts always reflect the full saved collection, independent of the search.
- Readable verse previews with Arabic and translation, collection identity, exact-ayah opening, move sheet, and confirmed removal.
- Collection creation has named color swatches, icon selection, required-name validation, saving feedback, and inline failure recovery.
- Deleting a collection requires confirmation and retains its ayahs in the default collection using the existing repository behavior.
- Pull-to-refresh and refresh after returning from the reader preserve search, selection, and ordering. Refresh failures retain loaded content.

## Notes

- Reflection summary, clearable search, All/Ayahs/Personal filters with counts, date grouping, and recent/oldest sorting.
- Readable note previews, exact-ayah links, quick edit/menu actions, and a persistent new-note action.
- Editor retains the verse association and saves before closing. Storage failures keep the draft in the form with an error message.
- New notes reset filters so the saved result is visible. Returning from a linked ayah refreshes the list.
- Permanent deletion requires confirmation. Failed deletion leaves the note visible.

## Architecture And Files

| Responsibility | Files |
| --- | --- |
| Bookmark loading, filter/sort state, mutation gating, stale-load protection | `lib/features/quran/presentation/bloc/quran_bookmarks_cubit.dart`, `lib/features/quran/presentation/bloc/quran_bookmarks_state.dart` |
| Bookmark screen, collection shelf, previews, action sheets, confirmations | `lib/features/quran/presentation/pages/quran_bookmarks_page.dart` |
| Collection creation, known persisted icon mapping, dark-mode collection colors | `lib/features/quran/presentation/widgets/quran_bookmark_collection_sheet.dart` |
| Notes screen, local view state, filters, date grouping, store actions | `lib/features/quran/presentation/pages/quran_notes_page.dart` |
| Shared editor with optional asynchronous save callback and draft-preserving errors | `lib/core/widgets/note_editor_sheet.dart` |
| Shared translation direction and typography | `lib/features/quran/presentation/widgets/quran_translation_text.dart` |
| Existing persistence and contracts, unchanged | `lib/features/quran/data/stores/quran_user_data_store.dart`, `lib/features/quran/data/repositories/quran_repository_impl.dart`, `lib/features/quran/domain/repositories/quran_repository.dart`, `lib/features/quran/domain/entities/quran_bookmark.dart`, `lib/features/quran/domain/entities/quran_note.dart` |
| Existing route entry points and exact-ayah links, unchanged | `lib/app/router/app_router.dart`, `lib/app/router/app_routes.dart` |

The bookmark screen keeps its Cubit. `state.bookmarks` now retains all loaded summaries; `visibleBookmarks` derives the displayed collection/search/order without repository reads. Notes retains its existing screen-local state and store ownership rather than introducing an unrelated architecture migration. Data formats, default collection ID, note IDs, timestamps, and reader links are unchanged. Existing editor callers retain the pop-with-text API when no save callback is supplied.

## Bugs And Techniques

- Saved-content safety: replaced immediate note/collection deletion with confirmations, disabled duplicate mutations, caught write failures, and saved notes inside the editor before dismissing it. No undo promise is made for permanent note deletion.
- Async bookmarks: retain loaded content during refresh; ignore obsolete or post-disposal loads; revalidate collection selection after loading. Failed refresh and failed writes have distinct feedback.
- Translation direction: preview exposed bundled English text being treated as RTL because it contains decorative ayah brackets. Ignore only U+FD3E/U+FD3F during fallback direction detection; displayed text and explicit translation-resource direction remain unchanged.
- Layout: scrolling headers, wrapping note filters, scaling collection heights, bounded sheet contents, scrollable confirmations, and lightened collection accents in dark mode.

## Verification

- Focused static analysis and existing bookmark/store/route checks passed (9 checks).
- Existing reader and interlinear selected-RTL-translation checks passed (11 existing checks in total).
- Actual Flutter web preview uses bundled Quran content and the real repository with an isolated memory store. No user records are loaded or changed.
- Browser interaction review: bookmark search and collection filtering, collection creation/customization, moving bookmarks with updated counts, removal confirmation/cancel, note filtering, editing, and new-note save verified.
- Simulated note-storage failure left the full draft editable with an error and an enabled retry button. Confirmed English verse-marker translations render left-to-right after the shared fix.
- Layouts inspected at 390x844 and 320x740, including dark mode and 1.8x interface text.
- Final preview build and focused static analysis passed. Final browser checks after the accessibility/contrast changes reported no console errors. Temporary preview entry point and web scaffold removed after review.
- No dependencies, data migrations, localization expansion, new test files, simulator launches, or device installations.

## Next Review

- Verify keyboard, screen-reader navigation, and touch feel on a physical device with the final native build.
- Full native builds and full-suite regression checks were not run; verification was focused on the changed surfaces and existing related checks.
