# Umrah illustrations

Created 2026-10-21 using the built-in `image_gen.imagegen` tool. Six individual full-bleed illustrations were generated, visually reviewed, and exported to WebP. No CLI/API generation fallback was used.

## Art direction

The user's attached IMG_0895.jpg, IMG_0896.jpg, and IMG_0897.jpg were visual references. The new illustrations use cel-shaded adult pilgrims, thin ink contours, ivory garments, slate shadows, pale blue sky, warm beige mosque architecture, and atmospheric background softness. No text, UI, captions, or frames are baked into the assets. The app should draw its own caption contrast gradient.

These are narrative illustrations, not diagrams or exact architectural records. Ritual counts, direction, clothing details, green-marker instructions, and individual circumstances must be explained in the accompanying researched guide. The Kaaba's decorative gold bands are simplified geometric ornament rather than invented sacred text.

## Delivered assets

All six assets are 1024 × 1536 pixels, 2:3 portrait, opaque WebP. Original generated PNG files were left intact at the source paths below.

| Asset | Bytes | Original selected PNG |
| --- | ---: | --- |
| `assets/images/learn/umrah_overview.webp` | 119396 | `/Users/farhanfida/.codex/generated_images/01a15e71-e2bf-72a3-b810-dd7100b962de/exec-59741425-35fa-4fcf-9930-c55c51e2877c.png` |
| `assets/images/learn/umrah_ihram.webp` | 84934 | `/Users/farhanfida/.codex/generated_images/01a15e71-e2bf-72a3-b810-dd7100b962de/exec-f9a7f817-fb3d-451d-bc71-c2eaef8fea3c.png` |
| `assets/images/learn/umrah_tawaf.webp` | 118302 | `/Users/farhanfida/.codex/generated_images/01a15e71-e2bf-72a3-b810-dd7100b962de/exec-6fc9bd80-f030-4f7f-b455-ccb5bd9e44e1.png` |
| `assets/images/learn/umrah_prayer.webp` | 105600 | `/Users/farhanfida/.codex/generated_images/01a15e71-e2bf-72a3-b810-dd7100b962de/exec-fd0b24b5-ce57-48d4-94c4-82b515bc167b.png` |
| `assets/images/learn/umrah_sai.webp` | 112718 | `/Users/farhanfida/.codex/generated_images/01a15e71-e2bf-72a3-b810-dd7100b962de/exec-b18fce09-32dd-488a-aa35-b69d2e3d46e3.png` |
| `assets/images/learn/umrah_completion.webp` | 86416 | `/Users/farhanfida/.codex/generated_images/01a15e71-e2bf-72a3-b810-dd7100b962de/exec-bf486520-3b72-41b7-af85-1843006bfc3a.png` |

Total runtime asset size: 627,366 bytes (approximately 613 KiB).

Export: `cwebp -quiet -q 86 -m 6 <selected-source.png> -o <asset.webp>`. The export preserves dimensions and performs only format compression, without crop, compositing, or color alteration.

## Visual review

- Overview and tawaf show the Kaaba with simplified gold geometric ornament, a warm mosque setting, and small pilgrims.
- The refined tawaf image shows the foreground man walking across the courtyard with the Kaaba on his left, right shoulder uncovered and left shoulder covered. Nearby pilgrims follow the same flow, and women remain modestly fully covered.
- Ihram shows both shoulders covered at a quiet miqat-style mosque without the Kaaba.
- Prayer shows a seated pilgrim with both shoulders covered, placed away from the busy flow.
- Sa'i shows a broad white indoor gallery with green lighting and modestly dressed pilgrims.
- Completion shows a clearly shaved head with both shoulders covered.
- Foreground anatomy, garment outlines, absence of UI/text, and consistent 2:3 framing were reviewed. Architectures and crowds remain illustrative.
- The app should keep essential instructional content outside image pixels and provide accessible descriptions.

## Initial generation prompts

Each block is the exact prompt used for the individual initial generation. `transparent_background` was false. New generations omitted reference-path arguments.

### umrah_overview

```text
Use case: illustration-story.
Asset type: portrait 2:3 editorial narrative illustration for an Umrah guide in a polished mobile app.
Style/medium: refined 2D cel-shaded illustration, elegant thin near-black ink contours on foreground pilgrims, broad crisp ivory fabric folds with slate blue-gray and navy shadow planes, slightly painterly grain, warm beige mosque architecture softly defocused in layers. Natural adult proportions, very restrained facial features. Soft atmospheric light and gentle depth of field translated into painted illustration. Matches a premium Hajj educational editorial card aesthetic: ivory, muted sandstone, very pale powder blue sky, dark blue-black, tiny restrained warm gold accents. Sophisticated and quiet, neither cartoon emoji nor photorealism nor 3D render.
Composition/framing: standalone full-bleed portrait image, approximately 1024 by 1536. Subject centered mostly in upper two-thirds; rich darker natural foreground in lower quarter to support live white app text overlay. Do not draw text or any overlay. No card outline or corner treatment.
Constraints: no text, no UI, no borders, no logos, no watermark, no lettering or invented Arabic calligraphy. On the Kaaba, any gold decoration must be simplified nonlinguistic embroidery from a distance. No Hajj-only sites or rituals such as Arafat, Mina, or stone throwing. Present respectful contemporary Umrah imagery.
Scene: a majestic Kaaba seen from a low respectful three-quarter view in the Grand Mosque courtyard in Makkah. Correct recognizable cubic Kaaba form, dark black kiswah with a restrained gold embroidered band, warm cream colonnade and two slender cream minarets behind, pale blue sky and soft sunrise. Small pilgrims in white and modest dark garments at the bottom provide scale. Architecture and Kaaba dominate, crowd is calm and not packed. Render the Kaaba as elegant flat navy-black planes with subtle texture, foreground people as soft silhouette shapes. No large foreground face.
```

### umrah_ihram

```text
Use case: illustration-story.
Asset type: portrait 2:3 editorial narrative illustration for an Umrah guide in a polished mobile app.
Style/medium: refined 2D cel-shaded illustration, elegant thin near-black ink contours on foreground pilgrims, broad crisp ivory fabric folds with slate blue-gray and navy shadow planes, slightly painterly grain, warm beige mosque architecture softly defocused in layers. Natural adult proportions, very restrained facial features. Soft atmospheric light and gentle depth of field translated into painted illustration. Matches a premium Hajj educational editorial card aesthetic: ivory, muted sandstone, very pale powder blue sky, dark blue-black, tiny restrained warm gold accents. Sophisticated and quiet, neither cartoon emoji nor photorealism nor 3D render.
Composition/framing: standalone full-bleed portrait image, approximately 1024 by 1536. Subject centered mostly in upper two-thirds; rich darker natural foreground in lower quarter to support live white app text overlay. Do not draw text or any overlay. No card outline or corner treatment.
Constraints: no text, no UI, no borders, no logos, no watermark, no lettering or invented Arabic calligraphy. On the Kaaba, any gold decoration must be simplified nonlinguistic embroidery from a distance. No Hajj-only sites or rituals such as Arafat, Mina, or stone throwing. Present respectful contemporary Umrah imagery.
Scene: a calm miqat mosque courtyard with simple sandstone arches and a quiet cream minaret, pale blue dawn sky. One adult male pilgrim with medium warm brown skin and short dark hair, shown from behind in three-quarter profile, wearing two plain white unstitched ihram cloths with his upper wrap draped over BOTH SHOULDERS. Frame from head to below hips. No cap, no shirt, no robe sleeves, no belt visible. His posture is composed and contemplative, hands naturally resting. Crisp thin black outlines and sculpted slate-shadowed ivory cloth in foreground, soft luminous beige mosque in background. Do not show Kaaba here. Both shoulders must be fully covered.
```

### umrah_tawaf

```text
Use case: illustration-story.
Asset type: portrait 2:3 editorial narrative illustration for an Umrah guide in a polished mobile app.
Style/medium: refined 2D cel-shaded illustration, elegant thin near-black ink contours on foreground pilgrims, broad crisp ivory fabric folds with slate blue-gray and navy shadow planes, slightly painterly grain, warm beige mosque architecture softly defocused in layers. Natural adult proportions, very restrained facial features. Soft atmospheric light and gentle depth of field translated into painted illustration. Matches a premium Hajj educational editorial card aesthetic: ivory, muted sandstone, very pale powder blue sky, dark blue-black, tiny restrained warm gold accents. Sophisticated and quiet, neither cartoon emoji nor photorealism nor 3D render.
Composition/framing: standalone full-bleed portrait image, approximately 1024 by 1536. Subject centered mostly in upper two-thirds; rich darker natural foreground in lower quarter to support live white app text overlay. Do not draw text or any overlay. No card outline or corner treatment.
Constraints: no text, no UI, no borders, no logos, no watermark, no lettering or invented Arabic calligraphy. On the Kaaba, any gold decoration must be simplified nonlinguistic embroidery from a distance. No Hajj-only sites or rituals such as Arafat, Mina, or stone throwing. Present respectful contemporary Umrah imagery.
Scene: a wide inviting view of the Kaaba courtyard at the Grand Mosque in Makkah with the Kaaba upper center, cream arcade and softly hazy minarets behind. Small respectfully spaced contemporary pilgrims walking calmly in the open courtyard, mostly white ihram with a few modest dark garments. View from within the courtyard at human height, Kaaba recognizable, broad expanse and depth. No directional arrows, no diagram, no clearly choreographed misleading line, no people climbing or touching the Kaaba. In lower foreground include backs of a few quiet pilgrims as subtle slate and ivory shapes. Soft morning golden light, pale powder blue sky.
```

### umrah_prayer

```text
Use case: illustration-story.
Asset type: portrait 2:3 editorial narrative illustration for an Umrah guide in a polished mobile app.
Style/medium: refined 2D cel-shaded illustration, elegant thin near-black ink contours on foreground pilgrims, broad crisp ivory fabric folds with slate blue-gray and navy shadow planes, slightly painterly grain, warm beige mosque architecture softly defocused in layers. Natural adult proportions, very restrained facial features. Soft atmospheric light and gentle depth of field translated into painted illustration. Matches a premium Hajj educational editorial card aesthetic: ivory, muted sandstone, very pale powder blue sky, dark blue-black, tiny restrained warm gold accents. Sophisticated and quiet, neither cartoon emoji nor photorealism nor 3D render.
Composition/framing: standalone full-bleed portrait image, approximately 1024 by 1536. Subject centered mostly in upper two-thirds; rich darker natural foreground in lower quarter to support live white app text overlay. Do not draw text or any overlay. No card outline or corner treatment.
Constraints: no text, no UI, no borders, no logos, no watermark, no lettering or invented Arabic calligraphy. On the Kaaba, any gold decoration must be simplified nonlinguistic embroidery from a distance. No Hajj-only sites or rituals such as Arafat, Mina, or stone throwing. Present respectful contemporary Umrah imagery.
Scene: one adult male Umrah pilgrim in plain ivory ihram cloth with BOTH shoulders covered, shown from behind and slightly to the side, kneeling calmly in seated prayer on a small understated warm sand-colored prayer rug in a quiet peripheral courtyard of the Grand Mosque. His seated pose is natural and respectful, hands resting on thighs, no raised hands. He is clearly well away from the busy pedestrian route. Warm cream mosque arches, distant tiny pilgrims in another area, soft early morning light. Architecturally neutral mosque backdrop without a visible Kaaba, not a crowded central circumambulation path. Thin ink outline on man, natural proportions, beautiful folded cloth shaded slate blue-gray. No inappropriate objects, no arrows.
ART DIRECTION, VERY IMPORTANT: This is a hand-drawn 2D animation-film still, NOT a realistic image. Use large unbroken simple flat color regions, only two or three bold flat shading planes on cloth, clearly visible thin black contour ink, no photographic surface detail, no realistically textured cloth, no shiny photoreal marble, no minute architectural details. Substantially simplify the background to softly blurred painted warm beige arches. The rendering must look like a sophisticated graphic-novel/animated documentary illustration in muted flat colors, as if manually painted. Keep the palette muted pale powder blue and cream with slate shadows, not saturated blue skies. Darken lower quarter gently.
```

### umrah_sai

```text
Use case: illustration-story.
Asset type: portrait 2:3 editorial narrative illustration for an Umrah guide in a polished mobile app.
Style/medium: refined 2D cel-shaded illustration, elegant thin near-black ink contours on foreground pilgrims, broad crisp ivory fabric folds with slate blue-gray and navy shadow planes, slightly painterly grain, warm beige mosque architecture softly defocused in layers. Natural adult proportions, very restrained facial features. Soft atmospheric light and gentle depth of field translated into painted illustration. Matches a premium Hajj educational editorial card aesthetic: ivory, muted sandstone, very pale powder blue sky, dark blue-black, tiny restrained warm gold accents. Sophisticated and quiet, neither cartoon emoji nor photorealism nor 3D render.
Composition/framing: standalone full-bleed portrait image, approximately 1024 by 1536. Subject centered mostly in upper two-thirds; rich darker natural foreground in lower quarter to support live white app text overlay. Do not draw text or any overlay. No card outline or corner treatment.
Constraints: no text, no UI, no borders, no logos, no watermark, no lettering or invented Arabic calligraphy. On the Kaaba, any gold decoration must be simplified nonlinguistic embroidery from a distance. No Hajj-only sites or rituals such as Arafat, Mina, or stone throwing. Present respectful contemporary Umrah imagery.
Scene: modern Safa and Marwah sa'i gallery inside the Grand Mosque in Makkah. Broad luminous white marble walkway with repeated graceful white mosque columns, high pale ceiling, clearly visible paired understated green illuminated marker strips overhead in the middle distance. A few adult pilgrims walk calmly along the broad gallery, seen mostly from behind, wearing ivory ihram cloth draped over both shoulders; a few women in modest long garments among distant pilgrims. No one running in this scene. Accurate indoor white architectural character, no outdoor desert, no Kaaba, no invented hillside in the corridor, no directional arrows or signage text. Perspective leads inward toward softly defocused white-and-cream architecture. Thin ink contours on nearest people, ivory drapery with slate shadows, restrained luminous green lights.
ART DIRECTION, VERY IMPORTANT: This is a hand-drawn 2D animation-film still, NOT a realistic image. Use large unbroken simple flat color regions, only two or three bold flat shading planes on cloth, clearly visible thin black contour ink, no photographic surface detail, no realistically textured cloth, no shiny photoreal marble, no minute architectural details. Substantially simplify the background to softly blurred painted warm beige arches. The rendering must look like a sophisticated graphic-novel/animated documentary illustration in muted flat colors, as if manually painted. Keep the palette muted pale powder blue and cream with slate shadows, not saturated blue skies. Darken lower quarter gently.
```

### umrah_completion

```text
Use case: illustration-story.
Asset type: portrait 2:3 editorial narrative illustration for an Umrah guide in a polished mobile app.
Style/medium: refined 2D cel-shaded illustration, elegant thin near-black ink contours on foreground pilgrims, broad crisp ivory fabric folds with slate blue-gray and navy shadow planes, slightly painterly grain, warm beige mosque architecture softly defocused in layers. Natural adult proportions, very restrained facial features. Soft atmospheric light and gentle depth of field translated into painted illustration. Matches a premium Hajj educational editorial card aesthetic: ivory, muted sandstone, very pale powder blue sky, dark blue-black, tiny restrained warm gold accents. Sophisticated and quiet, neither cartoon emoji nor photorealism nor 3D render.
Composition/framing: standalone full-bleed portrait image, approximately 1024 by 1536. Subject centered mostly in upper two-thirds; rich darker natural foreground in lower quarter to support live white app text overlay. Do not draw text or any overlay. No card outline or corner treatment.
Constraints: no text, no UI, no borders, no logos, no watermark, no lettering or invented Arabic calligraphy. On the Kaaba, any gold decoration must be simplified nonlinguistic embroidery from a distance. No Hajj-only sites or rituals such as Arafat, Mina, or stone throwing. Present respectful contemporary Umrah imagery.
Scene: dignified rear three-quarter portrait of a peaceful adult male pilgrim with medium brown skin and a clearly freshly shaved head, wearing a plain white ihram upper wrap draped across BOTH shoulders. Frame from head to lower torso, upper body centered, slight side view without detailed expression. Warm Makkah mosque cream architecture softly defocused in the distance, luminous pale blue morning sky, warm sunrise gently touching shaved scalp and cloth. His posture is relaxed and quietly fulfilled after completion. No razor, no barber, no scissors, no haircut action, no bare shoulder, no crowd pressing close. Foreground cloth has graphic sweeping ivory folds and slate navy shadows, delicate black line work.
ART DIRECTION, VERY IMPORTANT: This is a hand-drawn 2D animation-film still, NOT a realistic image. Use large unbroken simple flat color regions, only two or three bold flat shading planes on cloth, clearly visible thin black contour ink, no photographic surface detail, no realistically textured cloth, no shiny photoreal marble, no minute architectural details. Substantially simplify the background to softly blurred painted warm beige arches. The rendering must look like a sophisticated graphic-novel/animated documentary illustration in muted flat colors, as if manually painted. Keep the palette muted pale powder blue and cream with slate shadows, not saturated blue skies. Darken lower quarter gently.
```

## Style refinement prompts

## Tawaf ritual precision refinement

The final tawaf image was edited once more to show plausible circulation and the recommended men's right-shoulder exposure during this tawaf. The other five images were unchanged.

- Edit target: `assets/images/learn/umrah_tawaf.webp`, the WebP export of `/Users/farhanfida/.codex/generated_images/01a15e71-e2bf-72a3-b810-dd7100b962de/exec-a8e89e9e-4e1e-486e-b35d-195be3a54b44.png`.
- Selected final source: `/Users/farhanfida/.codex/generated_images/01a15e71-e2bf-72a3-b810-dd7100b962de/exec-6fc9bd80-f030-4f7f-b455-ccb5bd9e44e1.png`.
- Visual review: foreground man's right shoulder is bare, upper cloth passes beneath his right armpit and over the left shoulder; pilgrims in front of the Kaaba move across the image toward the right, keeping the Kaaba to their left. Women remain fully covered. Architecture, palette, and 2:3 framing were preserved.

```text
Use case: precise-object-edit.
Edit the supplied portrait Umrah illustration. Preserve exactly its beautiful cel-shaded 2D editorial style, ivory and slate fabric, thin black contours, pale powder-blue sky, warm beige architecture, soft painted depth, Kaaba architecture, 2:3 portrait frame, and visual density. No text, UI, arrows, maps, labels or watermarks.
Change only pilgrim clothing and walking orientation to make this a visually plausible tawaf scene. The large dark-haired adult male in the lower left foreground is now walking calmly ACROSS the picture from LEFT TO RIGHT, in a natural three-quarter right-side/rear view, rather than directly toward the Kaaba. The Kaaba is to HIS LEFT as he proceeds around it. His RIGHT shoulder, the shoulder nearest the viewer in this orientation, must be clearly BARE and visible; his white upper ihram cloth passes under his RIGHT armpit and over his LEFT shoulder. His torso and waist remain modestly covered by the draped cloth. Show his head and face in a subtle profile oriented toward the right edge, and a relaxed natural walking posture. Do not mirror the shoulder arrangement.
The fully covered woman in the lower right foreground also walks calmly toward the RIGHT edge along the same circular flow; her head and body remain modestly fully covered with the same navy abaya. Nearby pilgrims in FRONT of the Kaaba should also move LEFT TO RIGHT along its face, gently curving around its right side in the distance. Do not make everyone walk straight toward the Kaaba wall. Most men performing this tawaf have right shoulders uncovered and left shoulders covered; women remain fully covered. Keep crowd calm, anatomy coherent, no running and no forced diagrammatic rows.
Keep all architectural parts and the Kaaba in the same positions and preserve the overall portrait framing.
```


The initial overview, ihram, and tawaf images rendered with more surface detail than the references. They were each edited once using the built-in tool. Input 1 was the generated target, input 2 was the user-supplied style reference. The original targets were retained.

### umrah_overview

- Edit target: `/Users/farhanfida/.codex/generated_images/01a15e71-e2bf-72a3-b810-dd7100b962de/exec-9d9b1096-38ce-40d2-bd9b-e684387e3ce2.png`
- Style reference: `/Users/farhanfida/Downloads/IMG_0895.jpg`

```text
Use case: style-transfer.
Image 1 is the edit target. Image 2 is ONLY a visual style reference; ignore all of its text and UI.
Restyle Image 1 to closely match the restrained hand-drawn cel-shaded editorial illustration aesthetic of Image 2. Preserve the composition, subject, proportions, portrait aspect ratio and ritual context of Image 1. Replace photoreal detail with simplified graphic drawn shapes, flat broad slate and navy shadow planes, thin black ink outlines on people, soft pale powder-blue sky, warm beige painted architecture, tiny restrained gold accents and subtle painterly grain. Simplify architecture significantly and soften the background with atmospheric defocus like Image 2. Cloth must be smooth bold ivory and blue-gray color planes, not realistically textured. Sky should be very muted pale powder-blue, not vivid blue. Do not copy any letters, cards, icon, frame or UI from Image 2. Final is a standalone full-bleed portrait illustration with NO text, NO watermark, NO borders, NO UI and NO fake Arabic calligraphy. Replace small Kaaba script-like details with very subtle simple gold nonlinguistic geometric embroidery. Preserve men's white ihram and both shoulders covered wherever already covered. Keep natural anatomically coherent body shapes and hands. This is an elegant 2D animated documentary still, not 3D, not photorealistic, not a simplistic flat icon.
```

### umrah_ihram

- Edit target: `/Users/farhanfida/.codex/generated_images/01a15e71-e2bf-72a3-b810-dd7100b962de/exec-33aa4f30-79c0-4e54-81ee-53212163e6ce.png`
- Style reference: `/Users/farhanfida/Downloads/IMG_0896.jpg`

```text
Use case: style-transfer.
Image 1 is the edit target. Image 2 is ONLY a visual style reference; ignore all of its text and UI.
Restyle Image 1 to closely match the restrained hand-drawn cel-shaded editorial illustration aesthetic of Image 2. Preserve the composition, subject, proportions, portrait aspect ratio and ritual context of Image 1. Replace photoreal detail with simplified graphic drawn shapes, flat broad slate and navy shadow planes, thin black ink outlines on people, soft pale powder-blue sky, warm beige painted architecture, tiny restrained gold accents and subtle painterly grain. Simplify architecture significantly and soften the background with atmospheric defocus like Image 2. Cloth must be smooth bold ivory and blue-gray color planes, not realistically textured. Sky should be very muted pale powder-blue, not vivid blue. Do not copy any letters, cards, icon, frame or UI from Image 2. Final is a standalone full-bleed portrait illustration with NO text, NO watermark, NO borders, NO UI and NO fake Arabic calligraphy. Replace small Kaaba script-like details with very subtle simple gold nonlinguistic geometric embroidery. Preserve men's white ihram and both shoulders covered wherever already covered. Keep natural anatomically coherent body shapes and hands. This is an elegant 2D animated documentary still, not 3D, not photorealistic, not a simplistic flat icon.
```

### umrah_tawaf

- Edit target: `/Users/farhanfida/.codex/generated_images/01a15e71-e2bf-72a3-b810-dd7100b962de/exec-ce17be0f-e48a-4073-a773-b00455c41ba8.png`
- Style reference: `/Users/farhanfida/Downloads/IMG_0895.jpg`

```text
Use case: style-transfer.
Image 1 is the edit target. Image 2 is ONLY a visual style reference; ignore all of its text and UI.
Restyle Image 1 to closely match the restrained hand-drawn cel-shaded editorial illustration aesthetic of Image 2. Preserve the composition, subject, proportions, portrait aspect ratio and ritual context of Image 1. Replace photoreal detail with simplified graphic drawn shapes, flat broad slate and navy shadow planes, thin black ink outlines on people, soft pale powder-blue sky, warm beige painted architecture, tiny restrained gold accents and subtle painterly grain. Simplify architecture significantly and soften the background with atmospheric defocus like Image 2. Cloth must be smooth bold ivory and blue-gray color planes, not realistically textured. Sky should be very muted pale powder-blue, not vivid blue. Do not copy any letters, cards, icon, frame or UI from Image 2. Final is a standalone full-bleed portrait illustration with NO text, NO watermark, NO borders, NO UI and NO fake Arabic calligraphy. Replace small Kaaba script-like details with very subtle simple gold nonlinguistic geometric embroidery. Preserve men's white ihram and both shoulders covered wherever already covered. Keep natural anatomically coherent body shapes and hands. This is an elegant 2D animated documentary still, not 3D, not photorealistic, not a simplistic flat icon.
```

