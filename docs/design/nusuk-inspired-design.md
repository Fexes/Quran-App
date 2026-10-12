# Nusuk-Inspired Quran App Design

Research date: 12 October 2026.

## Evidence And Limits

This review uses the Ministry of Hajj and Umrah's public Nusuk app listing, its published screenshots, and the official Nusuk website. It is a visual adaptation, not a claim that we inspected a logged-in Nusuk session, measured its private design tokens, or reproduced its animation engine.

Primary references:

- [Official Google Play listing and screenshot gallery](https://play.google.com/store/apps/details?hl=en_US&id=com.moh.nusukapp).
- [Official Apple App Store listing](https://apps.apple.com/ae/app/nusuk-%D9%86%D8%B3%D9%83/id6469515422).
- [Official Nusuk website](https://www.nusuk.sa/).

Six full-resolution gallery images were inspected: the home/prayer preview, the Quran preview, booking/service screens, the pilgrimage counter, discovery/category navigation, and the Islamic-content assistant preview. Screenshots show several different contexts; they do not establish that every Nusuk screen has one identical background or color palette.

No Nusuk logos, screenshots, proprietary illustrations, or unlicensed font files are bundled in this app.

## What Creates The Nusuk Feel

### 1. Quiet Typography

The inspected service and discovery screens use clean, relatively light headings, regular-weight supporting text, and a clearly subordinate metadata layer. Large serif headlines and very heavy labels are not the dominant pattern in those screens. Arabic remains an independent reading layer rather than decorative UI text. These are visual observations, not identification of Nusuk's exact font family. [Official service screenshot](https://play-lh.googleusercontent.com/_beSl-_HavI71nMikGJaYroQLu8ph3TtVu-RlplHVzwzh6HolUpfiTbQmWSBEUDNfFFTWYA_OAD-bOgDkCsB=w1200).

Adaptation: use licensed Manrope for interface text with an Arabic fallback, medium-weight screen titles, smaller secondary descriptions, and zero letter spacing. Manrope is a visual approximation, not a claim about Nusuk's private font. Keep Quran Arabic script choices, font-size preferences, and translation direction logic.

### 2. White Surfaces And Selective Color

The booking and discovery previews use predominantly white content surfaces against a very light neutral backdrop. Dark foreground text establishes hierarchy. Gold appears in sacred-content symbols and highlights; green appears in status/contextual elements. The home and pilgrimage previews also contain dark immersive areas. A single beige or purple theme would therefore misrepresent the reference. [Official home screenshot](https://play-lh.googleusercontent.com/C_7Hm_1TVZU-STWcpQvdDW7uLmGPqFBKq1JEuoui2bJRmI-bof-JG8qzTNtnWQU1G2Hu-e5BJxdR7JXNf3DD=w1200), [official pilgrimage screenshot](https://play-lh.googleusercontent.com/z66yoLz7tpYJg1_BTGHG1EPgCvRiGLjQXTF9wh2BcYcMHDS-7lqlnRN6boNSPCoj9GWW8SDrfwLZvdYdWv7f=w1200).

Current direction: two appearances only, Light and Dark. Light retains the white background and charcoal controls; Dark reverses that hierarchy with neutral charcoal surfaces and white controls. Gold is reserved for the existing active Quran word highlight. Retired light presets resolve to Light; the retired Black Gold preset resolves to Dark. Existing white-glass/dark-minbar storage IDs remain readable.

### 3. Recognizable Service Navigation

The discovery preview puts recognizable service icons next to short labels, with category navigation close to the search field. This supports quick scanning rather than requiring users to read descriptions on every tile. The official site also groups daily worship tools such as Quran, prayer times, and Qibla together. [Official discovery screenshot](https://play-lh.googleusercontent.com/jvx3Zmga9BEyjsCFQl43tlBE0COFodt-1eE05Xsgd6gTZ0NiR7stOhQ1wKodBW7c98T9DxHNRN1cDVcAF-Rhcg=w1200), [official site](https://www.nusuk.sa/).

Adaptation: move the existing dashboard shortcuts near prayer information, use a compact grid, remove their explanatory subtitles, and keep every existing shortcut destination. Use two columns when the screen is narrow or text scaling needs more space, otherwise three.

### 4. Purposeful Imagery

The published reference uses contextual imagery for places and activities, not generic abstract decoration. The home preview gives prayer information a distinct visual position. [Official home screenshot](https://play-lh.googleusercontent.com/C_7Hm_1TVZU-STWcpQvdDW7uLmGPqFBKq1JEuoui2bJRmI-bof-JG8qzTNtnWQU1G2Hu-e5BJxdR7JXNf3DD=w1200).

Adaptation: a new original architectural photograph is bundled for a full-width Home prayer background and a low-opacity shell header backdrop. Live location, next prayer, time, and remaining time appear over the photograph. Prayer timeline and actions remain below. Surah covers remain in audio controls. See [artwork and generation prompt](artwork.md). No Nusuk imagery is copied.

### 5. Clear Separation Of Navigation And Content

The reference's service screens favor recognizable back/search actions, modest controls, and readable content boundaries. They do not surround every header action with a heavy decorative frame. [Official service screenshot](https://play-lh.googleusercontent.com/_beSl-_HavI71nMikGJaYroQLu8ph3TtVu-RlplHVzwzh6HolUpfiTbQmWSBEUDNfFFTWYA_OAD-bOgDkCsB=w1200).

Adaptation: consistent fixed shell headers with one unboxed section icon and standard action buttons. Replace the floating glass navigation capsule with a solid bottom navigation bar and a fine top separator. Preserve the audio player's existing clearance above navigation.

### 6. Detail Without Visual Noise

Booking rows in the screenshots reserve emphasis for the useful state, title, and next action. Rounded edges and subtle separation are visible, but repeated heavy shadows are not the main structure. [Official booking and pilgrimage screenshot](https://play-lh.googleusercontent.com/z66yoLz7tpYJg1_BTGHG1EPgCvRiGLjQXTF9wh2BcYcMHDS-7lqlnRN6boNSPCoj9GWW8SDrfwLZvdYdWv7f=w1200).

Adaptation: lighter surface shadows, quiet borders, compact Quran/library collection rows, and consistent sheet geometry. Floating audio controls retain enough elevation to read as an overlay; fixed appbars remain shadow-free.

## App Design Tokens

These are our adaptation values, not official Nusuk specifications.

| Role | Light | Dark |
| --- | --- | --- |
| Shell backdrop | `#FFFFFF` | `#141414` |
| Content surface | `#FFFFFF` | `#191919` |
| Secondary surface | `#F3F3F3` | `#252525` |
| Main text / controls | `#202323` | `#F3F3F3` |
| Active Quran word | `#8A5A00` | `#FFD166` |
| Border | `#E7E7E7` | `#363636` |

Shape scale: 8px repeated items, 10px controls, 20px floating docks, and 24px modal sheets. Ordinary page sections are unframed; borders and elevation are reserved for real tools, selected states, floating controls, and modals. Circular item badges remain circular.

Typography: shell title 24px/medium-to-semibold; section title 18px/semibold; metadata uses the existing body/label styles. Quran Arabic size remains controlled by reader settings. Selected ayahs and active words keep their existing color-only font treatment.

## Screen Mapping

| Existing screen/component | Adaptation | Behavior retained |
| --- | --- | --- |
| Home | Full-width photographic prayer overview, date/location metadata, compact early shortcut grid, calmer reading entry | Prayer refresh, next-prayer calculation, all quick actions, resume position, daily ayah, reading goals |
| All five shell headers | One shared title/subtitle/action arrangement, unboxed section icon, regular action buttons | Fixed positioning, tooltips, translated labels and existing callbacks |
| Bottom navigation | Solid white/charcoal bar, stable icon size, fine separator; separate from scroll viewport | Home, Quran, Prayer, Library, Settings |
| Quran index | Quiet collection rows, monochrome number badge, restrained Arabic/English hierarchy | Lazy lists, all structure sections, lookup, scrolling and reader navigation |
| Quran reader | Shared palette and shape rules, cleaner floating audio tile with icon-only actions | Text sizes, selection, word highlighting, translation, bookmarks, tafsir, seek, repeat, follow audio |
| Prayer | Lighter next-prayer typography and shared surfaces | Location, notifications, schedule, Qibla sensor calibration and calendar logic |
| Hadith/Azkar library | Consistent circular badges, collection headings and metadata | Book/category navigation, authentic-content filters, translations, downloads and search |
| Settings | Two appearances, compact reading/language/data rows, prayer calculation preferences, lazy preference sheets | Existing stored preferences, interface language, separate content languages, font controls, downloads, backup, attribution |
| Reader settings | Separate screen with pinned live preview, layout, Arabic script and size, translation toggle/language/size, audio follow | Combined and Separated layouts; tafsir/source configuration remains accessible in main Settings |
| Playback | Reciter row, translation toggle/voice, speed, expandable repeat controls | Ayah/range/count, editable range bounds, Stop/Continue, unavailable voice handling |
| Guides | Removed code, assets, catalog tools, navigation and localization labels | No unrelated user data deleted |
| Sheets/dialogs | Content-fit opaque sheets with one title and close action, bounded scrolling and keyboard clearance | Cancel/close actions and provider scopes; existing dialogs retain validation |

## Interaction And Accessibility

- Header buttons have 44px targets and retain tooltips.
- Bottom navigation retains labels, selected semantics, full-width item targets, and safe-area handling.
- Floating reader actions keep 44px targets. Action groups wrap on narrow screens rather than hiding buttons.
- No new endless ambient animations, blur layers, or network image requests are introduced.
- Reduced animation preferences and existing reading text-scale controls are not overridden.
- Translation RTL handling stays within translation text; the redesign does not force a new reading direction.
- Existing white-theme active-word dark gold is retained. Selected Arabic remains black in light themes and readable in dark themes.
- No data migration, deletion, language fallback, or playback-state reset is added.

## Deliberately Not Copied

Nusuk's pilgrimage booking, wallet, account flows, AI assistant, and travel services are not features requested for this Quran app. Its promotional backgrounds and institution branding are not copied. Exact animation timings, proprietary icons, and private typography cannot be established from public screenshots and are not presented as verified facts.

## Follow-Up Refinement

The follow-up re-inspected Nusuk's public Google Play gallery, particularly its centered prayer-time treatment, prayer arc, compact service navigation, and contextual image cards. These observations remain limited to published screenshots, not an interactive Nusuk session.

- Home now uses a centered next-prayer time over the original bundled courtyard image, a slim prayer arc, the five-prayer timeline, a cover-led resume card, two image-led destinations, and compact colored shortcuts. Existing destinations, reading goal, daily ayah, refresh, and saved position remain functional.
- Repeated interactive cards receive a fine outline; page sections remain unframed. Fixed appbars remain shadow-free.
- Qibla now uses an orbiting Kaaba, a fixed top alignment target, a shortest-turn arc, and a central degree readout. Stable alignment adds a green check and a rate-limited haptic; accuracy eligibility remains independent of temporary calibration hints. Existing location calculation and native providers are retained. Reduced motion disables interpolation. See [Qibla redesign](qibla-compass-redesign.md) for logic, UI files, safeguards, and validation limits.
- Hanafi/Shafi and the calculation method move from the Prayer screen to Settings > Prayer preferences. Onboarding is unchanged. Changes save through the existing repository and reschedule prayer alerts; entering Home or Prayer reloads the saved calculation.
- The reader's settings icon now opens a full screen. Its pinned preview uses the real Combined and Separated renderers and available translation data. Font sliders update the small preview during a drag and commit the shared preference on release. Script, layout, translation, and audio-follow preferences use the existing state and download flows.
- Reader edge navigation requires a 260-pixel pull followed by an 800 ms hold. The indicator uses nonlinear resistance, extra travel, a final hold-progress segment, and a 650 ms return when cancelled. Releasing or retreating cancels the switch; reduced motion removes added animation but preserves the deliberate hold. Existing tap navigation and upward-next/downward-previous directions are retained.
- Urdu translation text and Urdu tafsir use the bundled OFL-licensed Noto Nastaliq Urdu font with additional line height. Arabic scripture keeps the chosen Uthmani/Indo-Pak treatment, and unrelated languages retain their typography. See [Google Fonts on digital Nastaliq](https://fonts.googleblog.com/2023/03/why-are-there-so-few-digital-nastaliq.html) and the [Noto Nastaliq releases](https://github.com/notofonts/nastaliq/releases). This is a font choice, not a change to the translated content.

## Validation Boundary

The code-led redesign and active screen/overlay source audit are complete. See [whole-app audit](nusuk-ui-audit.md) for the complete inventory and evidence limits. Earlier Android compilation and phone observations predate the latest changes and do not verify this final design.

Follow-up verification: library-wide analysis, local Flutter asset-bundle compilation, and whitespace checks pass. All 40 existing focused reader, interlinear, Home-state, and prayer-time checks pass. Three settings checks were adapted for the new scrollable screen; the existing Urdu direction check also verifies the Nastaliq family and line height. No new test suites were added. The runner emitted a Dart finalizer diagnostic despite successful completion. Earlier whole-app, corpus/bootstrap, and deep-search fixture limitations remain outside this focused result.

The latest instruction is code-only review. No device, simulator, mirroring, installation, live content download or private-data operation was used for this refinement. Actual rendered appearance, physical sensor accuracy and artistic acceptance still require a separate review; they are not claimed from source analysis.
