# Learn expansion illustrations

Generated on 2026-10-21 using the built-in `image_gen` tool. Each requested illustration used an independent generation call. No API or CLI image-generation fallback was used.

## Visual direction

Reviewed the existing `prayer_standing.webp` and `umrah_tawaf.webp` illustrations and the supplied `/Users/farhanfida/Downloads/IMG_0895.jpg` style reference before generation. The new set uses warm ivory, cream, slate blue and subdued gold, realistic adult proportions, outlined figures, soft architectural backgrounds and calm respectful scenes. All illustrations are portrait 2:3, without added UI, text, labels or logos.

The illustrations are scene-setting educational artwork, not geographic maps or demonstrations of every valid jurisprudential technique. No prophets are depicted. Ghusl uses a preparation still life without a person; Janazah uses an opaque covered bier with no exposed remains. Arafat emphasizes supplication on the plain, and the Jamarat scene uses a contemporary elongated wall and basin.

## Generation and optimization

- Built-in generation: `image_gen.imagegen`, one call per initial asset, `transparent_background: false`.
- Eid received one targeted built-in edit to remove an oversized elevated figure and restore natural crowd perspective.
- Original generated PNGs remain in the Codex generated-images folder.
- Final selected assets are copied into the app as WebP using `cwebp -q 84 -m 6`, retaining the generated 1024 × 1536 dimensions. Compression changes file encoding only; it does not alter illustration content.
- Every selected generated image was visually inspected for subject, composition, modesty, text absence and the requested scene constraints.
- No tests or simulators were run for this asset task.

## Final assets and generation sources

| Final asset | Selected original |
|---|---|
| `assets/images/learn/ghusl_preparation.webp` | `/Users/farhanfida/.codex/generated_images/01a15e70-957a-7121-967d-884215793f60/exec-b6930423-4dc5-40d9-b679-1682777f0447.png` |
| `assets/images/learn/tayammum.webp` | `/Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-101070a3-d63d-44ba-831c-9e9d26d88146.png` |
| `assets/images/learn/congregation.webp` | `/Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-ae29a3de-8786-4c21-90a2-ecc5727b596e.png` |
| `assets/images/learn/prayer_travel.webp` | `/Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-d5df22c2-0513-478d-83bd-172566bb3dae.png` |
| `assets/images/learn/prayer_illness.webp` | `/Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-fc2b2843-c23b-4821-bd8f-66adddaa41a9.png` |
| `assets/images/learn/fasting.webp` | `/Users/farhanfida/.codex/generated_images/01a15e70-957a-7121-967d-884215793f60/exec-328e3fdc-f4bc-4157-8ff6-32a9f83295d6.png` |
| `assets/images/learn/zakat.webp` | `/Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-8757bdf4-849d-4782-8603-1f4e58be4721.png` |
| `assets/images/learn/jumuah.webp` | `/Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-f330b5e2-9a81-4cf5-9df4-62cc36a9bb81.png` |
| `assets/images/learn/eid.webp` | `/Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-c471bd3c-1fe4-4e21-9406-9348bba2310c.png` |
| `assets/images/learn/janazah.webp` | `/Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-f9f43aa5-4cd1-43c2-9343-79a8a47ce783.png` |
| `assets/images/learn/hajj_arafat.webp` | `/Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-76982e11-2657-4209-8da5-a33d291ee823.png` |
| `assets/images/learn/hajj_mina.webp` | `/Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-cb84a63c-5f79-4d67-a75f-14ae9fbd2841.png` |
| `assets/images/learn/hajj_jamarat.webp` | `/Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-98f3e613-1a82-4c18-bc9d-815ba8d68698.png` |

## Exact initial prompts

### ghusl_preparation.webp

```text
Use case: illustration-story.
Asset type: portrait illustration for an Islamic educational mobile app. Brand new independent image, portrait 2:3, ideally 1024 x 1536.
Style/medium: polished restrained cel-shaded editorial illustration matching a consistent series: realistic adult human proportions, fine dark outlines on foreground figures and objects, smooth flat-shaded folds, softly painted cream Islamic architectural backgrounds, muted warm ivory, sandstone, slate blue and subdued gold. Soft luminous natural light, calm and respectful, refined detail, not childish, not photorealistic, not 3D rendering. Full bleed scene, no frame.
Constraints: absolutely NO text, Arabic calligraphy, lettering, numbers, labels, UI, logos, watermarks, diagrams or panels. No depictions of prophets. All people fully and modestly clothed. Natural hands with correct anatomy. The scene is an illustrative overview, not a numbered technique demonstration.
Primary request: A quiet, private bathroom preparation still life for ghusl. No person and no visible body. A neatly folded ivory bath towel and modest full-length robe on a cream wooden bench, a simple ceramic water jug beside a basin with clear water, understated slate blue wall tiles, closed interior bathroom door in the soft background. Warm gentle daylight. Beautiful tactile fabric and water, serene clean setting. No writing or signs.
```

### tayammum.webp

```text
Use case: illustration-story.
Asset type: portrait illustration for an Islamic educational mobile app. Brand new independent image, portrait 2:3, ideally 1024 x 1536.
Style/medium: polished restrained cel-shaded editorial illustration matching a consistent series: realistic adult human proportions, fine dark outlines on foreground figures and objects, smooth flat-shaded folds, softly painted cream Islamic architectural backgrounds, muted warm ivory, sandstone, slate blue and subdued gold. Soft luminous natural light, calm and respectful, refined detail, not childish, not photorealistic, not 3D rendering. Full bleed scene, no frame.
Constraints: absolutely NO text, Arabic calligraphy, lettering, numbers, labels, UI, logos, watermarks, diagrams or panels. No depictions of prophets. All people fully and modestly clothed. Natural hands with correct anatomy. The scene is an illustrative overview, not a numbered technique demonstration.
Primary request: A fully clothed adult Muslim man in a loose ivory long-sleeved tunic seated quietly beside a clean natural earth surface and a smooth pale stone, in a sheltered sandstone courtyard. His natural open hands hover near the clean earth, visually suggesting preparation for tayammum without prescribing a particular disputed hand sequence or number of actions. Three-quarter side view, hands clearly but softly illustrated. Slate blue prayer mat nearby, cream arches softly blurred. No written instructions.
```

### congregation.webp

```text
Use case: illustration-story.
Asset type: portrait illustration for an Islamic educational mobile app. Brand new independent image, portrait 2:3, ideally 1024 x 1536.
Style/medium: polished restrained cel-shaded editorial illustration matching a consistent series: realistic adult human proportions, fine dark outlines on foreground figures and objects, smooth flat-shaded folds, softly painted cream Islamic architectural backgrounds, muted warm ivory, sandstone, slate blue and subdued gold. Soft luminous natural light, calm and respectful, refined detail, not childish, not photorealistic, not 3D rendering. Full bleed scene, no frame.
Constraints: absolutely NO text, Arabic calligraphy, lettering, numbers, labels, UI, logos, watermarks, diagrams or panels. No depictions of prophets. All people fully and modestly clothed. Natural hands with correct anatomy. The scene is an illustrative overview, not a numbered technique demonstration.
Primary request: Wide interior mosque scene framed vertically, seen from behind and slightly above: orderly straight rows of adult worshippers standing respectfully for congregational prayer behind one imam clearly positioned alone in front toward the mihrab. All worshippers face the same direction away from viewer. Modest full-length ivory, cream and muted slate blue garments; barefoot on a beautiful subdued slate blue carpet. Balanced spacious rows, realistic proportions, peaceful soft morning light through tall cream arches. No one facing the congregation.
```

### prayer_travel.webp

```text
Use case: illustration-story.
Asset type: portrait illustration for an Islamic educational mobile app. Brand new independent image, portrait 2:3, ideally 1024 x 1536.
Style/medium: polished restrained cel-shaded editorial illustration matching a consistent series: realistic adult human proportions, fine dark outlines on foreground figures and objects, smooth flat-shaded folds, softly painted cream Islamic architectural backgrounds, muted warm ivory, sandstone, slate blue and subdued gold. Soft luminous natural light, calm and respectful, refined detail, not childish, not photorealistic, not 3D rendering. Full bleed scene, no frame.
Constraints: absolutely NO text, Arabic calligraphy, lettering, numbers, labels, UI, logos, watermarks, diagrams or panels. No depictions of prophets. All people fully and modestly clothed. Natural hands with correct anatomy. The scene is an illustrative overview, not a numbered technique demonstration.
Primary request: A modestly dressed adult male traveler performing standing prayer on a small slate blue prayer mat in a quiet designated rest area with a simple cream arched opening. Loose ivory long-sleeved tunic and trousers, hands naturally folded, side profile, full body. A small closed travel bag and shoes neatly placed off the prayer mat. Peaceful landscape visible beyond, gentle daytime sun, calm and uncluttered. No airport branding, screens, labels or travel text.
```

### prayer_illness.webp

```text
Use case: illustration-story.
Asset type: portrait illustration for an Islamic educational mobile app. Brand new independent image, portrait 2:3, ideally 1024 x 1536.
Style/medium: polished restrained cel-shaded editorial illustration matching a consistent series: realistic adult human proportions, fine dark outlines on foreground figures and objects, smooth flat-shaded folds, softly painted cream Islamic architectural backgrounds, muted warm ivory, sandstone, slate blue and subdued gold. Soft luminous natural light, calm and respectful, refined detail, not childish, not photorealistic, not 3D rendering. Full bleed scene, no frame.
Constraints: absolutely NO text, Arabic calligraphy, lettering, numbers, labels, UI, logos, watermarks, diagrams or panels. No depictions of prophets. All people fully and modestly clothed. Natural hands with correct anatomy. The scene is an illustrative overview, not a numbered technique demonstration.
Primary request: A modest elderly adult Muslim man praying while seated upright on a simple stable chair, shown in gentle three-quarter side view. He wears a loose ivory long-sleeved robe, both feet resting naturally on the floor, hands relaxed on his thighs. Slate blue prayer mat beneath the chair. Quiet comfortable cream room with a softly lit arched window and subtle mosque courtyard view. Respectful calm dignity, no medical distress, no visible injury, no apparatus. Correct seated body anatomy, chair legs clear.
```

### fasting.webp

```text
Use case: illustration-story.
Asset type: portrait illustration for an Islamic educational mobile app. Brand new independent image, portrait 2:3, ideally 1024 x 1536.
Style/medium: polished restrained cel-shaded editorial illustration matching a consistent series: realistic adult human proportions, fine dark outlines on foreground figures and objects, smooth flat-shaded folds, softly painted cream Islamic architectural backgrounds, muted warm ivory, sandstone, slate blue and subdued gold. Soft luminous natural light, calm and respectful, refined detail, not childish, not photorealistic, not 3D rendering. Full bleed scene, no frame.
Constraints: absolutely NO text, Arabic calligraphy, lettering, numbers, labels, UI, logos, watermarks, diagrams or panels. No depictions of prophets. All people fully and modestly clothed. Natural hands with correct anatomy. The scene is an illustrative overview, not a numbered technique demonstration.
Primary request: A beautiful modest iftar place setting at sunset, no people: a small ceramic plate with a few dates and a clear glass of water on a simple low table with ivory cloth. Through a softly blurred arch behind the table, warm sunset light is at the horizon, pale gold and dusty blue sky, distant simple mosque silhouette. Peaceful, restrained, inviting. Clearly evening atmosphere, no visible eating, no feast excess, no clocks, no writing.
```

### zakat.webp

```text
Use case: illustration-story.
Asset type: portrait illustration for an Islamic educational mobile app. Brand new independent image, portrait 2:3, ideally 1024 x 1536.
Style/medium: polished restrained cel-shaded editorial illustration matching a consistent series: realistic adult human proportions, fine dark outlines on foreground figures and objects, smooth flat-shaded folds, softly painted cream Islamic architectural backgrounds, muted warm ivory, sandstone, slate blue and subdued gold. Soft luminous natural light, calm and respectful, refined detail, not childish, not photorealistic, not 3D rendering. Full bleed scene, no frame.
Constraints: absolutely NO text, Arabic calligraphy, lettering, numbers, labels, UI, logos, watermarks, diagrams or panels. No depictions of prophets. All people fully and modestly clothed. Natural hands with correct anatomy. The scene is an illustrative overview, not a numbered technique demonstration.
Primary request: A discreet respectful act of giving zakat, close medium framing of two fully clothed adults' hands: a donor in an ivory long sleeve gently offers a plain sealed cream envelope to the recipient's naturally open hand in a slate blue sleeve. A few simple unmarked coins rest in a small ceramic dish on the edge of a table nearby. Equal dignity, no exaggerated poverty or begging, no readable currency or markings. Soft warm cream courtyard backdrop. Correct fingers and natural hand poses. No text on envelope.
```

### jumuah.webp

```text
Use case: illustration-story.
Asset type: portrait illustration for an Islamic educational mobile app. Brand new independent image, portrait 2:3, ideally 1024 x 1536.
Style/medium: polished restrained cel-shaded editorial illustration matching a consistent series: realistic adult human proportions, fine dark outlines on foreground figures and objects, smooth flat-shaded folds, softly painted cream Islamic architectural backgrounds, muted warm ivory, sandstone, slate blue and subdued gold. Soft luminous natural light, calm and respectful, refined detail, not childish, not photorealistic, not 3D rendering. Full bleed scene, no frame.
Constraints: absolutely NO text, Arabic calligraphy, lettering, numbers, labels, UI, logos, watermarks, diagrams or panels. No depictions of prophets. All people fully and modestly clothed. Natural hands with correct anatomy. The scene is an illustrative overview, not a numbered technique demonstration.
Primary request: A respectful wide mosque sermon scene composed vertically from the rear: adult worshippers sit quietly on a muted slate blue carpet facing a khatib standing on a simple low minbar near a cream mihrab. The khatib is small in the middle distance, modest ivory clothing, no identifiable historic person. All listeners orient toward the front. Soft cream arches and warm daylight, calm dignified atmosphere, realistic proportions. Clearly seated listeners, not rows of people standing in prayer. Absolutely no scripture or lettering.
```

### eid.webp

```text
Use case: illustration-story.
Asset type: portrait illustration for an Islamic educational mobile app. Brand new independent image, portrait 2:3, ideally 1024 x 1536.
Style/medium: polished restrained cel-shaded editorial illustration matching a consistent series: realistic adult human proportions, fine dark outlines on foreground figures and objects, smooth flat-shaded folds, softly painted cream Islamic architectural backgrounds, muted warm ivory, sandstone, slate blue and subdued gold. Soft luminous natural light, calm and respectful, refined detail, not childish, not photorealistic, not 3D rendering. Full bleed scene, no frame.
Constraints: absolutely NO text, Arabic calligraphy, lettering, numbers, labels, UI, logos, watermarks, diagrams or panels. No depictions of prophets. All people fully and modestly clothed. Natural hands with correct anatomy. The scene is an illustrative overview, not a numbered technique demonstration.
Primary request: Outdoor Eid prayer at dawn: spacious orderly rows of modestly clothed adult worshippers standing on aligned prayer mats in a large clean open prayer ground, viewed from behind and slightly raised, with a single imam ahead facing the same direction. Soft cream and slate blue full-length clothing, gentle pale gold dawn light, a modest mosque and trees in the far background. Peaceful communal celebration without festival props. Straight rows, safe open space, realistic scale.
```

### janazah.webp

```text
Use case: illustration-story.
Asset type: portrait illustration for an Islamic educational mobile app. Brand new independent image, portrait 2:3, ideally 1024 x 1536.
Style/medium: polished restrained cel-shaded editorial illustration matching a consistent series: realistic adult human proportions, fine dark outlines on foreground figures and objects, smooth flat-shaded folds, softly painted cream Islamic architectural backgrounds, muted warm ivory, sandstone, slate blue and subdued gold. Soft luminous natural light, calm and respectful, refined detail, not childish, not photorealistic, not 3D rendering. Full bleed scene, no frame.
Constraints: absolutely NO text, Arabic calligraphy, lettering, numbers, labels, UI, logos, watermarks, diagrams or panels. No depictions of prophets. All people fully and modestly clothed. Natural hands with correct anatomy. The scene is an illustrative overview, not a numbered technique demonstration.
Primary request: Dignified non-graphic funeral prayer scene in a quiet mosque courtyard: rows of adult mourners standing respectfully behind an imam, all facing the same direction toward an opaque fully covered bier positioned horizontally across the foreground of their prayer direction. The bier is a simple low platform completely enclosed under a plain thick ivory covering, no human body, body outline, face, limbs or exposed remains visible. View from a rear side angle that makes the imam and covered bier intelligible, cream arches and soft slate blue shadows, subdued respectful daylight. No grief closeups, no candles, no flowers, no text.
```

### hajj_arafat.webp

```text
Use case: illustration-story.
Asset type: portrait illustration for an Islamic educational mobile app. Brand new independent image, portrait 2:3, ideally 1024 x 1536.
Style/medium: polished restrained cel-shaded editorial illustration matching a consistent series: realistic adult human proportions, fine dark outlines on foreground figures and objects, smooth flat-shaded folds, softly painted cream Islamic architectural backgrounds, muted warm ivory, sandstone, slate blue and subdued gold. Soft luminous natural light, calm and respectful, refined detail, not childish, not photorealistic, not 3D rendering. Full bleed scene, no frame.
Constraints: absolutely NO text, Arabic calligraphy, lettering, numbers, labels, UI, logos, watermarks, diagrams or panels. No depictions of prophets. All people fully and modestly clothed. Natural hands with correct anatomy. The scene is an illustrative overview, not a numbered technique demonstration.
Primary request: The broad plain of Arafat in gentle afternoon light during Hajj. A small foreground group of present-day adult male pilgrims in modest white ihram cloth with both shoulders and entire torso covered, and female pilgrims in full loose slate blue abayas and headscarves, standing quietly in supplication with hands raised naturally. Wide open sandy plain and scattered distant pilgrims, pale cream shelters and hazy low rocky hills in the distance. Main subject is prayer across the plain, not climbing a mountain, no dense crowd on a summit. Calm realistic proportions, warm muted atmosphere.
```

### hajj_mina.webp

```text
Use case: illustration-story.
Asset type: portrait illustration for an Islamic educational mobile app. Brand new independent image, portrait 2:3, ideally 1024 x 1536.
Style/medium: polished restrained cel-shaded editorial illustration matching a consistent series: realistic adult human proportions, fine dark outlines on foreground figures and objects, smooth flat-shaded folds, softly painted cream Islamic architectural backgrounds, muted warm ivory, sandstone, slate blue and subdued gold. Soft luminous natural light, calm and respectful, refined detail, not childish, not photorealistic, not 3D rendering. Full bleed scene, no frame.
Constraints: absolutely NO text, Arabic calligraphy, lettering, numbers, labels, UI, logos, watermarks, diagrams or panels. No depictions of prophets. All people fully and modestly clothed. Natural hands with correct anatomy. The scene is an illustrative overview, not a numbered technique demonstration.
Primary request: A portrait landscape illustration of the Mina tent valley during Hajj in daylight: many orderly rows of distinctive white peaked fire-resistant tents spread across a broad valley between pale rocky hills, clean access lanes, a few very small modestly clothed pilgrims walking calmly. Elevated vantage looking over the tents with depth into the valley. Cream, ivory and slate blue shadows with subtle pale gold sunlight. Accurate recognizable tent city mood, no skyscraper focus, no text, no signage, no labels.
```

### hajj_jamarat.webp

```text
Use case: illustration-story.
Asset type: portrait illustration for an Islamic educational mobile app. Brand new independent image, portrait 2:3, ideally 1024 x 1536.
Style/medium: polished restrained cel-shaded editorial illustration matching a consistent series: realistic adult human proportions, fine dark outlines on foreground figures and objects, smooth flat-shaded folds, softly painted cream Islamic architectural backgrounds, muted warm ivory, sandstone, slate blue and subdued gold. Soft luminous natural light, calm and respectful, refined detail, not childish, not photorealistic, not 3D rendering. Full bleed scene, no frame.
Constraints: absolutely NO text, Arabic calligraphy, lettering, numbers, labels, UI, logos, watermarks, diagrams or panels. No depictions of prophets. All people fully and modestly clothed. Natural hands with correct anatomy. The scene is an illustrative overview, not a numbered technique demonstration.
Primary request: Modern Jamarat complex during Hajj, respectful architectural editorial illustration. A tall smooth grey oval elongated pillar-wall within its surrounding oval collection basin stands prominently in a spacious modern multi-level pedestrian bridge hall. It must look like the contemporary elliptical concrete Jamarat wall, not an old narrow round pillar or a statue. A few small adult pilgrims in fully modest white or slate blue garments stand at safe distances in the broad walkway, suggesting the rite without dramatic throwing or crowding. Cream structural columns and overhead canopy, soft daylight, calm organized space. No devil figures, demons, dramatic stone flight, crush crowds, arrows, signs, numbers or writing.
```

## Eid targeted correction

```text
Use case: precise-object-edit. Correct only the perspective mistake in this Eid prayer illustration: remove the one oversized elevated man in white near the upper center of the congregation and replace his footprint with ordinary human-scale worshippers continuing the orderly distant rows. The imam can remain out of frame far ahead, do not add a new large imam. Every worshipper must stand on the same flat ground and diminish naturally into the distance. Preserve all other figures, colors, full portrait composition, architecture, morning light and cel-shaded illustration style. No text, logos or labels.
```

Edit target: `/Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-507cd85d-9970-4d45-b652-3a63c9dbab51.png`.


## Still-life style refinements

Ghusl preparation and fasting received a built-in style edit with their initial generated image as the first input and `/Users/farhanfida/Downloads/IMG_0896.jpg` as the second, style-only reference. These selected versions replace the initial still-life drafts. Their composition is retained while photographic texture is simplified into outlined, cel-shaded illustration.

Exact shared prompt (scene is respectively “the bathroom preparation still life” and “the dates and water at sunset still life”):

```text
Edit the FIRST input image: {scene}. The SECOND input is only a visual style reference. Preserve the first image's portrait 2:3 composition and objects, but REDRAW it as a restrained hand-drawn 2D cel-shaded editorial illustration matching the second image. Strongly simplify photographic surface detail into broad flat cream, slate blue, sandstone and muted gold color shapes. Add fine crisp dark ink outlines to foreground object silhouettes, fabric folds and architectural edges, with just two or three flat shadow tones. Background architecture softly painted and atmospheric, foreground clearly line-illustrated. Remove photographic microtexture, realistic camera rendering, photoreal glass caustics and pore-like fabric detail. Preserve dignity and calm warm lighting. No text, no UI, no captions, no lettering, no logos, no added people or symbols. Return ONLY the redrawn original scene, full-bleed portrait, not a collage and do not include the reference card or its text.
```
