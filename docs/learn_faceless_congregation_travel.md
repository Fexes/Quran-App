# Faceless congregation, occasion and travel illustrations

Integration note: Replacement filenames gained `_faceless` after generation to prevent reuse of earlier cached artwork. Original edit inputs used the same names without that suffix.

Date: 2026-10-21

## Scope and generation method

Nine selected illustrations were produced with the built-in image_gen tool, one call per illustration, followed by four targeted head-direction revisions. No CLI/API image generation or procedural image substitutes were used. Six pre-existing assets were viewed before editing. The original IMG_0895.jpg, IMG_0896.jpg and IMG_0897.jpg references informed the muted cream, slate-blue and gold cel-shaded illustration style; IMG_0897.jpg was supplied as the style-only reference for the six replacements. Its app interface and text were excluded from every output.

All PNG originals remain in the generated_images directory listed below. Selected PNGs were encoded to WebP with cwebp -q 84 -m 6, without resizing, cropping, compositing, drawing or other content edits. Final dimensions are 1024 by 1536 pixels. All nine current WebPs total 1,145,674 bytes at this handoff.

Only image, imageDescription and coverDescription metadata changed in the five owned Dart files. A comparison against the pre-edit snapshots with the four allowed image fields removed confirmed the remaining content was byte-for-byte unchanged. No religious prose, Arabic, transliteration, sources, chapter structure or behavior was edited. No tests or simulators were run.

## Chapter and cover relevance audit

| Cover or chapter | Final filename at handoff | Relevance |
| --- | --- | --- |
| Congregation cover | congregation_faceless.webp | Aligned standing rows, imam ahead facing away. |
| congregation-follow | congregation_faceless.webp | The congregation follows the imam; everyone is seen from behind. |
| congregation-join | congregation_faceless.webp | A coherent active congregation for joining the imam. |
| congregation-complete | congregation_complete.webp | Latecomer stands to complete missed units while others remain seated. |
| Eid cover | eid_faceless.webp | Outdoor Eid rows in morning light after sunrise. |
| eid-prepare | eid_faceless.webp | Eid gathering context and appropriate morning light. |
| eid-pray | eid_faceless.webp | Outdoor congregational Eid prayer replaces unrelated solo prayer. |
| Jumuah cover | jumuah_faceless.webp | Seated congregation settling in the mosque before the sermon. |
| jumuah-prepare | jumuah_faceless.webp | Seated Friday gathering; no front-facing preacher is shown. |
| jumuah-pray | jumuah_prayer.webp | Standing Friday rows behind the imam replace solo prayer. |
| Janazah cover | janazah_faceless.webp | Standing funeral rows before an opaque covered bier. |
| janazah-prepare | janazah_faceless.webp | The funeral setting is explicit and dignified. |
| janazah-first | janazah_faceless.webp | Standing funeral context replaces unrelated solo prayer. |
| janazah-finish | janazah_faceless.webp | The congregation remains standing at the funeral. |
| Travel and illness cover | prayer_travel_faceless_mat.webp | A traveller stands in prayer, travel bag nearby. |
| travel-shorten | prayer_travel_faceless_mat.webp | Quiet travel setting, rear view of a modest traveller. |
| travel-combine | prayer_travel_faceless_mat.webp | The same coherent travel prayer scene. |
| illness-sitting | prayer_illness_faceless_mat.webp | Seated chair prayer, upright torso and feet supported. |
| illness-bed | illness_bed.webp | Actual side-lying bed posture replaces the chair image. |

All final files are under /Users/farhanfida/Desktop/Quran/quran/assets/images/learn/. The root agent may version these filenames centrally after this handoff to invalidate Flutter's image cache.

## Face and posture verification

Each selected final WebP was opened individually at its original 1024 by 1536 resolution and visually inspected across the whole frame, including all background participants. No visible eyes, noses, mouths, cheeks, front-facing heads, facial profiles, portraits or reflected faces remain. Faces are hidden by actual rear viewpoints, never erased, blurred, masked or painted blank. Back-of-head hair, the nape and the backs of ears are visible where natural.

| Asset | Inspection |
| --- | --- |
| congregation_faceless.webp | Both rows and imam face directly away; no front-facing imam or background people. |
| congregation_complete.webp | Standing latecomer and all seated people face away. |
| eid_faceless.webp | All rows and imam viewed from behind; no background bystanders. |
| jumuah_faceless.webp | Seated rows face away, including small background figures; preacher absent from frame. |
| jumuah_prayer.webp | Standing rows and imam face away; empty minbar does not contain a figure. |
| janazah_faceless.webp | All participants face away; fully opaque covered bier contains no visible body details. |
| prayer_travel_faceless_mat.webp | Single traveller shown directly from behind; no other people or mirrors. |
| prayer_illness_faceless_mat.webp | Single worshipper viewed directly behind the chair; no face or reflection. |
| illness_bed.webp | Only the back of the head and neck are visible; person lies horizontally under an opaque blanket. |

The bed scene illustrates the guide's permitted side-lying alternative, with the right side resting on the bed, head supported and face directed away from the viewer. The referenced Hanafi guidance permits lying on the side, preferably the right, facing the qibla, while noting that lying on the back with the head supported is the preferred Hanafi option. The image is contextual and does not attempt to establish a geographic qibla bearing or demonstrate sequential head movements. No object is raised to the forehead. Source checked: [SeekersGuidance: Can I Pray Laying Down Due to Sickness and Surgery?](https://seekersguidance.org/answers/hanafi-fiqh/can-i-pray-laying-down-due-to-sickness-and-surgery-if-so-how/).

The initial seated Jumuah draft showed small cheek and beard profiles and was revised before acceptance. Additional strict head-direction refinements were applied to congregation, standing Jumuah and Janazah. Those final encodings were inspected again at original resolution.

## Selected sources and exact prompts

### congregation

Final WebP: /Users/farhanfida/Desktop/Quran/quran/assets/images/learn/congregation_faceless.webp

Selected PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-bae3e1ff-78a1-4dcf-9a42-5d66650071a8.png

Initial prompt:

```text
Use case: style-transfer. Input image 1 is the existing congregation scene to rebuild; input image 2 is only the style reference (ignore all UI/text in it). Preserve the subject of prayer rows inside a mosque, but replace its current angle and rendering with the flat illustrated style below. Camera exactly centered behind the rows, level with their upper backs. Show two or three straight rows of modest adult male worshippers standing, evenly aligned, with one imam beyond them ALSO FACING DIRECTLY AWAY, his BACK visible. EVERY head points at the mihrab, directly away from camera; no head turns or side views. Keep worshippers comparable proportions and the imam smaller with distance. Cream mosque arches and slate-blue carpet with simple gold border. A simple empty mihrab ahead. No people facing the congregation. The rear row can be naturally cropped at the lower image edge.

Asset type: Quran app Learn guide illustration, one standalone portrait image 1024 by 1536 pixels, 2:3 ratio. Style: clean hand-drawn 2D flat cel-shaded illustration with confident dark charcoal outlines, broad smooth color shapes, only two or three shadow values, muted warm cream, slate blue and restrained soft gold. Simplified soft architectural backgrounds, believable adult proportions and calm respectful mood. NOT photographic, no 3D render, no grain or hyperrealistic material detail.
ABSOLUTE REQUIREMENT: no visible human face anywhere. Show only the back of every head from a STRICT STRAIGHT REAR viewpoint, never three-quarter rear, never profile. No eyes, noses, mouths, cheeks, beard profiles, or reflected faces. All heads face directly away, parallel to the camera viewing axis. Do not erase, blur, mask or make blank faces; hide faces naturally by camera angle. No extra people in the background, no mirrors/reflections, no portraits. Fully modest clothing. No prophets depicted. No writing, calligraphy, text, UI, lettering, logos or watermarks.
```

Revision input PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-b9fbd130-93da-4167-b37f-b65572b61827.png

Selected revision prompt:

```text
Use case: precise-object-edit. Preserve this exact portrait illustration, scene, people, clothing, background, positions, colors, flat cel-shaded drawing style, and 1024x1536 size. Make ONE precise correction: orient EVERY person's HEAD perfectly straight away from camera. This includes imam and all foreground and background participants. Only BACKS OF HEADS may be visible: symmetric back-of-cap, hair at back, back-of-neck. No cheek patches or beard/jaw profiles visible below either ear. The current outer heads reveal small side cheek/jaw/beard strips; TURN the heads to face perfectly parallel away rather than converging toward the center, so these face parts are physically hidden behind the back of the skull. Keep normal human back-head anatomy, do NOT blur or erase a front-facing face, and do NOT make featureless blank faces. No head should be tilted or turned sideways. Backs of ears are acceptable; facial skin other than nape is not. Preserve all other illustration content unchanged and no text.
```

### eid

Final WebP: /Users/farhanfida/Desktop/Quran/quran/assets/images/learn/eid_faceless.webp

Selected PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-4708d202-dc28-4890-9e92-edbd8cf7078b.png

Initial prompt:

```text
Use case: style-transfer. Input image 1 is existing Eid scene to rebuild; input image 2 only supplies illustration style (ignore its UI/text). Preserve outdoor Eid congregation, but change to strict centered REAR view. Two or three straight rows of modest adult men in cream and slate robes, all standing in prayer and all facing exactly away from the viewer. A distant imam stands with his BACK to camera ahead. Soft open-air prayer ground with simple mosque architecture and a few palms at the edge, sunny warm morning after sunrise with sun sufficiently above horizon. No sunrise sun touching horizon. No people approaching from front, no side-angled participants. Calm dignified festival morning without banners. Heads only from directly behind. Simple flat cel shading.

Asset type: Quran app Learn guide illustration, one standalone portrait image 1024 by 1536 pixels, 2:3 ratio. Style: clean hand-drawn 2D flat cel-shaded illustration with confident dark charcoal outlines, broad smooth color shapes, only two or three shadow values, muted warm cream, slate blue and restrained soft gold. Simplified soft architectural backgrounds, believable adult proportions and calm respectful mood. NOT photographic, no 3D render, no grain or hyperrealistic material detail.
ABSOLUTE REQUIREMENT: no visible human face anywhere. Show only the back of every head from a STRICT STRAIGHT REAR viewpoint, never three-quarter rear, never profile. No eyes, noses, mouths, cheeks, beard profiles, or reflected faces. All heads face directly away, parallel to the camera viewing axis. Do not erase, blur, mask or make blank faces; hide faces naturally by camera angle. No extra people in the background, no mirrors/reflections, no portraits. Fully modest clothing. No prophets depicted. No writing, calligraphy, text, UI, lettering, logos or watermarks.
```

### prayer_travel

Final WebP: /Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_travel_faceless_mat.webp

Selected PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-20306ed0-4acb-4e85-b279-af20764c07d0.png

Initial prompt:

```text
Use case: style-transfer. Input image 1 is existing travel prayer scene to rebuild; image 2 style only (ignore its UI/text). Keep the quiet travel rest area, modest male traveller, compact slate-blue travel bag and shoes beside a prayer rug. REPLACE camera angle: STRICT STRAIGHT REAR VIEW, centered behind his back, head and torso facing perfectly straight away, only back of cream cap, back of neck and back of long cream tunic visible. He stands upright on a simple blue prayer mat with arms held in front of torso therefore hidden from rear view. No visible face/profile at all. Calm open-sided rest shelter with simple cream arch, distant muted blue hills, no other people. Transform all rendering to the simple outlined flat 2D cel-shaded reference style.

Asset type: Quran app Learn guide illustration, one standalone portrait image 1024 by 1536 pixels, 2:3 ratio. Style: clean hand-drawn 2D flat cel-shaded illustration with confident dark charcoal outlines, broad smooth color shapes, only two or three shadow values, muted warm cream, slate blue and restrained soft gold. Simplified soft architectural backgrounds, believable adult proportions and calm respectful mood. NOT photographic, no 3D render, no grain or hyperrealistic material detail.
ABSOLUTE REQUIREMENT: no visible human face anywhere. Show only the back of every head from a STRICT STRAIGHT REAR viewpoint, never three-quarter rear, never profile. No eyes, noses, mouths, cheeks, beard profiles, or reflected faces. All heads face directly away, parallel to the camera viewing axis. Do not erase, blur, mask or make blank faces; hide faces naturally by camera angle. No extra people in the background, no mirrors/reflections, no portraits. Fully modest clothing. No prophets depicted. No writing, calligraphy, text, UI, lettering, logos or watermarks.
```

### prayer_illness

Final WebP: /Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_illness_faceless_mat.webp

Selected PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-0e279184-3bf7-4f38-aff9-5af3b0a1bbbc.png

Initial prompt:

```text
Use case: style-transfer. Input image 1 is existing chair prayer scene to rebuild; image 2 style only (ignore its UI/text). Preserve the subject of an elderly modest male worshipper seated upright on a stable simple wooden chair for prayer at home. REPLACE viewpoint with STRICT STRAIGHT REAR view centered on his back and the back of chair; face completely hidden by natural direction. Back of cream cap and small band of gray hair only, no profile or cheek. His torso upright, knees bent naturally and both socked feet supported on floor; hands rest on thighs in front and are not prominent from the rear. Long loose cream robe covers whole body. Slate-blue mat underneath. A quiet cream wall and simple recessed arch ahead, soft warm daylight, small green plant aside. No other people, no mirrors, no photographs. Flat hand-drawn cel-shaded style.

Asset type: Quran app Learn guide illustration, one standalone portrait image 1024 by 1536 pixels, 2:3 ratio. Style: clean hand-drawn 2D flat cel-shaded illustration with confident dark charcoal outlines, broad smooth color shapes, only two or three shadow values, muted warm cream, slate blue and restrained soft gold. Simplified soft architectural backgrounds, believable adult proportions and calm respectful mood. NOT photographic, no 3D render, no grain or hyperrealistic material detail.
ABSOLUTE REQUIREMENT: no visible human face anywhere. Show only the back of every head from a STRICT STRAIGHT REAR viewpoint, never three-quarter rear, never profile. No eyes, noses, mouths, cheeks, beard profiles, or reflected faces. All heads face directly away, parallel to the camera viewing axis. Do not erase, blur, mask or make blank faces; hide faces naturally by camera angle. No extra people in the background, no mirrors/reflections, no portraits. Fully modest clothing. No prophets depicted. No writing, calligraphy, text, UI, lettering, logos or watermarks.
```

### jumuah

Final WebP: /Users/farhanfida/Desktop/Quran/quran/assets/images/learn/jumuah_faceless.webp

Selected PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-5305940f-b614-409a-afcb-d0bdf3e924e8.png

Initial prompt:

```text
Use case: style-transfer. Input image 1 is existing Friday mosque scene to rebuild; image 2 style only (ignore its UI/text). Scene for arriving and settling before the Friday sermon. STRICT centered REAR view of two or three orderly rows of modest adult men seated calmly on slate-blue mosque carpet facing toward the mihrab, all heads exactly away from camera. Back of every cap/head only. The PREACHER MUST BE COMPLETELY OUT OF FRAME, no person on a pulpit and nobody facing the listeners. A cream mosque arch/mihrab and a partial empty wooden minbar at the far right edge may suggest the setting. Use balanced clean architecture, broad flat cream/gold color shapes and inked outlines, not ornate photorealistic texture. No visible faces anywhere.

Asset type: Quran app Learn guide illustration, one standalone portrait image 1024 by 1536 pixels, 2:3 ratio. Style: clean hand-drawn 2D flat cel-shaded illustration with confident dark charcoal outlines, broad smooth color shapes, only two or three shadow values, muted warm cream, slate blue and restrained soft gold. Simplified soft architectural backgrounds, believable adult proportions and calm respectful mood. NOT photographic, no 3D render, no grain or hyperrealistic material detail.
ABSOLUTE REQUIREMENT: no visible human face anywhere. Show only the back of every head from a STRICT STRAIGHT REAR viewpoint, never three-quarter rear, never profile. No eyes, noses, mouths, cheeks, beard profiles, or reflected faces. All heads face directly away, parallel to the camera viewing axis. Do not erase, blur, mask or make blank faces; hide faces naturally by camera angle. No extra people in the background, no mirrors/reflections, no portraits. Fully modest clothing. No prophets depicted. No writing, calligraphy, text, UI, lettering, logos or watermarks.
```

Revision input PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-b954cd96-cb50-42a0-a09b-58cc75802a72.png

Selected revision prompt:

```text
Use case: precise-object-edit. Edit this portrait illustration. Preserve the mosque, seated prayer rows, clothing, palette and 1024x1536 portrait composition. Correct ONLY the HEAD DIRECTION of ALL worshippers: every head must point perfectly straight away from camera, parallel to the vertical center axis into the mihrab. In particular the three large foreground people currently have partial side cheeks and beard profiles; turn each head so we see only the symmetrical BACK of their head/hair and nape, with no visible part of any face, cheek, nose, eye, mouth or beard profile. Their heads should look like straight rear view head silhouettes, with equal small backs of ears if necessary. None should look diagonally toward the central person. Do the same for any small background heads. Do NOT erase or blur faces, do NOT paint featureless faces: the corrected camera-relative direction must physically hide every face behind the back of its head. No front-facing preacher, no text, no UI. Keep flat outlined cel-shaded cream, slate blue and gold illustration.
```

### janazah

Final WebP: /Users/farhanfida/Desktop/Quran/quran/assets/images/learn/janazah_faceless.webp

Selected PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-8e9d5cc0-8472-48fe-81a8-057d8be2b5fb.png

Initial prompt:

```text
Use case: style-transfer. Input image 1 is existing funeral prayer scene to rebuild; image 2 style only (ignore its UI/text). Preserve respectful standing funeral prayer rows and an opaque fully covered bier in front. REPLACE angle with STRICT centered STRAIGHT REAR VIEW. Two neat rows of modest adult men standing aligned, facing exactly away, backs of heads only. Imam beyond them, also facing directly away, normal proportions. An opaque cream cloth completely covers a bier horizontally before the imam, supported low and dignified; NO body, limbs, face or anatomy under cloth. Quiet mosque courtyard with simple cream arches, muted blue sky and subtle green tree. No bystanders facing viewer, no side profiles, no head turns. Flat outlined 2D cel-shaded illustration.

Asset type: Quran app Learn guide illustration, one standalone portrait image 1024 by 1536 pixels, 2:3 ratio. Style: clean hand-drawn 2D flat cel-shaded illustration with confident dark charcoal outlines, broad smooth color shapes, only two or three shadow values, muted warm cream, slate blue and restrained soft gold. Simplified soft architectural backgrounds, believable adult proportions and calm respectful mood. NOT photographic, no 3D render, no grain or hyperrealistic material detail.
ABSOLUTE REQUIREMENT: no visible human face anywhere. Show only the back of every head from a STRICT STRAIGHT REAR viewpoint, never three-quarter rear, never profile. No eyes, noses, mouths, cheeks, beard profiles, or reflected faces. All heads face directly away, parallel to the camera viewing axis. Do not erase, blur, mask or make blank faces; hide faces naturally by camera angle. No extra people in the background, no mirrors/reflections, no portraits. Fully modest clothing. No prophets depicted. No writing, calligraphy, text, UI, lettering, logos or watermarks.
```

Revision input PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-acc5cdfa-91ec-41db-b42f-8e0db0c970ae.png

Selected revision prompt:

```text
Use case: precise-object-edit. Preserve this exact portrait illustration, scene, people, clothing, background, positions, colors, flat cel-shaded drawing style, and 1024x1536 size. Make ONE precise correction: orient EVERY person's HEAD perfectly straight away from camera. This includes imam and all foreground and background participants. Only BACKS OF HEADS may be visible: symmetric back-of-cap, hair at back, back-of-neck. No cheek patches or beard/jaw profiles visible below either ear. The current outer heads reveal small side cheek/jaw/beard strips; TURN the heads to face perfectly parallel away rather than converging toward the center, so these face parts are physically hidden behind the back of the skull. Keep normal human back-head anatomy, do NOT blur or erase a front-facing face, and do NOT make featureless blank faces. No head should be tilted or turned sideways. Backs of ears are acceptable; facial skin other than nape is not. Preserve all other illustration content unchanged and no text.
```

### congregation_complete

Final WebP: /Users/farhanfida/Desktop/Quran/quran/assets/images/learn/congregation_complete.webp

Selected PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-62602f18-70d5-470a-aa8e-04ff8e32760b.png

Initial prompt:

```text
Use case: illustration-story. Show a latecomer completing missed units of prayer after the imam has finished, in a calm mosque. STRICT centered STRAIGHT REAR VIEW: one modest adult male worshipper stands in the foreground on slate-blue carpet facing straight away, back of cap/head and back of long cream robe visible; his hands held in front so unseen. Several other worshippers in two orderly rows ahead remain seated quietly, every one also viewed exactly from behind with heads parallel and pointing toward a simple cream mihrab. No one turns around or faces camera. No giant imam, no extra people beyond the rows. Soft cream arches, simple gold trim, peaceful daylight. Strong flat illustrative outlined style. No face visible, including seated people.

Asset type: Quran app Learn guide illustration, one standalone portrait image 1024 by 1536 pixels, 2:3 ratio. Style: clean hand-drawn 2D flat cel-shaded illustration with confident dark charcoal outlines, broad smooth color shapes, only two or three shadow values, muted warm cream, slate blue and restrained soft gold. Simplified soft architectural backgrounds, believable adult proportions and calm respectful mood. NOT photographic, no 3D render, no grain or hyperrealistic material detail.
ABSOLUTE REQUIREMENT: no visible human face anywhere. Show only the back of every head from a STRICT STRAIGHT REAR viewpoint, never three-quarter rear, never profile. No eyes, noses, mouths, cheeks, beard profiles, or reflected faces. All heads face directly away, parallel to the camera viewing axis. Do not erase, blur, mask or make blank faces; hide faces naturally by camera angle. No extra people in the background, no mirrors/reflections, no portraits. Fully modest clothing. No prophets depicted. No writing, calligraphy, text, UI, lettering, logos or watermarks.
```

### jumuah_prayer

Final WebP: /Users/farhanfida/Desktop/Quran/quran/assets/images/learn/jumuah_prayer.webp

Selected PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-31a030b2-e35f-458e-87f4-dc10ba1e182e.png

Initial prompt:

```text
Use case: illustration-story. Friday prayer inside a calm cream mosque, showing worshippers standing together behind their imam. STRICT centered STRAIGHT REAR camera axis behind the congregation, three straight rows of modest adult men facing perfectly away, backs of caps/heads only. Hands held in front of robes hidden from rear. The imam at front is ALSO SEEN ONLY FROM BEHIND and smaller at correct depth. Simple slate-blue carpet, large cream mihrab and an empty small wooden minbar off to one side provide Friday mosque context. No preacher facing people, no bystanders, no side profiles, no one turning head. Clean 2D flat cel shading with bold controlled outlines and limited muted cream/slate/gold palette. Calm devotional scene, no text.

Asset type: Quran app Learn guide illustration, one standalone portrait image 1024 by 1536 pixels, 2:3 ratio. Style: clean hand-drawn 2D flat cel-shaded illustration with confident dark charcoal outlines, broad smooth color shapes, only two or three shadow values, muted warm cream, slate blue and restrained soft gold. Simplified soft architectural backgrounds, believable adult proportions and calm respectful mood. NOT photographic, no 3D render, no grain or hyperrealistic material detail.
ABSOLUTE REQUIREMENT: no visible human face anywhere. Show only the back of every head from a STRICT STRAIGHT REAR viewpoint, never three-quarter rear, never profile. No eyes, noses, mouths, cheeks, beard profiles, or reflected faces. All heads face directly away, parallel to the camera viewing axis. Do not erase, blur, mask or make blank faces; hide faces naturally by camera angle. No extra people in the background, no mirrors/reflections, no portraits. Fully modest clothing. No prophets depicted. No writing, calligraphy, text, UI, lettering, logos or watermarks.
```

Revision input PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-735294e2-a834-42c3-a8d1-5115be511b49.png

Selected revision prompt:

```text
Use case: precise-object-edit. Preserve this exact portrait illustration, scene, people, clothing, background, positions, colors, flat cel-shaded drawing style, and 1024x1536 size. Make ONE precise correction: orient EVERY person's HEAD perfectly straight away from camera. This includes imam and all foreground and background participants. Only BACKS OF HEADS may be visible: symmetric back-of-cap, hair at back, back-of-neck. No cheek patches or beard/jaw profiles visible below either ear. The current outer heads reveal small side cheek/jaw/beard strips; TURN the heads to face perfectly parallel away rather than converging toward the center, so these face parts are physically hidden behind the back of the skull. Keep normal human back-head anatomy, do NOT blur or erase a front-facing face, and do NOT make featureless blank faces. No head should be tilted or turned sideways. Backs of ears are acceptable; facial skin other than nape is not. Preserve all other illustration content unchanged and no text.
```

### illness_bed

Final WebP: /Users/farhanfida/Desktop/Quran/quran/assets/images/learn/illness_bed.webp

Selected PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-303fd3c7-ae2d-4aed-9dce-f5a03b113503.png

Initial prompt:

```text
Use case: illustration-story. Respectful educational illustration of a modest adult worshipper unable to sit, praying while LYING ON THEIR RIGHT SIDE in bed, the permitted side-lying Hanafi alternative. Camera is placed behind the person's back, on the left side of their body: show ONLY the back of their gray-haired head and back of neck above an opaque blanket, never their face or profile. The right shoulder and right side of torso rest on mattress, left shoulder is above it; body is clearly lying HORIZONTALLY, not sitting up. A single low pillow supports the head naturally and the FACE POINTS COMPLETELY AWAY toward the far side of the bed, with space ahead for slight head movements. Person is awake for prayer, but no face is visible to tell expression. Long modest cream nightclothes, fully covered from shoulders to feet by smooth opaque slate-blue blanket; no exposed chest, arms or legs. Hands in front of body and hidden. Bed runs diagonally through portrait composition, simple cream bedroom, quiet soft daylight and one small bedside table. No other people, no mirrors. Do NOT put pillows or objects in front of forehead. No arrows, no anatomical diagram, no medical machinery. Natural rear angle hides face, not blank/blurred face.

Asset type: Quran app Learn guide illustration, one standalone portrait image 1024 by 1536 pixels, 2:3 ratio. Style: clean hand-drawn 2D flat cel-shaded illustration with confident dark charcoal outlines, broad smooth color shapes, only two or three shadow values, muted warm cream, slate blue and restrained soft gold. Simplified soft architectural backgrounds, believable adult proportions and calm respectful mood. NOT photographic, no 3D render, no grain or hyperrealistic material detail.
ABSOLUTE REQUIREMENT: no visible human face anywhere. Show only the back of every head from a STRICT STRAIGHT REAR viewpoint, never three-quarter rear, never profile. No eyes, noses, mouths, cheeks, beard profiles, or reflected faces. All heads face directly away, parallel to the camera viewing axis. Do not erase, blur, mask or make blank faces; hide faces naturally by camera angle. No extra people in the background, no mirrors/reflections, no portraits. Fully modest clothing. No prophets depicted. No writing, calligraphy, text, UI, lettering, logos or watermarks.
```
