# Prayer mat follow-up audit

Reviewed 21 October 2026. All 38 Learn illustration files were opened and reviewed, covering all 37 active images used by the 14 guides and their 62 cover/chapter placements, plus the unused Mina image. Seven illustrations required correction. The other 31 were retained.

## Review standard

This review checks visual plausibility, not a religious requirement to use a mat or stand on an exact marked point. Standing and bowing scenes should show a believable adult-sized mat continuing ahead of the feet, rather than ending at the toes. Seated figures should leave usable space ahead of their knees. Prostration contact points should stay inside the mat with visible forward clearance. Direction, perspective, scale, obstacles and row spacing were checked separately. Different postures naturally occupy different parts of the same usable prayer space.

The seven corrections use rear viewpoints and retain the no-visible-faces rule, including background people and reflections. Generic oversized rugs were refined to keep the scale appropriate for one person. No religious prose, Arabic, transliterations, sources, chapter order or guide behavior changed.

## Artwork and exact prompts

Every final image is saved in `/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/`. Image content edits used the built-in imagegen tool, one call per image. Only WebP encoding used local tools.

- [Four prayer poses: outputs, selected PNGs and exact prompts](learn_mat_audit_prayer.md).
- [Travel and chair prayer: outputs, selected PNGs and exact prompts](learn_mat_audit_congregation_travel.md).
- [Umrah prayer: output, selected PNG and exact prompts](learn_mat_audit_umrah.md).

Replacement paths gain a `_mat` suffix during integration so an already-running app does not reuse older image-cache entries. Historical source references in generation records refer to the pre-revision filenames; the current mapping is recorded in [the asset manifest](learn_illustration_audit.json).

## Complete asset review

| Asset | Decision | Finding |
| --- | --- | --- |
| [congregation_complete.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/congregation_complete.webp) | Retained | Continuous carpet; the standing latecomer has clear floor ahead before the seated row. |
| [congregation_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/congregation_faceless.webp) | Retained | Continuous mosque carpet, coherent direction and visually plausible spacing between rows. |
| [eid_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/eid_faceless.webp) | Retained | Continuous outdoor prayer carpet, one shared forward direction and no tiny individual mat borders. |
| [fasting.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/fasting.webp) | Retained | No actionable prayer-mat placement issue; no person praying on an individual mat. |
| [fasting_day.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/fasting_day.webp) | Retained | Folded unused rug on a table; no posture or prayer-space issue. |
| [fasting_makeup.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/fasting_makeup.webp) | Retained | No actionable prayer-mat placement issue; no person praying on an individual mat. |
| [fasting_suhoor.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/fasting_suhoor.webp) | Retained | No actionable prayer-mat placement issue; no person praying on an individual mat. |
| [ghusl_preparation.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/ghusl_preparation.webp) | Retained | Bathroom floor mat is not a prayer mat. |
| [ghusl_wash.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/ghusl_wash.webp) | Retained | No actionable prayer-mat placement issue; no person praying on an individual mat. |
| [hajj_arafat_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/hajj_arafat_faceless.webp) | Retained | No actionable prayer-mat placement issue; no person praying on an individual mat. |
| [hajj_jamarat_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/hajj_jamarat_faceless.webp) | Retained | No actionable prayer-mat placement issue; no person praying on an individual mat. |
| [hajj_mina_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/hajj_mina_faceless.webp) | Retained | No actionable prayer-mat placement issue; no person praying on an individual mat. |
| [hajj_muzdalifah.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/hajj_muzdalifah.webp) | Retained | Sleeping mats with bedding, not active prayer placements. |
| [illness_bed.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/illness_bed.webp) | Retained | Bed prayer/resting posture does not depend on the decorative floor rug. |
| [janazah_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/janazah_faceless.webp) | Retained | Standing funeral context on broad carpet and courtyard; no individual mat problem or prostration implied. |
| [jumuah_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/jumuah_faceless.webp) | Retained | Seated gathering on continuous mosque carpet; no individual mat placement fault. |
| [jumuah_prayer.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/jumuah_prayer.webp) | Retained | Standing rows on continuous carpet with coherent forward direction and visible separation. |
| [prayer_bowing_faceless_mat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_bowing_faceless_mat.webp) | Revised | Bowing feet retain the rear placement; forward mat area remains clear. |
| [prayer_illness_faceless_mat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_illness_faceless_mat.webp) | Revised | Chair is near the rear short edge, feet are supported and mat extends toward the niche. |
| [prayer_prostration_faceless_mat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_prostration_faceless_mat.webp) | Revised | Hands, knees, forehead and toes fit inside the mat, with clearance beyond the head. |
| [prayer_seated_faceless_mat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_seated_faceless_mat.webp) | Revised | Seated posture is near the rear with usable mat ahead of the knees. |
| [prayer_standing_faceless_mat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_standing_faceless_mat.webp) | Revised | Heels toward the rear with space ahead for kneeling and prostration; mat points toward the niche. |
| [prayer_travel_faceless_mat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_travel_faceless_mat.webp) | Revised | Standing traveller is near the rear short edge; bag and shoes remain beside the mat. |
| [tayammum_arms.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/tayammum_arms.webp) | Retained | Background rug is unoccupied; no praying person to reposition. |
| [tayammum_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/tayammum_faceless.webp) | Retained | Background rug is unoccupied; no praying person to reposition. |
| [tayammum_prayer.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/tayammum_prayer.webp) | Retained | Unoccupied mat lies lengthwise toward the niche with unobstructed floor. |
| [umrah_completion_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_completion_faceless.webp) | Retained | No actionable prayer-mat placement issue; no person praying on an individual mat. |
| [umrah_ihram_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_ihram_faceless.webp) | Retained | No actionable prayer-mat placement issue; no person praying on an individual mat. |
| [umrah_overview_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_overview_faceless.webp) | Retained | No actionable prayer-mat placement issue; no person praying on an individual mat. |
| [umrah_prayer_faceless_mat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_prayer_faceless_mat.webp) | Revised | Lengthwise narrow rug points toward the Kaaba; seated pilgrim is near the rear, open floor ahead, dispenser to the side. |
| [umrah_sai_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_sai_faceless.webp) | Retained | No actionable prayer-mat placement issue; no person praying on an individual mat. |
| [umrah_tawaf_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_tawaf_faceless.webp) | Retained | No actionable prayer-mat placement issue; no person praying on an individual mat. |
| [wudu_face_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/wudu_face_faceless.webp) | Retained | No actionable prayer-mat placement issue; no person praying on an individual mat. |
| [wudu_feet.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/wudu_feet.webp) | Retained | No actionable prayer-mat placement issue; no person praying on an individual mat. |
| [wudu_hands_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/wudu_hands_faceless.webp) | Retained | No actionable prayer-mat placement issue; no person praying on an individual mat. |
| [zakat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/zakat.webp) | Retained | No actionable prayer-mat placement issue; no person praying on an individual mat. |
| [zakat_assess.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/zakat_assess.webp) | Retained | No actionable prayer-mat placement issue; no person praying on an individual mat. |
| [zakat_calculate.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/zakat_calculate.webp) | Retained | No actionable prayer-mat placement issue; no person praying on an individual mat. |

## Validation

All 38 final assets were inspected at full resolution across the three bounded review scopes. The seven revised assets were also independently reopened by the root reviewer after final encoding. Full application analysis passed with no issues. Unsigned iOS compilation passed in 42.3 seconds. The 38 bundled images match the reviewed source files by SHA-256, with no stale extra Learn artwork in the bundle. All 62 image paths resolve, the application binary is newer than the sources and images, and non-image guide content matches the pre-edit baseline. Whitespace checks passed. No tests or simulators were run.
