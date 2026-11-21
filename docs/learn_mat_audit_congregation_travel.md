# Prayer mat audit: congregation and travel illustrations

Integration note: Final project assets use `_mat` filenames to refresh the app image cache. Original edit inputs used the earlier filenames without that suffix; preserved input copies and native PNG paths remain unchanged.

Date: 2026-10-21

## Scope and outcome

All eight actual final WebPs were viewed individually at original 1024 by 1536 resolution before deciding changes. Two personal-mat illustrations were revised with the built-in image_gen tool. Six congregation and funeral illustrations were retained unchanged after a visual review of carpet direction, row spacing and obstacles.

This is a visual plausibility audit. The requested heel placement and dimensions in the prompts are composition guidance for these images, not religious rules requiring an exact mat position or size. Perspective illustrations cannot establish measured real-world clearances. Continuous mosque carpets and shared row rugs are suitable visual contexts without separate personal-mat borders.

No Dart files were edited or renamed. No tests or simulators were run. The root agent owns any later filename versioning.

## Per-asset findings

| Asset at handoff | Decision | Initial finding | Final assessment |
| --- | --- | --- | --- |
| prayer_travel_faceless_mat.webp | Revise | The original mat appeared too short in the direction of prayer, with excess rug behind the feet. | Long axis now follows the traveller toward the arch. Heels are near the rear quarter; the clear mat extends forward. Bag and shoes stay off the rug. |
| prayer_illness_faceless_mat.webp | Revise | The original rug read as shallow and placed too much rug behind the chair. | Chair is near the rear short edge. Rug extends toward the niche. Both socked feet are supported, and chair posture remains upright. |
| congregation_faceless.webp | Retain | Continuous mosque carpet is aligned toward the niche, rather than a set of undersized personal mats. | Visible floor between rows and depth perspective provide believable movement space; no mat edge crosses a required standing area. |
| congregation_complete.webp | Retain | Continuous carpet and row bands provide coherent direction. The standing latecomer has a clear area ahead before the seated row. | No objects obstruct the visible floor in front of the latecomer. Seated people remain in their existing positions. |
| eid_faceless.webp | Retain | Outdoor rows stand on continuous prayer carpeting, with no misleading small individual mat boundary. | Rows share one forward direction; depth and visible strips between figures are coherent. No visible obstruction suggests unusable spacing. |
| jumuah_faceless.webp | Retain | Seated gathering uses continuous mosque carpet. No individual rug needs repositioning. | Rows and carpet follow the mosque direction. The depicted seated gathering has plausible spacing. |
| jumuah_prayer.webp | Retain | Standing congregation uses continuous carpet with transverse row markings toward the niche. | No tiny rug, conflicting direction or visible object blocks the rows. Existing depth separation is believable. |
| janazah_faceless.webp | Retain | The funeral scene uses an open courtyard and broad carpeting, with no individual mat-position problem. | The scene is standing funeral prayer; the opaque bier and people are aligned. No prostration pose or tiny personal mat is implied. |

All final images are under /Users/farhanfida/Desktop/Quran/quran/assets/images/learn/.

## Method and final inspection

The original eight WebPs were preserved before changes in /private/tmp/learn_mat_audit_ct_originals/. This includes exact copies of the actual assets reviewed, rather than relying on previous generation records. The new PNG source originals remain at the generated_images paths recorded below.

Two independent built-in image_gen edits produced the new long-mat compositions. The travel draft then received one targeted adjustment moving the whole traveller toward the near short edge so the clear mat extends ahead of the feet. No scripted content edits, resizing or cropping were used. Selected PNGs were encoded with cwebp -q 84 -m 6 to the same owned WebP paths. Both selected PNGs are 1024 by 1536 pixels.

Each revised final WebP was reopened at its original resolution. Travel: long axis points away toward the arch, heel position is near the rear quarter, rug extends forward, and luggage and shoes remain to the side. Chair: rear legs sit close to the near short edge, mat extends forward toward the niche, feet remain supported, and the torso is upright. Both preserve the cream/slate/gold cel-shaded style and strictly rear-facing heads with no visible face, facial profile or reflection. No text or diagram markers were introduced.

Final sizes at handoff: prayer_travel_faceless_mat.webp, 141,266 bytes; prayer_illness_faceless_mat.webp, 186,428 bytes.

## Originals reviewed

- prayer_travel_faceless_mat.webp: exact reviewed original preserved at /private/tmp/learn_mat_audit_ct_originals/prayer_travel_faceless.webp; earlier generated PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-20306ed0-4acb-4e85-b279-af20764c07d0.png.
- prayer_illness_faceless_mat.webp: exact reviewed original preserved at /private/tmp/learn_mat_audit_ct_originals/prayer_illness_faceless.webp; earlier generated PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-0e279184-3bf7-4f38-aff9-5af3b0a1bbbc.png.
- congregation_faceless.webp: exact reviewed original preserved at /private/tmp/learn_mat_audit_ct_originals/congregation_faceless.webp; earlier generated PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-bae3e1ff-78a1-4dcf-9a42-5d66650071a8.png.
- congregation_complete.webp: exact reviewed original preserved at /private/tmp/learn_mat_audit_ct_originals/congregation_complete.webp; earlier generated PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-62602f18-70d5-470a-aa8e-04ff8e32760b.png.
- eid_faceless.webp: exact reviewed original preserved at /private/tmp/learn_mat_audit_ct_originals/eid_faceless.webp; earlier generated PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-4708d202-dc28-4890-9e92-edbd8cf7078b.png.
- jumuah_faceless.webp: exact reviewed original preserved at /private/tmp/learn_mat_audit_ct_originals/jumuah_faceless.webp; earlier generated PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-5305940f-b614-409a-afcb-d0bdf3e924e8.png.
- jumuah_prayer.webp: exact reviewed original preserved at /private/tmp/learn_mat_audit_ct_originals/jumuah_prayer.webp; earlier generated PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-31a030b2-e35f-458e-87f4-dc10ba1e182e.png.
- janazah_faceless.webp: exact reviewed original preserved at /private/tmp/learn_mat_audit_ct_originals/janazah_faceless.webp; earlier generated PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-8e9d5cc0-8472-48fe-81a8-057d8be2b5fb.png.

## Exact edit prompts and selected source PNGs

### prayer_travel_faceless

Input edit target: /Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_travel_faceless_mat.webp (pre-edit copy at /private/tmp/learn_mat_audit_ct_originals/prayer_travel_faceless.webp).

Selected source PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-dcbfad34-fe8e-493a-9931-74635c3fc82d.png

Final WebP: /Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_travel_faceless_mat.webp

Initial edit prompt:

```text
Use case: precise-object-edit. Edit the supplied illustration. Preserve the established flat cel-shaded, outlined cream, slate-blue and gold style, calm architecture and modest clothing. Preserve portrait 1024x1536 size. No text, arrows, diagram labels, logos or UI. CRITICAL: every person remains seen strictly from behind, only back of cap/hair/nape, NO face, facial profile, cheek, nose, mouth, eyes, beard profile or reflection. Never erase or blur a face; hide it by the natural rear viewpoint.
Correct the individual prayer rug and the traveller's position. At present the rug is a short sideways-looking rectangle with the person near its middle and insufficient mat extending in front of the toes. Recompose the floor and rug as needed: a standard long rectangular prayer mat, about 70 cm wide and 130 cm long, with its LONG AXIS pointing directly forward in the direction the traveller is facing, away from camera toward the open cream arch. Put the standing traveller's heels near the REAR QUARTER of the rug, at the SHORT EDGE CLOSEST TO CAMERA, leaving roughly one full metre of clear rug ahead of his toes for kneeling and prostration. Most rug length must extend IN FRONT of him toward the arch, not behind him toward viewer. The distant border at the FRONT of the rug must be well beyond his toes. Move the traveller slightly toward the foreground and the far bench farther back if necessary; show enough floor and use a modestly elevated but straight REAR camera to make the long clear rug visible alongside his legs. Keep body upright, hands folded in front out of sight, feet together naturally pointing forward, no visible face. Bag and shoes remain OFF the mat to the side, never in the clear prostration area. No object blocks the space ahead. Do not keep the old tiny horizontal mat geometry.
```

Intermediate draft PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-2397a055-2c5e-4f23-830d-bfd6c55e9182.png

Final revision prompt:

```text
Use case: precise-object-edit. Preserve this exact rear-view travel prayer illustration, its long rug, cream/slate/gold cel-shaded style, architecture, bag, shoes and 1024x1536 portrait format. Make one final placement correction: move the whole standing man BACKWARD TOWARD CAMERA by about 30 cm along the rug, so both heels are just inside the rug's NEAR SHORT EDGE, about 5 to 10 cm inside it. In image composition his heels should land near y=1415, with the existing near rug edge at y=1460; move the whole figure lower, do not stretch only his legs. Keep all of the rug's far extension toward the arch where it currently is, front edge near y=1075. Therefore almost the entire long rug will now extend AHEAD of his feet and only a small strip remains behind his heels. Feet fully on mat, never on the border or off it. Natural upright standing prayer posture and realistic proportions. His back of head and cap remain perfectly straight away; no face or cheek profile, no eyes/nose/mouth or reflections. Do not add text or any position markers.
```

### prayer_illness_faceless

Input edit target: /Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_illness_faceless_mat.webp (pre-edit copy at /private/tmp/learn_mat_audit_ct_originals/prayer_illness_faceless.webp).

Selected source PNG: /Users/farhanfida/.codex/generated_images/01a15ea7-5204-74c2-8371-13bbd70bd230/exec-4c9d26ae-6abb-4032-94e0-6c4f33e61e54.png

Final WebP: /Users/farhanfida/Desktop/Quran/quran/assets/images/learn/prayer_illness_faceless_mat.webp

Initial edit prompt:

```text
Use case: precise-object-edit. Edit the supplied illustration. Preserve the established flat cel-shaded, outlined cream, slate-blue and gold style, calm architecture and modest clothing. Preserve portrait 1024x1536 size. No text, arrows, diagram labels, logos or UI. CRITICAL: every person remains seen strictly from behind, only back of cap/hair/nape, NO face, facial profile, cheek, nose, mouth, eyes, beard profile or reflection. Never erase or blur a face; hide it by the natural rear viewpoint.
Correct only the prayer rug layout and chair placement as needed. At present the rug reads like a short rectangle with excess rug behind the chair. Make it a plausible long rectangular blue prayer rug, long axis directed toward the cream prayer niche directly ahead, with the chair positioned at its REAR end closest to camera. Rear chair legs should be close to the near short edge, with only a small margin of rug behind them, while most rug length extends forward beneath the feet and toward the niche, plainly visible at either side of the chair and beyond the feet. The rug is a natural personal mat about 80 cm wide and 140 cm long, not a tiny doormat or giant room carpet. Keep the seated worshipper upright in the stable wooden chair, knees naturally bent, BOTH socked feet fully supported on the rug/floor, not dangling, and no objects before his forehead. This is chair prayer during illness, do not turn it into floor prostration. May use a slightly more elevated straight-rear camera and move the chair a little lower in frame to show the long mat extending away. Keep the entire person viewed exactly from behind with no face or profile visible. Preserve the quiet room, plant, chair, modest robe and color palette.
```
