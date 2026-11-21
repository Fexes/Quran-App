# Learn glossary research

Reviewed 21 October 2026. Companion to `umrah_research.md` and `prayer_wudu_research.md`; it explains vocabulary used in those guides rather than adding a new ritual syllabus.

## Content and matching

`lib/features/learn/data/guide_terms.dart` contains 57 terms, 24 focused detailed topics, 120 aliases, and 60 source records. Every term includes a short definition and sources. Detailed entries contain two or three short sections. Definitions use plain English where possible, including “prayer unit” rather than requiring the reader to already understand rak‘ah.

Aliases include the straight and curved apostrophe spellings actually present in the guides. English ritual vocabulary includes ablution, ritual bath, dry ablution, prostration/prostrations, supplication/supplications, and blessings on the Prophet. General words such as prayer, washing, and sitting are deliberately not aliases. The combined Sunni schools entry explains the Hanafi, Maliki, Shafi‘i, and Hanbali labels without presenting one as uniquely correct.

## Evidence and important distinctions

| Topic | Evidence | Editorial decision |
| --- | --- | --- |
| Salah and one complete unit | [Bukhari 757](https://sunnah.com/bukhari:757), [Muslim 498](https://sunnah.com/muslim:498) | A unit includes a bow, upright pause, two prostrations, and the sitting between them. |
| Prayer names and times | [Muslim 612d](https://sunnah.com/muslim:612d), daily counts already checked in the Prayer research | Definitions identify time of day and ordinary required counts. They do not attempt a timetable or all travel exceptions. |
| Fard and wajib | [SeekersGuidance: Hanafi distinction](https://seekersguidance.org/answers/hanafi-fiqh/how-do-the-hanafis-distinguish-between-fard-wajib-and-and-when-denial-becomes-disbelief/) | Both require observance; the Hanafi distinction is acknowledged. The source’s separate theological discussion is not reproduced. |
| Sunnah and schools | [Dar Al-Ifta: emphasized Sunnah](https://www.dar-alifta.org/ar/fatwa/details/17521/بيان-المراد-بمصطلح-سنة-الـهُدى-عند-السادة-الأحناف), [Dar Al-Ifta: schools of law](https://www.dar-alifta.org/en/fatwa/details/5916/am-i-obliged-to-follow-only-one-of-the-four-sunni-legal-schools-of-jurisprudence) | Sunnah can mean the prophetic way or a legal category. It must not automatically be read as “optional.” |
| Witr | [Mathabah: status of Witr](https://mathabah.org/the-status-of-witr-prayer/), [SeekersGuidance: Hanafi method](https://seekersguidance.org/answers/hanafi-fiqh/details-regarding-witr-confirmed-sunna-and-non-confirmed-sunna-prayers/) | Wajib describes the standard Hanafi position; emphasized Sunnah describes the other three schools. This does not claim unanimity among every historical Hanafi jurist. |
| Wudu, ghusl, tayammum | [Quran 5:6](https://quran.com/5/6), [Bukhari 248](https://sunnah.com/bukhari:248), [Bukhari 347](https://sunnah.com/bukhari:347), [Hanafi ghusl guidance](https://seekersguidance.org/answers/hanafi-fiqh/the-ritual-bath-ghusl-obligatory-recommended-and-disliked-acts/), [Hanafi tayammum method](https://seekersguidance.org/answers/hanafi-fiqh/how-to-make-dry-ablution-tayammum/) | Ghusl and tayammum entries explain their purpose and boundaries. They do not present one school’s full method as universal or replace individual advice for unusual circumstances. |
| Maqam Ibrahim | [Quran 2:125](https://quran.com/2/125), [Bukhari 3364](https://sunnah.com/bukhari:3364), [official Maqam page](https://alharamain.gov.sa/public/?page=maqam-ibrahim-en) | Explain the standing stone itself, rather than using “station” as an unexplained circular definition. It is not a tomb. |
| Hijr | [Abu Dawud 2028](https://sunnah.com/abudawud:2028), [official Hijr page](https://alharamain.gov.sa/public/?page=hijr-en&site=ur) | The enclosure contains part of the original Kaaba footprint. Do not imply its whole present area was inside the original Kaaba. Tawaf remains outside it. |
| Safa, Marwah, Zamzam | [Quran 2:158](https://quran.com/2/158), [Muslim 1218a](https://sunnah.com/muslim:1218a), [Bukhari 3364](https://sunnah.com/bukhari:3364) | One-way sa’i counting is explicit. Drinking Zamzam is not made a completion condition. |
| Haram boundary | [Bukhari 1834](https://sunnah.com/bukhari:1834), [Islamic Portal: haircut location](https://islamicportal.co.uk/does-hair-have-to-be-shaved-in-haram/) | The precinct is larger than the mosque. The haircut-location requirement is identified specifically as Hanafi. |
| Hajj places | [Muslim 1218a](https://sunnah.com/muslim:1218a), [official Hajj rituals](https://hajj.nusuk.sa/nusuk/hajj-rituals) | Arafat, Muzdalifah, and Jamarat are explained because the Umrah guide names them when distinguishing the two pilgrimages. They are not added as Umrah steps. |
| Madinah | [Nusuk: Makkah and Madinah](https://umrah.nusuk.sa/MakkahAndMadinah), [official visiting guide, printed p. 12](https://risala.prh.gov.sa/storage/contents/250/en400.pdf) | Madinah and the Prophet’s Mosque are identified; the visit is separate from the rites completing Umrah. |
| Umrah operations | [Nusuk journey](https://umrah.nusuk.sa/Journey), [official Umrah portal](https://www.nusuk.sa/umrah) | Booking and access information remains a live official link, without freezing a permit or visa rule in the glossary. |

## Source handling and limits

The app gives direct links to Quran passages, hadith references, and the relevant institutional or named scholarly answers. Existing prayer recitation and Umrah procedural evidence remains recorded in the two earlier research notes. Descriptions are original concise summaries, with no copied article passages or copied modern translations. Evidence is distributed across topic-specific references instead of reproducing an entire modern guide. The classical source text is distinguished from modern school-specific interpretation.

This is researched educational content, not a claim of scholarly certification. School-dependent details remain qualified, particularly purity for tawaf, Witr, prayer methods, tayammum, ghusl, face covering, and haircut location. The definition of Jumu‘ah is not an exhaustive eligibility ruling.

The content preflight found no duplicate term IDs, no duplicate case-insensitive aliases, no repeated source within an entry, no unresolved source references, and no em dashes. Dart formatting was applied. No tests or simulators were run.

## Library expansion, 21 October 2026

The library now contains 14 guides and 48 illustrated chapters, ordered as Purification (Wudu, Ghusl, Tayammum), Prayer (Prayer, Congregational prayer, Prayer mistakes, Travel & illness, Jumu‘ah, Eid, Janazah), Fasting & giving (Fasting, Zakat), and Pilgrimage (Umrah, Hajj). `learning_guide_catalog.dart` is the single catalog used by Learn. Cards retain the illustration-led presentation and expand to accommodate their text.

`additional_guide_terms.dart` adds 37 entries, bringing the glossary to 94. It covers new prayer corrections, purification vocabulary, travel, fasting, zakat and Hajj terms. Longer multi-word aliases take priority over their individual words, so sujud al-sahw, zakat al-fitr, and tawaf al-ifadah receive their own definitions. Arabic and transliteration recitations retain their existing selectable presentation.

New definitions use the primary texts and named institutional or scholarly references linked directly in their entries. In particular, shortening and combining remain distinct; fidyah and kaffarah are not interchangeable payments; nisab is a threshold rather than only the portion on which zakat is calculated; Tamattu, Qiran and Ifrad remain separate pilgrimage forms. The midday zenith entry explains the prayer-guide use of local solar noon, rather than implying the sun is literally overhead at every location.

See `learn_purification_prayer_research.md` and `learn_worship_pilgrimage_research.md` for new procedural source checks. `learn_expansion_illustrations.md` records the built-in generation prompts, original selections, final workspace assets and style refinements. A whole-library content check found unique guide, chapter and term IDs, no unresolved chapter or supplication references, and no missing images. No tests or simulators were created or run.
