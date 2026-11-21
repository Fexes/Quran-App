# Pilgrimage illustration audit and faceless replacements

Integration note: Replacement filenames gained `_faceless` after generation to prevent reuse of earlier cached artwork. Original edit inputs used the same names without that suffix.

Completed 21 October 2026 using the built-in image generation tool. All final assets are 1024 × 1536 WebP, encoded from native generated PNGs with cwebp quality 88, method 6. No procedural painting, face blurring, face erasure, crops, or simulator runs were used.

## Scope and initial findings

Inspected all nine existing pilgrimage assets at their original resolution before editing. Ihram, tawaf, the prayer pause, completion and Arafat contained visible facial features or profiles. Overview, Mina and Jamarat had distant people that prevented confidently guaranteeing the requested absence of every face. Sa’i was largely a rear view, but the new version limits the scene to five unambiguous rear views and removes the background crowd. The tenth-day Hajj chapter used Mina tents even though its opening subject was Muzdalifah; it now has a dedicated night scene.

The original references supplied by the user informed the muted cream, slate blue, gold and outlined cel-shaded style. The images depict contemporary ordinary pilgrims, never prophetic figures. Actual camera orientation hides faces: straight rear views or a vertical overhead view. Architectural scenes omit people.

## Final chapter mapping

| Guide / chapter | Final asset | Relevance and face audit |
| --- | --- | --- |
| Umrah cover and overview | `umrah_overview_faceless.webp` | Kaaba and courtyard architectural view, no people or human reflections |
| Umrah / ihram | `umrah_ihram_faceless.webp` | Bareheaded pilgrim preparing in white wraps, both shoulders covered, straight rear view |
| Umrah / tawaf | `umrah_tawaf_faceless.webp` | Vertical overhead Kaaba and courtyard; circular counterclockwise movement outside the Hijr; tops of heads only |
| Umrah / prayer | `umrah_prayer_faceless_mat.webp` | Seated rear view in a post-tawaf prayer area, Kaaba ahead, cup and Zamzam dispenser nearby; no background crowd |
| Umrah / sa’i | `umrah_sai_faceless.webp` | Five rear-view pilgrims in the modern Safa–Marwah gallery with green markers |
| Umrah / completion | `umrah_completion_faceless.webp` | Shaved scalp from straight behind after the haircut; no active haircut in the mosque |
| Hajj / Tamattu preparation | `umrah_ihram_faceless.webp` | Reuse is appropriate because the chapter prepares the pilgrim for ihram and Umrah |
| Hajj cover and Arafat | `hajj_arafat_faceless.webp` | Three rear-view pilgrims making dua on the open plain; distant landscape has no crowd |
| Hajj / Muzdalifah and the 10th | `hajj_muzdalifah.webp` | New open-air night resting scene, with empty mats and travel belongings; no Mina tent city |
| Hajj / ifadah | `umrah_tawaf_faceless.webp` | Reuse is appropriate because this is the same circling rite at the Kaaba |
| Hajj / farewell days | `hajj_jamarat_faceless.webp` | Modern Jamrah wall and collection basin, fitting the remaining stoning steps; people omitted |
| Retained pilgrimage asset | `hajj_mina_faceless.webp` | Correct Mina tent-city landscape, revised without crowds; no longer mislabeled as Muzdalifah |

The bounded image-reference search found these assets only in the Umrah and Hajj guides. The parent task audits the other chapters in the 48-chapter library. Only image paths and image/cover descriptions were edited in these two source files. A whitespace-normalized comparison with the four permitted image fields removed confirmed that all religious content remained identical.

## Review and iteration

All accepted full-resolution generated outputs were visually inspected. The first tawaf attempt was rejected because every pilgrim faced the same direction. A second edit specified tangential directions around a vertical top-down Kaaba and produced the accepted counterclockwise composition. The unused first attempt remains in the generation folder, not in the app assets. Every final file is stored under `/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/`.

## Exact final prompts and source PNGs

### umrah_overview

Final WebP: `/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_overview_faceless.webp`

Source PNG: `/Users/farhanfida/.codex/generated_images/01a15e71-23ee-7130-b200-b4fe22dcdddb/exec-4973b9b4-53b4-4703-b378-95afe88837c4.png`

Reference: `/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_overview_faceless.webp`

Prompt:

```text
Use case: precise-object-edit. Edit the supplied pilgrimage illustration into a 1024x1536 portrait artwork. Keep the Kaaba, cream Masjid al-Haram arcades, golden morning light and muted slate blue / warm cream / soft gold palette. Preserve its refined outlined flat cel-shaded editorial illustration style, with reduced painterly texture. Remove EVERY person from the courtyard and distant galleries and remove their reflections. Show the beautiful empty marble courtyard and the Kaaba as an architectural introduction to Umrah. Absolutely no people, faces, profiles, human reflections, statues or portraits anywhere. No UI, text, lettering, watermarks or readable calligraphy; gold ornamental geometric bands only. Full bleed, no border.
```

### umrah_ihram

Final WebP: `/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_ihram_faceless.webp`

Source PNG: `/Users/farhanfida/.codex/generated_images/01a15e71-23ee-7130-b200-b4fe22dcdddb/exec-6f534e66-4db3-4675-9b49-58a678786261.png`

Reference: `/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_ihram_faceless.webp`

Prompt:

```text
Use case: precise-object-edit. Edit the supplied illustration, portrait 1024x1536. Keep the white ihram cloth, warm cream mosque courtyard and blue sky, precise dark outlines and flat cel-shaded blocks in muted cream/slate blue/gold. Change the male pilgrim to a PERFECTLY STRAIGHT REAR VIEW, centered: camera directly behind his spine, head faces straight away, only back of dark hair, nape and back of head visible. NO TURN or side profile, no facial features, no beard silhouette, no cheek, nose, eye or mouth. Bareheaded male in two white unsewn ihram wraps with BOTH SHOULDERS covered, arms relaxed. Do not add a hood, cap, turban or head covering. Remove all other people and human reflections. No face anywhere, not even tiny background. Geographically plausible miqat preparation mosque courtyard, no Kaaba at miqat. No readable text, signs, UI or watermark. Full bleed.
```

### umrah_tawaf

Final WebP: `/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_tawaf_faceless.webp`

Source PNG: `/Users/farhanfida/.codex/generated_images/01a15e71-23ee-7130-b200-b4fe22dcdddb/exec-54e6b2b1-1c72-497f-9952-ad92e2d1e933.png`

Reference: `/Users/farhanfida/.codex/generated_images/01a15e71-23ee-7130-b200-b4fe22dcdddb/exec-20d4090a-21b0-4542-b5b9-0e64ccd9bd00.png`

Prompt:

```text
Edit this 1024x1536 portrait overhead tawaf artwork. Crucial correction: the pilgrims must NOT all be walking upward. Recompose as EXACTLY VERTICAL 90-DEGREE TOP-DOWN view, with the Kaaba as a flat square roof with NO front wall visible. Reduce the number of people to about 32, in clearly CIRCULAR COUNTERCLOCKWISE walking lanes around the Kaaba and outside the Hijr enclosure. Their feet, shoulders, heads and walking direction follow these tangents: pilgrims BELOW the Kaaba walk toward the RIGHT edge; pilgrims RIGHT of the Kaaba walk toward the TOP edge; pilgrims ABOVE the Kaaba walk toward the LEFT edge; pilgrims LEFT of the Kaaba walk toward the BOTTOM edge. Intermediate people turn smoothly around those circular lanes. Anatomically natural TOPS OF HEADS only, hair crowns or dark headscarves; vertical camera sees zero facial surfaces regardless of walking direction. No face, eye, nose, mouth, cheek, profile, human reflection, blank oval faces, or people looking upward. Do not rotate everyone to a single direction. Fine outlined flat cel shading, cream floor, white ihram/dark modest clothing, slate shadows. No arrows, text, lettering, UI or watermark. Preserve overall restrained illustration style.
```

### umrah_prayer

Final WebP: `/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_prayer_faceless_mat.webp`

Source PNG: `/Users/farhanfida/.codex/generated_images/01a15e71-23ee-7130-b200-b4fe22dcdddb/exec-69070274-9d0f-49e5-8906-81f7f2c9995d.png`

Reference: `/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_prayer_faceless_mat.webp`

Prompt:

```text
Edit the supplied Umrah prayer illustration into a 1024x1536 portrait. Keep refined dark outlines, flat cel-shaded folds, warm cream/slate blue/soft gold colors and Masjid al-Haram architecture. Recompose a quiet permitted prayer area at the EDGE of the Grand Mosque courtyard, not obstructing tawaf. The Kaaba is visible far ahead through an opening, establishing the worshipper's qiblah. One bareheaded adult male in white two-piece ihram with both shoulders covered sits on his heels after the two tawaf prayer units. Camera is EXACTLY directly behind his back and head, no head turn: only back of hair and nape, zero cheek/nose/eye/mouth/profile/beard. Beside him on a low ledge is a small clear cup of Zamzam water, and nearby a discreet plain beige water dispenser without any writing, appropriate to the mosque. Omit EVERY other person, including far galleries and courtyard. No human reflections, no faces anywhere, no text, UI or watermark. Full bleed editorial illustration.
```

### umrah_completion

Final WebP: `/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_completion_faceless.webp`

Source PNG: `/Users/farhanfida/.codex/generated_images/01a15e71-23ee-7130-b200-b4fe22dcdddb/exec-a5a6aa0e-8b92-4ec5-b1bf-b5e8bbb9e8bc.png`

Reference: `/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_completion_faceless.webp`

Prompt:

```text
Edit the supplied illustration into a 1024x1536 portrait. Preserve its modest male pilgrim with a freshly shaved head, white ihram wrap with both shoulders covered, and warm cream Masjid al-Haram courtyard / distant Kaaba setting. Keep refined outlined flat cel shading in muted cream, slate blue and gold. Essential change: EXACT STRAIGHT REAR VIEW of the pilgrim, camera directly behind spine and centered back of head; head faces straight away. Only back of shaved scalp and nape visible, no cheek, eye, nose, mouth, beard or side profile on either side. No face surfaces, not erased face or blank oval. Remove ALL other people, even tiny distant people, from courtyard and galleries. Remove all human reflections. This shows Umrah completion after the haircut, not an active haircut inside the mosque. No text, letters, UI or watermark.
```

### umrah_sai

Final WebP: `/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_sai_faceless.webp`

Source PNG: `/Users/farhanfida/.codex/generated_images/01a15e71-23ee-7130-b200-b4fe22dcdddb/exec-8014e06f-3bb1-4932-8ac8-9224bbe2d4df.png`

Reference: `/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_sai_faceless.webp`

Prompt:

```text
Edit the supplied portrait illustration, 1024x1536. Keep the recognizable modern Safa–Marwah sa’i gallery at Masjid al-Haram, with long cream marble columns, ceiling lights, subtle green illuminated markers, muted warm cream/slate blue/gold palette, fine dark outlines and clean flat cel-shaded clothing folds. Keep a small group walking away, only five people total: bareheaded adult men in white two-piece ihram with both shoulders covered and adult women in long dark modest garments with headscarves. Every single person, including background figures, must be EXACT STRAIGHT REAR VIEW, camera behind their backs, all heads face directly away along gallery. No head turns, side profiles, faces, cheeks, noses, eyes, mouths or beard silhouettes. Remove all remaining distant crowds and all human reflections. The gallery continues into a calm empty background, no tiny figures beyond the five. Not blank erased faces. No text, calligraphy, labels, signs, UI or watermark. Full bleed.
```

### hajj_arafat

Final WebP: `/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/hajj_arafat_faceless.webp`

Source PNG: `/Users/farhanfida/.codex/generated_images/01a15e71-23ee-7130-b200-b4fe22dcdddb/exec-6b4bd540-01a5-477f-8b1d-c63356734af0.png`

Reference: `/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/hajj_arafat_faceless.webp`

Prompt:

```text
Completely revise the supplied portrait Arafat illustration into 1024x1536. The original contains faces and too much photorealism. Use fine dark outlines and flat cel-shaded broad shapes like elegant illustrated pilgrimage guide cards, muted warm cream, dusty slate blue, pale sky and soft gold, low texture, no photorealistic skin. Scene: the open plain of Arafat in afternoon light, low rocky terrain and a small distant hill with modest white marker, sparse distant shade tents, absolutely no Kaaba or Haram mosque. Foreground: exactly THREE pilgrims seen from PERFECT STRAIGHT REAR VIEW, two bareheaded adult men in white ihram wraps covering BOTH shoulders and one adult woman in a loose slate-blue abaya and headscarf. Camera directly behind backs and heads; all gaze straight into the plain away from camera. Their hands may be raised naturally in dua in front of their chests, only backs of hands visible from behind. No person turns head. Show only hair crowns, napes, back of headscarves, no faces/profiles/cheeks/eyes/noses/mouths/beards, including silhouettes. Remove ALL background people and reflections. No text, UI or watermark. Respectful ordinary contemporary pilgrims, not prophetic figures.
```

### hajj_mina

Final WebP: `/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/hajj_mina_faceless.webp`

Source PNG: `/Users/farhanfida/.codex/generated_images/01a15e71-23ee-7130-b200-b4fe22dcdddb/exec-5e36bc51-d388-49d7-aa35-a32d7458707a.png`

Reference: `/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/hajj_mina_faceless.webp`

Prompt:

```text
Edit supplied Mina tent-city illustration, portrait 1024x1536. Preserve the recognizable valley of Mina, organized rows of off-white pointed-roof pilgrimage tents, service roads, rocky brown mountains and tall light poles. Convert detail to elegant editorial FLAT CEL-SHADED illustration with fine dark outlines, broad quiet shape layers, muted cream/slate blue/gold colors matching illustrated pilgrimage cards, less photorealistic terrain texture. Essential: remove EVERY person from every street, tent doorway, hill, background, and any reflection. Entirely PEOPLE-FREE architectural landscape. No tiny human figures, no faces, no portraits, no statues. Warm gentle morning light and pale sky. No Kaaba, no Muzdalifah camping mats, no lettering, signs, UI, watermark or border.
```

### hajj_jamarat

Final WebP: `/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/hajj_jamarat_faceless.webp`

Source PNG: `/Users/farhanfida/.codex/generated_images/01a15e71-23ee-7130-b200-b4fe22dcdddb/exec-38960d46-e2c5-4d1a-b5a7-a8726c0965fa.png`

Reference: `/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/hajj_jamarat_faceless.webp`

Prompt:

```text
Edit the supplied illustration into 1024x1536 portrait. Preserve the geographically recognizable modern Jamarat complex in Mina: the large elongated vertical stone Jamrah wall set inside an oval pebble collection basin, multiple pale cream concrete pedestrian levels, slender rails, shade canopies and background rocky hills. The scene is an architectural close view showing the stoning basin clearly. REMOVE EVERY PERSON from foreground, distant basin edges, upper galleries, bridges, doorways, background, and reflections. Absolutely people-free, no tiny human shapes or faces anywhere. Change photorealistic details into refined dark-outline flat cel-shaded editorial artwork, quiet broad shade shapes in muted warm cream, slate blue, soft gold; no gritty realism. No letters, signs, arrows, numbers, calligraphy, UI or watermark, no border.
```

### hajj_muzdalifah

Final WebP: `/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/hajj_muzdalifah.webp`

Source PNG: `/Users/farhanfida/.codex/generated_images/01a15e71-23ee-7130-b200-b4fe22dcdddb/exec-232d3e59-6327-44d8-b02f-0ce0403b6806.png`

Reference: `None`

Prompt:

```text
Use case: illustration-story. Create one finished 1024x1536 portrait illustration for an accurate Hajj guide, depicting the NIGHT at MUZDALIFAH. A wide open arid plain between low dark rocky hills, under a deep muted slate-blue starry night sky. The foreground contains two simple empty woven sleeping mats laid on the open ground, folded cream blankets, a plain reusable water bottle and small unmarked travel satchel. In the distance a modest mosque silhouette and tall modern floodlights create small warm golden pools of light on the plain. This is open-air resting at Muzdalifah, NOT the white tent city of Mina: no rows of pointed pilgrimage tents, no Kaaba, no domed fantasy city. NO PEOPLE whatsoever, no faces, no human silhouettes, no portraits, no mannequins, no reflections. A respectful peaceful pause in the journey. Elegant refined editorial outlined FLAT CEL-SHADED artwork, fine dark linework, broad clean planes, restrained warm cream and soft gold accents against slate blue, similar to a sophisticated illustrated pilgrimage learning card. Not photography, not 3D. No text, lettering, labels, arrows, UI, border or watermark.
```

## Verification

All ten outputs are 1024 × 1536, all referenced image paths exist, and the two edited content files pass formatting and Dart analysis. The ten WebP files total 1,830,170 bytes. No tests or simulators were run.
