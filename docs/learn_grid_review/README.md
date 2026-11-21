# Learn grouped tile grid review

Implemented 21 October 2026. Learn retains the existing catalog sequence: Purification (3), Prayer (7), Fasting & giving (2), Pilgrimage (2). All 14 guides remain available through their original overview navigation.

The page now renders each category as a separate asymmetric tile grid. Three-guide groups pair a tall lead card with two compact cards. Prayer continues with alternating unequal pairs. Two-guide groups use unequal-width portrait cards. Wider layouts use three cards across for the leading band; narrow screens and text above 125% use cards that grow naturally in one column. Category counts move beneath headings at larger text sizes. Compact title sizing is measured to keep long words intact.

Guide reading order is preserved through category semantic boundaries and ordered tile traversal. Existing artwork is unchanged. Prayer, prayer-mistakes and travel covers use contain framing to preserve their full image bounds.

## Verification

- Full lib analysis: passed, no issues.
- Unsigned iOS compilation: passed, 40.0 seconds. Binary newer than both edited UI sources.
- Whitespace check: passed.
- All 38 illustration files still match their earlier reviewed SHA-256 hashes.
- Browser preview: reviewed 1280px desktop, 390px and 360px phone mosaics, 320px single-column fallback, and 200% text with the actual dark theme.
- Category headings, guide actions and their order inspected in the accessibility tree. Wudu tile opens the original overview and returns correctly.
- No layout/runtime errors observed in browser logs. No tests or Android/iOS simulators were run.

## Preview limits

The browser used a temporary package with byte-identical Learn sources, the app's actual theme, localization, fonts and artwork. It replaced the floating audio dependency with an idle 24px inset and used a standalone Scaffold without the application shell. Settings was a placeholder route. Preview-only URL controls selected dark mode and text scaling. This verifies Learn presentation and guide navigation, not native device playback or the complete application shell. The temporary server was stopped after review.

## Screenshots

- [Phone mosaic](phone.png)
- [Fasting, giving and pilgrimage](giving-pilgrimage.png)
- [200% text in dark mode](large-text-dark.png)
