# Prayer and Wudu illustrations

Created 2026-10-21 with the built-in `image_gen.imagegen` tool. Seven independent portrait illustrations were generated and visually reviewed. No CLI/API generation fallback was used.

## Visual direction and intended use

The series follows the user's reference aesthetic and the app's Umrah illustrations: refined 2D cel shading, thin ink contours, ivory loose clothing, slate shadows, warm beige mosque architecture, pale blue atmospheric light, soft background depth, and restrained painterly grain. These scenes depict everyday prayer and ablution using ordinary modest clothing, not ihram.

The illustrations support the live instructional text. They do not encode complete prayer or wudu instructions, counts, words, schools of law, or direction markers. Keep accessible descriptions and specific instructions in the guide.

## Assets

All files are opaque WebP, 1024 × 1536 pixels, portrait 2:3. Compression only used `cwebp -quiet -q 86 -m 6 <selected-source.png> -o <asset.webp>`. There was no crop, compositing, or color alteration during export. Original generated PNGs were left intact at their source paths.

| Asset | Bytes | Selected original PNG |
| --- | ---: | --- |
| `assets/images/learn/prayer_standing.webp` | 106322 | `/Users/farhanfida/.codex/generated_images/01a15e71-e2bf-72a3-b810-dd7100b962de/exec-ec0a24f3-84c6-4b70-9719-f9787368dc5d.png` |
| `assets/images/learn/prayer_bowing.webp` | 120304 | `/Users/farhanfida/.codex/generated_images/01a15e71-e2bf-72a3-b810-dd7100b962de/exec-a5684e6c-d706-4381-a701-dade7cc43eb2.png` |
| `assets/images/learn/prayer_prostration.webp` | 95888 | `/Users/farhanfida/.codex/generated_images/01a15e71-e2bf-72a3-b810-dd7100b962de/exec-b189d0e7-11f9-475d-9be6-8025f8170cbb.png` |
| `assets/images/learn/prayer_seated.webp` | 118248 | `/Users/farhanfida/.codex/generated_images/01a15e71-e2bf-72a3-b810-dd7100b962de/exec-21b6b79a-c3b2-4032-8ce2-6d02e6a9f532.png` |
| `assets/images/learn/wudu_hands.webp` | 128604 | `/Users/farhanfida/.codex/generated_images/01a15e71-e2bf-72a3-b810-dd7100b962de/exec-3e3aa4a8-46fa-440e-94fd-1602beea363e.png` |
| `assets/images/learn/wudu_face.webp` | 127848 | `/Users/farhanfida/.codex/generated_images/01a15e71-e2bf-72a3-b810-dd7100b962de/exec-1ca084a1-af3f-4b4f-a319-7f93382f1de8.png` |
| `assets/images/learn/wudu_feet.webp` | 151726 | `/Users/farhanfida/.codex/generated_images/01a15e71-e2bf-72a3-b810-dd7100b962de/exec-1d41e74b-8a2d-478c-886d-911fad045d58.png` |

Total runtime asset size: 848,940 bytes (approximately 829 KiB).

## Inspection and refinements

- Standing: ordinary loose thobe, planted feet, lowered gaze, naturally folded hands. Refined to face left and reduce figure size so the complete posture survives a centered square crop.
- Bowing: initial posture was too shallow. Edited for a flatter back, forward bend from hips, hands resting on knees, and planted feet.
- Prostration: forehead and nose at the mat, palms next to the head, knees down, toes tucked and contacting the mat. Elbows are lifted, clothing covers torso and legs.
- Seated: torso upright, legs folded beneath, hands resting on thighs, calm lowered gaze.
- Wudu hands: two coherent hands under a gentle stream over a basin; sleeves are cuffed safely clear.
- Wudu face: both hands wash the face over a basin; face and action remain visible.
- Wudu feet: one coherent foot including ankle being washed by a hand under running water. The adult is seated safely, with other leg clothed.
- All seven were inspected for pose, anatomy, modest clothing, lack of baked text/UI, and action visibility. Prayer images consistently face left.
- Existing Umrah assets were not changed.

## Initial generation prompts

Each block is the exact initial prompt. All new generations omitted reference-image arguments and set `transparent_background` to false.

### prayer_standing

```text
Use case: illustration-story.
Asset type: full-bleed portrait 1024 by 1536 narrative illustration for an Islamic learning app, same visual series as refined 2D cel-shaded Umrah education editorial cards.
Style: elegant hand-drawn 2D animation-film still. Large smooth flat color regions, two or three broad slate blue-gray shadow planes on ivory fabric, clearly visible thin near-black ink contours, naturally proportioned adults, minimal facial detail. Softly defocused painted warm beige mosque architecture and atmospheric depth, restrained ochre-gold accents, pale powder-blue light, subtly painterly grain. Beautiful graphic-novel/documentary illustration, NOT photorealism, NOT a 3D render, NOT a simplistic icon. No tiny photoreal textures, no realistic cloth weave, no shiny marble realism. Maintain graceful calm dignity.
Composition: portrait 2:3, place the COMPLETE important action including hands, face/head, feet when essential, in the central square area between y=250 and y=1280 so square cropping retains the instruction. Gentle breathing room at top and bottom. Subject and key contact points clearly visible. Soft background architecture only.
Constraints: no text, no labels, no arrows, no UI, no card borders, no watermark, no logos, no invented Arabic writing. This is everyday prayer or ablution, NOT Hajj or Umrah, so no ihram. The adult man wears ordinary loose cream long clothing, modestly covering his body. No tight clothing, no exposed torso, no dramatic gesture. Natural coherent anatomy with normal hands and limbs.
Scene: an adult male worshipper with medium warm brown skin, dark short hair and neatly trimmed beard, wearing a plain loose ankle-length cream thobe with long sleeves, standing upright in qiyam on a quiet understated sand-and-slate prayer mat in a serene mosque side area. View his full body from the LEFTWARD-facing side in three-quarter profile. Both bare feet are firmly on the mat, slightly apart, entire feet visible. His head is gently lowered toward the place of prostration. Hands rest naturally folded together in front of his upper abdomen, right hand resting over left, arms relaxed, no theatrical clasp. Show the whole body from head to feet within the central area. Warm beige blurred arches behind, soft light.
```

### prayer_bowing

```text
Use case: illustration-story.
Asset type: full-bleed portrait 1024 by 1536 narrative illustration for an Islamic learning app, same visual series as refined 2D cel-shaded Umrah education editorial cards.
Style: elegant hand-drawn 2D animation-film still. Large smooth flat color regions, two or three broad slate blue-gray shadow planes on ivory fabric, clearly visible thin near-black ink contours, naturally proportioned adults, minimal facial detail. Softly defocused painted warm beige mosque architecture and atmospheric depth, restrained ochre-gold accents, pale powder-blue light, subtly painterly grain. Beautiful graphic-novel/documentary illustration, NOT photorealism, NOT a 3D render, NOT a simplistic icon. No tiny photoreal textures, no realistic cloth weave, no shiny marble realism. Maintain graceful calm dignity.
Composition: portrait 2:3, place the COMPLETE important action including hands, face/head, feet when essential, in the central square area between y=250 and y=1280 so square cropping retains the instruction. Gentle breathing room at top and bottom. Subject and key contact points clearly visible. Soft background architecture only.
Constraints: no text, no labels, no arrows, no UI, no card borders, no watermark, no logos, no invented Arabic writing. This is everyday prayer or ablution, NOT Hajj or Umrah, so no ihram. The adult man wears ordinary loose cream long clothing, modestly covering his body. No tight clothing, no exposed torso, no dramatic gesture. Natural coherent anatomy with normal hands and limbs.
Scene: a fully covered adult male worshipper with medium brown skin, dark short hair and trimmed beard, in ordinary loose long cream thobe with long sleeves, performing ruku on a sand-and-slate mat. Strict LEFTWARD-facing side profile clearly showing the posture. His hips bend to approximately 90 degrees; his BACK IS APPROXIMATELY HORIZONTAL and straight, head aligned naturally with spine, neck neutral, gaze down. Both hands are placed on the corresponding knees with fingers naturally spread; legs mostly straight, feet planted parallel on the mat, not kneeling. No curved standing bow, no crouch, no hands floating above knees. The loose thobe follows the body naturally and covers his entire body apart from head, hands and feet. Entire body and feet contained in central square. Soft warm blurred mosque arches behind.
```

### prayer_prostration

```text
Use case: illustration-story.
Asset type: full-bleed portrait 1024 by 1536 narrative illustration for an Islamic learning app, same visual series as refined 2D cel-shaded Umrah education editorial cards.
Style: elegant hand-drawn 2D animation-film still. Large smooth flat color regions, two or three broad slate blue-gray shadow planes on ivory fabric, clearly visible thin near-black ink contours, naturally proportioned adults, minimal facial detail. Softly defocused painted warm beige mosque architecture and atmospheric depth, restrained ochre-gold accents, pale powder-blue light, subtly painterly grain. Beautiful graphic-novel/documentary illustration, NOT photorealism, NOT a 3D render, NOT a simplistic icon. No tiny photoreal textures, no realistic cloth weave, no shiny marble realism. Maintain graceful calm dignity.
Composition: portrait 2:3, place the COMPLETE important action including hands, face/head, feet when essential, in the central square area between y=250 and y=1280 so square cropping retains the instruction. Gentle breathing room at top and bottom. Subject and key contact points clearly visible. Soft background architecture only.
Constraints: no text, no labels, no arrows, no UI, no card borders, no watermark, no logos, no invented Arabic writing. This is everyday prayer or ablution, NOT Hajj or Umrah, so no ihram. The adult man wears ordinary loose cream long clothing, modestly covering his body. No tight clothing, no exposed torso, no dramatic gesture. Natural coherent anatomy with normal hands and limbs.
Scene: a fully covered adult male worshipper with medium brown skin, dark short hair and trimmed beard, in ordinary loose long cream thobe and long sleeves, performing proper sujud on a sand-and-slate mat. Clear LEFTWARD-facing side profile. His FOREHEAD AND NOSE visibly touch the prayer mat at the LEFT; the palms are flat on the mat beside his head, elbows bent and lifted away from the floor; both KNEES rest on the mat; the FEET are behind him toward the RIGHT, with toes flexed/tucked and contacting the mat, heels pointing upward. His hips raised naturally above his shoulders, torso sloping down toward head. Natural correct anatomy, all seven contact areas plausible even if far-side limbs partly occluded. No floating forehead, no forehead on hands, no bent-back ankles, no extra fingers, no outstretched arms, no elbows laid flat. Loose modest clothing fully covers torso and legs. Keep whole body, toes, hands and forehead visible in the central square. Warm mosque background softly blurred.
```

### prayer_seated

```text
Use case: illustration-story.
Asset type: full-bleed portrait 1024 by 1536 narrative illustration for an Islamic learning app, same visual series as refined 2D cel-shaded Umrah education editorial cards.
Style: elegant hand-drawn 2D animation-film still. Large smooth flat color regions, two or three broad slate blue-gray shadow planes on ivory fabric, clearly visible thin near-black ink contours, naturally proportioned adults, minimal facial detail. Softly defocused painted warm beige mosque architecture and atmospheric depth, restrained ochre-gold accents, pale powder-blue light, subtly painterly grain. Beautiful graphic-novel/documentary illustration, NOT photorealism, NOT a 3D render, NOT a simplistic icon. No tiny photoreal textures, no realistic cloth weave, no shiny marble realism. Maintain graceful calm dignity.
Composition: portrait 2:3, place the COMPLETE important action including hands, face/head, feet when essential, in the central square area between y=250 and y=1280 so square cropping retains the instruction. Gentle breathing room at top and bottom. Subject and key contact points clearly visible. Soft background architecture only.
Constraints: no text, no labels, no arrows, no UI, no card borders, no watermark, no logos, no invented Arabic writing. This is everyday prayer or ablution, NOT Hajj or Umrah, so no ihram. The adult man wears ordinary loose cream long clothing, modestly covering his body. No tight clothing, no exposed torso, no dramatic gesture. Natural coherent anatomy with normal hands and limbs.
Scene: a fully covered adult male worshipper with medium brown skin, dark short hair and trimmed beard, in ordinary loose long cream thobe with long sleeves, sitting calmly in prayer on a sand-and-slate mat. Clear LEFTWARD-facing three-quarter side profile. Torso upright, gaze lowered, legs folded underneath in a natural seated prayer posture, hands relaxed on thighs near the knees, shoulders relaxed, feet close to the body. Do not add a conspicuously pointing finger. No chair, no cross-legged yoga posture, no crossed hands, no lifted palms or gesture. Natural silhouette of loose clothing covering torso and legs, visible hands and a small glimpse of natural foot position. Entire seated figure in central square. Soft warm beige mosque arches, slight pale blue ambient light.
```

### wudu_hands

```text
Use case: illustration-story.
Asset type: full-bleed portrait 1024 by 1536 narrative illustration for an Islamic learning app, same visual series as refined 2D cel-shaded Umrah education editorial cards.
Style: elegant hand-drawn 2D animation-film still. Large smooth flat color regions, two or three broad slate blue-gray shadow planes on ivory fabric, clearly visible thin near-black ink contours, naturally proportioned adults, minimal facial detail. Softly defocused painted warm beige mosque architecture and atmospheric depth, restrained ochre-gold accents, pale powder-blue light, subtly painterly grain. Beautiful graphic-novel/documentary illustration, NOT photorealism, NOT a 3D render, NOT a simplistic icon. No tiny photoreal textures, no realistic cloth weave, no shiny marble realism. Maintain graceful calm dignity.
Composition: portrait 2:3, place the COMPLETE important action including hands, face/head, feet when essential, in the central square area between y=250 and y=1280 so square cropping retains the instruction. Gentle breathing room at top and bottom. Subject and key contact points clearly visible. Soft background architecture only.
Constraints: no text, no labels, no arrows, no UI, no card borders, no watermark, no logos, no invented Arabic writing. This is everyday prayer or ablution, NOT Hajj or Umrah, so no ihram. The adult man wears ordinary loose cream long clothing, modestly covering his body. No tight clothing, no exposed torso, no dramatic gesture. Natural coherent anatomy with normal hands and limbs.
Scene: a modest adult man with medium warm brown skin in a simple loose cream long-sleeved shirt, viewed in calm three-quarter side view at a clean simple low stone ablution basin in a quiet mosque wash area. Close focus on his two anatomically normal hands and wrists, gently rinsing and rubbing both hands under a small clear running stream from a single plain brass tap. Hands and wrists clearly visible, only two hands, realistic five-finger structure, water gently flows over hand surfaces into basin, no exaggerated splash. Sleeves modest and cuffed safely above wrists, torso covered. Head in soft profile higher in image, hands as focal point centered, architecture softly blurred warm beige. No soap, no soap bottle, no text, no jewelry, no dirty water.
```

### wudu_face

```text
Use case: illustration-story.
Asset type: full-bleed portrait 1024 by 1536 narrative illustration for an Islamic learning app, same visual series as refined 2D cel-shaded Umrah education editorial cards.
Style: elegant hand-drawn 2D animation-film still. Large smooth flat color regions, two or three broad slate blue-gray shadow planes on ivory fabric, clearly visible thin near-black ink contours, naturally proportioned adults, minimal facial detail. Softly defocused painted warm beige mosque architecture and atmospheric depth, restrained ochre-gold accents, pale powder-blue light, subtly painterly grain. Beautiful graphic-novel/documentary illustration, NOT photorealism, NOT a 3D render, NOT a simplistic icon. No tiny photoreal textures, no realistic cloth weave, no shiny marble realism. Maintain graceful calm dignity.
Composition: portrait 2:3, place the COMPLETE important action including hands, face/head, feet when essential, in the central square area between y=250 and y=1280 so square cropping retains the instruction. Gentle breathing room at top and bottom. Subject and key contact points clearly visible. Soft background architecture only.
Constraints: no text, no labels, no arrows, no UI, no card borders, no watermark, no logos, no invented Arabic writing. This is everyday prayer or ablution, NOT Hajj or Umrah, so no ihram. The adult man wears ordinary loose cream long clothing, modestly covering his body. No tight clothing, no exposed torso, no dramatic gesture. Natural coherent anatomy with normal hands and limbs.
Scene: same type of modest adult man with medium warm brown skin, short dark hair and neatly trimmed beard, wearing a simple loose cream long-sleeved shirt, leaning gently forward over a clean stone ablution basin. Clear three-quarter side view as he cups clean water in BOTH HANDS and brings the water to wash his face. Palms lightly contact his cheeks, fingers naturally below his hairline, face visible enough to understand face washing, drops fall gently into the basin beneath. Water is clear, no huge splashes, no submerged head, no closed-fist rubbing, no extra fingers. Sleeves modest and safely cuffed above wrists, ordinary loose clothing, no ihram. Main face and both hands central within square crop. Simple brass tap and warm beige softly blurred mosque wash area.
```

### wudu_feet

```text
Use case: illustration-story.
Asset type: full-bleed portrait 1024 by 1536 narrative illustration for an Islamic learning app, same visual series as refined 2D cel-shaded Umrah education editorial cards.
Style: elegant hand-drawn 2D animation-film still. Large smooth flat color regions, two or three broad slate blue-gray shadow planes on ivory fabric, clearly visible thin near-black ink contours, naturally proportioned adults, minimal facial detail. Softly defocused painted warm beige mosque architecture and atmospheric depth, restrained ochre-gold accents, pale powder-blue light, subtly painterly grain. Beautiful graphic-novel/documentary illustration, NOT photorealism, NOT a 3D render, NOT a simplistic icon. No tiny photoreal textures, no realistic cloth weave, no shiny marble realism. Maintain graceful calm dignity.
Composition: portrait 2:3, place the COMPLETE important action including hands, face/head, feet when essential, in the central square area between y=250 and y=1280 so square cropping retains the instruction. Gentle breathing room at top and bottom. Subject and key contact points clearly visible. Soft background architecture only.
Constraints: no text, no labels, no arrows, no UI, no card borders, no watermark, no logos, no invented Arabic writing. This is everyday prayer or ablution, NOT Hajj or Umrah, so no ihram. The adult man wears ordinary loose cream long clothing, modestly covering his body. No tight clothing, no exposed torso, no dramatic gesture. Natural coherent anatomy with normal hands and limbs.
Scene: respectful close view of a seated adult man washing ONE BARE FOOT including the ankle at a LOW mosque ablution basin. He is seated safely on a simple stone bench, not balancing on one leg. Ordinary loose cream trousers and long sleeve clothing modestly cover his body. The main bare foot and ankle rest low over the shallow basin, heel supported safely on the basin lip, ankle visible above the foot. A gentle clear stream from a low plain brass tap lands on the top of the foot near the ankle; ONE hand naturally rubs over the top and side of the foot to wash it including the ankle. Five natural toes clearly coherent, no extra feet or hands. His other leg is visible subtly away to the side and covered. Crop focuses on one foot, ankle, hand and water at the center, no face needed. Warm pale stone, soft slate shadows, clean uncluttered mosque wash area, no soap or excessive splash.
```

## Refinement prompts

The initial source images below were preserved. Each edit used the built-in tool with its source as `referenced_image_paths` and `transparent_background` set to false.

### prayer_bowing

Edit source: `/Users/farhanfida/.codex/generated_images/01a15e71-e2bf-72a3-b810-dd7100b962de/exec-6408efc0-524c-4365-a5b5-7255b09a90dc.png`

```text
Use case: precise-object-edit. Correct ONLY the man's bowing posture in this illustration. Keep exactly the same portrait canvas, hand-drawn cel-shaded style, warm mosque, cream loose long thobe, slate shadows, mat and calm dignified atmosphere. The current bow is not deep enough and the back is curved. Correct ruku: the upper torso must bend farther forward from the hips until the BACK IS STRAIGHT AND HORIZONTAL, forming a clear right angle with his mostly vertical legs, like an upside-down L. Head and neck align with the flat back, face looking at the mat. Both palms rest securely ON TOP OF THE CORRESPONDING KNEECAPS, fingers naturally spread, not below on the shins. Knees are not deeply bent. Both feet remain flat on the mat. Thobe stays loose and modest, fully covering torso and legs. No floating hands, no curved spine, no crouch. Whole figure within central square portion of image, clear left-facing side profile, no text, arrows, diagram lines or UI.
```

### prayer_standing

Edit source: `/Users/farhanfida/.codex/generated_images/01a15e71-e2bf-72a3-b810-dd7100b962de/exec-14ca4b85-4c14-479f-b907-eb143d9568d9.png`

```text
Use case: precise-object-edit. Keep this beautiful cel-shaded ivory-and-slate prayer illustration and its 1024x1536 portrait canvas, soft warm beige mosque architecture, natural adult proportions and ordinary loose cream long thobe. Make exactly TWO small composition changes: (1) mirror the whole man so that his nose and toes point LEFT, toward the left edge, while hands remain anatomically right hand resting on left in front; (2) pull the view back so his entire body is SMALLER and vertically centered, with the TOP OF HIS HAIR at about y=300 and BOTTOM OF FEET at about y=1240. This must leave at least 280 pixels of architecture above his head and 280 pixels of floor below feet, so a center square crop retains his COMPLETE body. His head-to-toe height should occupy only 60% of the portrait's total height. Both feet planted on the prayer mat. Keep his posture and hands folded naturally unchanged, gaze lowered and serene. Do not crop any body part, do not exaggerate head tilt, no text, no symbols, no arrows, no UI, no new objects.
```

