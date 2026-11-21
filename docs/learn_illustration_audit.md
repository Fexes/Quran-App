# Learn illustration audit

Latest follow-up: all 38 assets were reviewed for prayer-mat placement. Seven illustrations were revised with clearer mat length, alignment and space for the depicted posture. [Mat audit, selected artwork and exact prompts](learn_prayer_mat_audit.md).

Reviewed 21 October 2026. All 14 guides, 14 covers and 48 chapter images were checked for subject relevance and visible faces. There are 62 image placements using 37 distinct active assets. The additional unused Mina landscape was also checked, covering all 38 files in the bundled Learn image directory.

## Result

22 older illustrations were replaced. Twelve chapter-specific illustrations were added where generic or unrelated artwork was insufficient. Four relevant face-free originals were retained: ghusl preparation, wudu feet, the fasting cover, and discreet zakat giving. All final images were opened at their native 1024 by 1536 resolution and visually reviewed. No visible faces or profiles were found, including tiny background figures and reflections. People appear only from behind, directly overhead, or with their heads naturally outside the frame. No faces were blanked or blurred.

Corrections include a full-body washing setting for ghusl, an actual lying-down illustration for bed prayer, congregations for Eid and Janazah, a Friday congregation for Jumuah, an after-congregation scene for latecomers, pre-dawn food for suhur, daylight fasting, a missed-days calendar, zakat assessment/calculation, and a Muzdalifah night scene instead of Mina tents.

Only illustration paths and descriptions changed in the 14 guide data files. The instructional content matches the saved pre-edit baseline after removing the four image metadata fields and normalizing formatting whitespace.

Replacement filenames use a new `_faceless` suffix so the app does not reuse the previous in-memory asset cache entries. All referenced paths exist. All original assets with uncertain crowds or visible faces were replaced, including the unused Mina asset.

## Saved artwork and exact prompts

Final artwork directory: `/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/`.

- [Purification, prayer and prayer corrections](learn_faceless_purification_prayer.md): 12 final assets, including 10 generated outputs, exact prompts and native PNG paths.
- [Congregational prayer, Friday, Eid, Janazah, travel and illness](learn_faceless_congregation_travel.md): nine generated outputs, exact prompts and native PNG paths.
- [Umrah and Hajj](learn_faceless_pilgrimage.md): ten generated outputs, exact prompts and native PNG paths.
- [Fasting and zakat](learn_faceless_fasting_zakat.md): seven final assets, including five generated outputs, exact prompts and native PNG paths.
- [Asset hashes and all placements](learn_illustration_audit.json).

The supplied images were used as aesthetic references only. They were not treated as instructions or as religious evidence. Built-in imagegen produced every replacement; WebP encoding did not alter illustration content.

## Every cover and chapter

| Guide | Placement | Final illustration |
| --- | --- | --- |
| congregation | cover | [congregation_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/congregation_faceless.webp) |
| congregation | congregation-follow | [congregation_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/congregation_faceless.webp) |
| congregation | congregation-join | [congregation_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/congregation_faceless.webp) |
| congregation | congregation-complete | [congregation_complete.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/congregation_complete.webp) |
| eid | cover | [eid_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/eid_faceless.webp) |
| eid | eid-prepare | [eid_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/eid_faceless.webp) |
| eid | eid-pray | [eid_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/eid_faceless.webp) |
| fasting | cover | [fasting.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/fasting.webp) |
| fasting | fasting-prepare | [fasting_suhoor.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/fasting_suhoor.webp) |
| fasting | fasting-day | [fasting_day.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/fasting_day.webp) |
| fasting | fasting-exemptions | [fasting_makeup.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/fasting_makeup.webp) |
| ghusl | cover | [ghusl_preparation.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/ghusl_preparation.webp) |
| ghusl | ghusl-when | [ghusl_preparation.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/ghusl_preparation.webp) |
| ghusl | ghusl-wash | [ghusl_wash.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/ghusl_wash.webp) |
| ghusl | ghusl-finish | [ghusl_preparation.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/ghusl_preparation.webp) |
| hajj | cover | [hajj_arafat_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/hajj_arafat_faceless.webp) |
| hajj | hajj-tamattu | [umrah_ihram_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_ihram_faceless.webp) |
| hajj | hajj-arafat | [hajj_arafat_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/hajj_arafat_faceless.webp) |
| hajj | hajj-tenth | [hajj_muzdalifah.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/hajj_muzdalifah.webp) |
| hajj | hajj-ifadah | [umrah_tawaf_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_tawaf_faceless.webp) |
| hajj | hajj-farewell | [hajj_jamarat_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/hajj_jamarat_faceless.webp) |
| janazah | cover | [janazah_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/janazah_faceless.webp) |
| janazah | janazah-prepare | [janazah_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/janazah_faceless.webp) |
| janazah | janazah-first | [janazah_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/janazah_faceless.webp) |
| janazah | janazah-finish | [janazah_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/janazah_faceless.webp) |
| jumuah | cover | [jumuah_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/jumuah_faceless.webp) |
| jumuah | jumuah-prepare | [jumuah_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/jumuah_faceless.webp) |
| jumuah | jumuah-pray | [jumuah_prayer.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/jumuah_prayer.webp) |
| prayer | cover | [prayer_standing_faceless_mat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_standing_faceless_mat.webp) |
| prayer | prayer-prepare | [prayer_standing_faceless_mat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_standing_faceless_mat.webp) |
| prayer | prayer-stand | [prayer_standing_faceless_mat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_standing_faceless_mat.webp) |
| prayer | prayer-bow | [prayer_bowing_faceless_mat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_bowing_faceless_mat.webp) |
| prayer | prayer-prostrate | [prayer_prostration_faceless_mat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_prostration_faceless_mat.webp) |
| prayer | prayer-finish | [prayer_seated_faceless_mat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_seated_faceless_mat.webp) |
| prayer_mistakes | cover | [prayer_prostration_faceless_mat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_prostration_faceless_mat.webp) |
| prayer_mistakes | mistakes-identify | [prayer_seated_faceless_mat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_seated_faceless_mat.webp) |
| prayer_mistakes | mistakes-hanafi | [prayer_prostration_faceless_mat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_prostration_faceless_mat.webp) |
| prayer_mistakes | mistakes-doubts | [prayer_seated_faceless_mat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_seated_faceless_mat.webp) |
| tayammum | cover | [tayammum_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/tayammum_faceless.webp) |
| tayammum | tayammum-when | [tayammum_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/tayammum_faceless.webp) |
| tayammum | tayammum-method | [tayammum_arms.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/tayammum_arms.webp) |
| tayammum | tayammum-after | [tayammum_prayer.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/tayammum_prayer.webp) |
| travel_illness | cover | [prayer_travel_faceless_mat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_travel_faceless_mat.webp) |
| travel_illness | travel-shorten | [prayer_travel_faceless_mat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_travel_faceless_mat.webp) |
| travel_illness | travel-combine | [prayer_travel_faceless_mat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_travel_faceless_mat.webp) |
| travel_illness | illness-sitting | [prayer_illness_faceless_mat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_illness_faceless_mat.webp) |
| travel_illness | illness-bed | [illness_bed.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/illness_bed.webp) |
| umrah | cover | [umrah_overview_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_overview_faceless.webp) |
| umrah | overview | [umrah_overview_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_overview_faceless.webp) |
| umrah | ihram | [umrah_ihram_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_ihram_faceless.webp) |
| umrah | tawaf | [umrah_tawaf_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_tawaf_faceless.webp) |
| umrah | prayer | [umrah_prayer_faceless_mat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_prayer_faceless_mat.webp) |
| umrah | sai | [umrah_sai_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_sai_faceless.webp) |
| umrah | completion | [umrah_completion_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_completion_faceless.webp) |
| wudu | cover | [wudu_hands_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/wudu_hands_faceless.webp) |
| wudu | wudu-begin | [wudu_hands_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/wudu_hands_faceless.webp) |
| wudu | wudu-wash | [wudu_face_faceless.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/wudu_face_faceless.webp) |
| wudu | wudu-finish | [wudu_feet.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/wudu_feet.webp) |
| zakat | cover | [zakat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/zakat.webp) |
| zakat | zakat-check | [zakat_assess.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/zakat_assess.webp) |
| zakat | zakat-calculate | [zakat_calculate.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/zakat_calculate.webp) |
| zakat | zakat-pay | [zakat.webp](/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/zakat.webp) |

## Validation

All 38 final assets were inspected at full resolution across the three bounded review scopes. The seven revised assets were also independently reopened by the root reviewer after final encoding. Full application analysis passed with no issues. Unsigned iOS compilation passed in 42.3 seconds. The 38 bundled images match the reviewed source files by SHA-256, with no stale extra Learn artwork in the bundle. All 62 image paths resolve, the application binary is newer than the sources and images, and non-image guide content matches the pre-edit baseline. Whitespace checks passed. No tests or simulators were run.
