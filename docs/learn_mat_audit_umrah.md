# Umrah prayer mat correction

Integration note: Final project assets use `_mat` filenames to refresh the app image cache. Original edit inputs used the earlier filenames without that suffix; preserved input copies and native PNG paths remain unchanged.

Reviewed 21 October 2026. The original post-tawaf prayer image placed a seated pilgrim on a short crosswise rug, with a ledge immediately in front. It did not show enough believable space for prostration.

The accepted illustration uses a higher rear viewpoint, a narrow individual rug running toward the Kaaba, a seated pilgrim near the rear end, and a clear forward section for hands and forehead. There is no nearby obstacle in front. The Zamzam dispenser and cup remain to the left, outside the prayer space. The person's face is naturally hidden by the rear view; the courtyard and reflections contain no other people. This is an illustration layout correction, not a claim that a particular point on a mat is a religious requirement.

Built-in imagegen produced both drafts. The first draft was rejected because it did not preserve the water dispenser and did not make forward space sufficiently clear. Only the second output was encoded into the project using cwebp at quality 88, method 6. No illustration content was changed with other tools.

Final asset at generation handoff: `/Users/farhanfida/Desktop/Quran/quran/assets/images/learn/umrah_prayer_faceless_mat.webp`.

Selected PNG: `/Users/farhanfida/.codex/generated_images/01a15e70-957a-7121-967d-884215793f60/exec-bc964548-87c0-468c-9518-bd67c6d33a3a.png`.

Unselected first PNG: `/Users/farhanfida/.codex/generated_images/01a15e70-957a-7121-967d-884215793f60/exec-d0f9e4ad-8fdf-4396-9eb5-a8a8a8928026.png`.

## Exact selected prompt

Input 1 was the first generated draft. Input 2 was the revised seated prayer illustration as a layout reference. Neither supplied image was treated as a source of religious instructions.

```text
Use case: precise-object-edit. Input 1 is the Umrah prayer composition to refine; input 2 supplies the correct seat-on-a-long-mat spatial arrangement only. Make one 1024x1536 portrait illustration. Keep the same warm cream / slate blue / gold flat cel shading, dark contour lines, a single bareheaded adult male in white ihram with both shoulders covered, and the Kaaba centered ahead. Fix the mat and camera composition carefully: camera is HIGH DIRECTLY BEHIND the worshipper, angled downward about 45 degrees so we can see the actual EMPTY FRONT HALF of his prayer mat. His whole seated body is smaller in the lower part of the frame, centered over the REAR QUARTER of one ordinary individual mat. Long mat axis runs toward the Kaaba. The rug is realistically about 80 cm wide and 140 cm long, just wider than the seated man's knees and hands, not a broad carpet or corridor runner. Show a substantial continuous empty rectangle of rug ahead of the knees, visible above and around the seated body, sufficient to place the hands and forehead on it during sujud. Keep a small rear border behind his feet. No ledge, steps, barriers or objects ahead of the mat. ADD back a small plain Zamzam water dispenser and a clear cup on a little low shelf well to the LEFT SIDE of the rug, completely outside the prayer space. No other people or human reflections. STRICT NO VISIBLE FACES: exact rear orientation, head directed completely away, no facial profile, cheek, eye, nose, mouth, or reflected face. No face erasing or blur. Keep valid modest seated prayer posture. No text, numbers, UI, symbols, calligraphy, labels, arrows, logos or watermark.
```

## Initial prompt, unselected draft

The first input was the existing Umrah prayer WebP.

```text
Use case: precise-object-edit. Edit target: the supplied Umrah prayer illustration. Preserve the same refined dark outlines, flat cel-shaded white ihram folds, warm cream / slate blue / soft gold palette, calm Masjid al-Haram context, and cup with Zamzam dispenser off to the left. Portrait 1024x1536, full bleed, no text or UI. CRITICAL COMPOSITION CORRECTION: this is a seated worshipper after two tawaf prayer units; give him a believable LONG narrow adult prayer mat with its LONG AXIS running AWAY from the camera toward the Kaaba, not horizontally across the frame. Reframe from a higher directly rear camera so the mat’s entire outline and long unused portion AHEAD of the seated pilgrim are clearly visible. The seated pilgrim rests on his heels in the REAR QUARTER of the mat, close to the edge nearest the viewer, leaving only a small rear border behind his feet, with knees pointing toward the far end. In front of his knees show a long empty unobstructed mat area sufficient to lean forward and place BOTH hands and forehead fully ON the mat. The far end remains a clear distance BEYOND the eventual forehead position. Keep realistic human-to-rug proportions, roughly an ordinary 70 by 130 cm mat, never a tiny square or a giant room carpet. NO ledge, step, wall, barrier, dispenser or object immediately in front of the mat; provide open level prayer floor extending beyond the mat. Any architectural ledge is far away. Kaaba centered in the distance on the continuation of the mat axis, so worshipper faces it. One bareheaded adult male in white two-piece ihram covering both shoulders, exact straight rear view with head facing directly away. NO visible face surfaces, eyes, nose, cheek, mouth, profile or human reflection, including background. No other people. No face erasure or blur, actual rear viewpoint. Respectful accurate seated prayer posture, no change to the rite. Do not add arrows, labels, numbers, lettering, logos, borders or watermark.
```

The final 1024 by 1536 PNG and encoded WebP were inspected at full resolution for mat direction, human scale, unobstructed forward space, seated placement, face visibility and reflections. Guide prose was unchanged. No tests or simulators were run.
