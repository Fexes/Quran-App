# Reading language defaults

Verified 2026-10-12. These are editorial/provider defaults, not a claim of measured worldwide popularity. The providers do not publish comparable listening or translation usage rankings.

## Urdu

- Text: Fatah Muhammad Jalandhari, Quran.com resource `234`.
- Voice: Shamshad Ali Khan, AlQuran Cloud edition `ur.khan` (64 kbps).
- This voice already existed in the catalog; it is now an explicit default rather than an accident of list order.
- [Quran.com translation catalog](https://api.quran.com/api/v4/resources/translations) verifies the text resource. [AlQuran Cloud's Urdu audio catalog](https://api.alquran.cloud/v1/edition?format=audio&language=ur) verifies the voice. [Quran4u's publisher credits](https://www.quran4u.com/QR_Urdu_Index.htm) attribute Urdu narration to Shamshad Ali Khan and translation to Fateh Muhammad Jalundhari. Do not substitute resource 97, which is Maududi.

## Other languages

- The language picker selects one default edition on a language tap. Its translator button and translator search still permit explicit edition choices.
- First priority is a saved user choice for that language, including an existing selected edition. Otherwise use a supported Quran.com locale default, then the existing bundled catalog default, then the first available text edition.
- [Quran.com's locale settings](https://github.com/quran/quran.com-frontend-next/tree/production/src/redux/defaultSettings/locales) supply the Bengali, Spanish, Persian, French, Indonesian, Italian, Malay, Dutch, Portuguese, Russian, Albanian, Swahili, Thai, Turkish, Vietnamese and Chinese choices. English keeps the available Abdel Haleem edition 85; Quran.com's web default 131 is absent from the public catalog used by this app.
- All 69 existing catalog buckets have language codes. Do not merge case/alias buckets silently in this change.
- Translation audio has explicit stable defaults for every currently supported audio language. Saved voice choices take precedence and survive language switching. A voice from a different language is never a fallback.
- Languages without audio keep audio unavailable. This does not invent audio coverage for all 69 languages, force audio on, or download packs silently.
- Selecting a Quran translation updates the audio meaning language. Users can subsequently override audio language or voice in settings. A new playback queue resolves the latest saved preference; an existing queue is not interrupted just because a text edition changed.
- No cache data is deleted, and the existing Arabic/translation/bismillah queue sequence is preserved.

## Onboarding script

- Pakistan, India and Bangladesh suggest IndoPak; other countries suggest Uthmani.
- The Arabic script selector lives under `Personalize your journey`, not `Set prayer location`.
- A confirmed prayer location takes priority. Resolve its country against the existing offline city database without requesting a fresh GPS fix. Explicit city/GPS choices override an earlier IP suggestion, and their coordinates are saved before the location-confirmed flag so resuming setup uses the chosen city.
- Otherwise make one bounded HTTPS request to [country.is](https://country.is/). The service permits free commercial use without a key. Only its country field is consumed; the returned IP is not stored or logged. Precise coordinates are never uploaded.
- This is a suggestion, not precise border geocoding. IP/VPN location and nearest-city country can be wrong. The visible script selector is always editable.
- A manual choice, including a pre-existing saved script, is never replaced by a late lookup. GPS/IP failures keep the existing default and never block onboarding. The script is applied globally on finishing setup.
- No account, paid subscription, simulator runtime, or device installation was created by this change.
