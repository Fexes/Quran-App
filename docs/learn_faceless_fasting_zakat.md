# Faceless fasting and zakat illustration audit

Reviewed 21 October 2026. All six chapter placements and both cover images were checked for relevance and visible faces. The final scenes contain either no people or hands with heads entirely outside the frame. No masks, blank faces or blur were used.

| Placement | Final asset | Review |
| --- | --- | --- |
| Fasting cover | assets/images/learn/fasting.webp | Retained. Person-free evening meal preparation; appropriate overview. |
| Before dawn | assets/images/learn/fasting_suhoor.webp | Replaced sunset scene with pre-dawn meal and dark exterior. No people. |
| Keep the fast | assets/images/learn/fasting_day.webp | Replaced unrelated solo-prayer image with a daytime fasting setting. No people. |
| When a day is missed | assets/images/learn/fasting_makeup.webp | Replaced meal image with a physical calendar for recording missed days. No people. |
| Zakat cover and Give it correctly | assets/images/learn/zakat.webp | Retained appropriate envelope handover. Only hands and clothed torsos; heads out of frame, no background people or face reflections. |
| Check when it is due | assets/images/learn/zakat_assess.webp | Asset assessment scene, no people or portraits on coins. |
| Calculate the amount | assets/images/learn/zakat_calculate.webp | Calculator and ledger scene, no people, coin portraits or invented figures. |

Built-in image_gen was used for the five new chapter-specific variants. Existing images were viewed before editing. Every result was inspected at full resolution for faces and subject relevance, then encoded to WebP with cwebp -q 84 -m 6 without changing its content. All final assets are 1024 × 1536 and saved under /Users/farhanfida/Desktop/Quran/quran/assets/images/learn/.

## Exact prompts and original files

### fasting_suhoor.webp

Original: /Users/farhanfida/.codex/generated_images/01a15e70-957a-7121-967d-884215793f60/exec-7995062f-7240-49a3-9adc-9cf8a1f66289.png

```text
Edit the supplied fasting illustration into a clearly PRE-DAWN SUHUR scene, not a sunset scene. Preserve the illustrated table and arched-window visual language, but change the outdoors to dark cool navy blue BEFORE true dawn, no sun visible and no orange sunset. A small simple pre-dawn meal of bread, a bowl of porridge, dates and water stands on the table under a modest warm lantern. Quiet atmosphere, correct contrast of dim interior lamp with very dark exterior. Keep the input's flat 2D hand-drawn cel-shaded editorial style, fine dark ink outlines, broad cream/slate blue/muted gold shapes and softly painted architectural background. No photographic textures or 3D rendering. Full-bleed portrait 2:3. Absolutely no people, heads, faces, portraits, reflections of people, readable text, digits, calligraphy, logos, UI or watermarks.
```

### fasting_day.webp

Original: /Users/farhanfida/.codex/generated_images/01a15e70-957a-7121-967d-884215793f60/exec-6d0d9be5-ce2a-454f-827c-a330a2db0ccc.png

```text
Edit the supplied fasting illustration into the DAYTIME FASTING chapter scene. Bright midday daylight and a clear pale blue sky through the arch, no sunset and no visible low sun. Show a quiet place setting set aside: a plain covered water carafe and an empty clean plate on a simple table, with a closed book with a blank cover and a folded slate blue prayer mat nearby. Nothing being eaten or drunk. Calm restraint and an ordinary fasting day, not an evening feast or a prayer posture demonstration. Keep the input's flat 2D hand-drawn cel-shaded editorial style, fine dark ink outlines, broad cream/slate blue/muted gold shapes and softly painted architectural background. No photographic textures or 3D rendering. Full-bleed portrait 2:3. Absolutely no people, heads, faces, portraits, reflections of people, readable text, digits, calligraphy, logos, UI or watermarks.
```

### fasting_makeup.webp

Original: /Users/farhanfida/.codex/generated_images/01a15e70-957a-7121-967d-884215793f60/exec-02ca9a3e-0295-48dc-ae0d-0aef9ae1eb76.png

```text
Edit the supplied illustration into a still life for RECORDING MISSED FASTS to make up later. Close high-angle view of a cream desk with a physical paper calendar, a small plain notebook, a pencil and a modest travel bag in the softly painted background. Calendar is a simple grid of blank squares, with a few small slate blue circular marks but NO numbers or writing anywhere. No food, no medicine, no coins and no implication that payment replaces every missed fast. This is a tangible paper planning scene, no app interface. Keep the input's flat 2D hand-drawn cel-shaded editorial style, fine dark ink outlines, broad cream/slate blue/muted gold shapes and softly painted architectural background. No photographic textures or 3D rendering. Full-bleed portrait 2:3. Absolutely no people, heads, faces, portraits, reflections of people, readable text, digits, calligraphy, logos, UI or watermarks.
```

### zakat_assess.webp

Original: /Users/farhanfida/.codex/generated_images/01a15e70-957a-7121-967d-884215793f60/exec-46a1c848-7cf0-4558-af14-554ccd24e530.png

```text
Transform the FIRST input donation illustration into a chapter-specific still life about ASSESSING ELIGIBLE WEALTH before zakat. The SECOND input is rendering-style reference only. Remove both people entirely. On a quiet cream desk arrange small plain gold and silver coin stacks (no portraits or denominations), a simple open cloth coin pouch, a modest gold bangle and a physical notebook with blank ruled pages. A small plain balance scale may sit in the background. Keep the warm Islamic architectural atmosphere softly painted but all foreground objects clearly ink-outlined. No giving gesture and no envelope exchange, because this chapter is checking assets and the threshold. Use only flat 2D cel-shaded illustration with crisp fine dark outlines, broad cream, sandstone, muted gold and slate blue color shapes, matching the SECOND input's illustrated rendering. No photography, 3D rendering, realistic microtextures, photographic reflections or shallow depth of field. Full-bleed portrait 2:3. No people or heads whatsoever, including background figures, coin portraits and reflections. No readable letters, digits, logos, calligraphy or app UI.
```

### zakat_calculate.webp

Original: /Users/farhanfida/.codex/generated_images/01a15e70-957a-7121-967d-884215793f60/exec-5d5e59f7-6bb7-40c0-9124-dc99f219a538.png

```text
Transform the FIRST input donation illustration into a chapter-specific still life about CALCULATING ZAKAT. The SECOND input is rendering-style reference only. Remove both people entirely. Show a cream wooden desk from a high oblique angle, with a simple physical calculator with blank display and plain unmarked buttons, a pencil lying across a blank ruled ledger, small neat stacks of plain gold and silver coins with no portraits, and two unmarked cream envelopes. Tactile objects without photographic texture. The calculator and ledger are the clear subject, no handing money to anyone. No fabricated equations or currency values anywhere. Use only flat 2D cel-shaded illustration with crisp fine dark outlines, broad cream, sandstone, muted gold and slate blue color shapes, matching the SECOND input's illustrated rendering. No photography, 3D rendering, realistic microtextures, photographic reflections or shallow depth of field. Full-bleed portrait 2:3. No people or heads whatsoever, including background figures, coin portraits and reflections. No readable letters, digits, logos, calligraphy or app UI.
```

