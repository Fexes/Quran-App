# Reading language defaults

Implementation updated 2026-10-13. Catalog-source checks were recorded 2026-10-12. These are editorial/provider defaults, not a claim of measured worldwide popularity. The providers do not publish comparable listening or translation usage rankings.

## Urdu

- Text: Fatah Muhammad Jalandhari, Quran.com resource `234`.
- Voice: Shamshad Ali Khan, AlQuran Cloud edition `ur.khan` (64 kbps).
- This voice already existed in the catalog; it is now an explicit default rather than an accident of list order.
- [Quran.com translation catalog](https://api.quran.com/api/v4/resources/translations) verifies the text resource. [AlQuran Cloud's Urdu audio catalog](https://api.alquran.cloud/v1/edition?format=audio&language=ur) verifies the voice. [Quran4u's publisher credits](https://www.quran4u.com/QR_Urdu_Index.htm) attribute Urdu narration to Shamshad Ali Khan and translation to Fateh Muhammad Jalundhari. Do not substitute resource 97, which is Maududi.

## Other languages

- Onboarding, Settings, reader settings and Downloads share one Reading & listening setup. Language and Arabic reciter are the main choices. Text edition and translation voice remain optional details.
- The language picker places languages with a verified text/audio pairing in the available reciter catalog first. A tap selects a matching edition automatically. An existing selected edition is preserved when tapping its language again.
- Automatic recommendations prefer an available text/audio pair over a text-only edition. English's paired recommendation is Saheeh International, resource 20, with Ibrahim Walk. Text-only languages use their existing catalog default.
- Explicit text-edition choices remain available. Changing a translation voice also selects the exact text edition in the curated pairing catalog; language or author similarity alone never establishes a match.
- Bundled English remains the offline fallback when no resource is selected. This is distinct from selecting an English edition with audio and from hiding translations using the reader toggle.
- Translation audio has explicit stable defaults for every currently supported audio language. Saved voice choices take precedence and survive language switching. A voice from a different language is never a fallback.
- Languages without audio keep audio unavailable. This does not invent audio coverage for all 69 languages, force audio on, or download packs silently.
- Selecting a Quran translation updates its audio language and compatible voice. Saved preferences synchronize existing playback so displayed text and translated audio remain matched. Translation audio is optional and is not enabled merely by choosing a language.
- Saving a selected edition prepares or refreshes its full text pack first. Downloads separates text readiness from per-surah audio progress; bulk audio, Wi-Fi, storage and source options are optional details. Cancelled text preparation leaves the previous selection intact.
- No cache data is deleted, and the existing Arabic/translation/bismillah queue sequence is preserved.

## Onboarding script

- Pakistan, India and Bangladesh suggest IndoPak; other countries suggest Uthmani.
- The Arabic script selector lives under `Personalize your journey`, not `Set prayer location`.
- A confirmed prayer location takes priority. Resolve its country against the existing offline city database without requesting a fresh GPS fix. Explicit city/GPS choices override an earlier IP suggestion, and their coordinates are saved before the location-confirmed flag so resuming setup uses the chosen city.
- Otherwise make one bounded HTTPS request to [country.is](https://country.is/). The service permits free commercial use without a key. Only its country field is consumed; the returned IP is not stored or logged. Precise coordinates are never uploaded.
- This is a suggestion, not precise border geocoding. IP/VPN location and nearest-city country can be wrong. The visible script selector is always editable.
- A manual choice, including a pre-existing saved script, is never replaced by a late lookup. GPS/IP failures keep the existing default and never block onboarding. The script is applied globally on finishing setup.
- No account, paid subscription, simulator runtime, or device installation was created by this change.
