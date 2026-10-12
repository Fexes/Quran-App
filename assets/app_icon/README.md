# Launcher Artwork

Updated: 2026-10-13. The user approved the clean white-background Ink And Gold concept and requested launcher integration plus a matching round version.

- `logo.png`: exact copy of `docs/design/app-icon-concepts/31-ink-and-gold-clean-white.png`. Opaque 1254px square master used for iOS and standard Android icons. The approved cover artwork is unchanged.
- `logo_round.png`: 1254px circular navy emblem with transparent corners, adapted with the built-in image tool from the approved square master. Quran lettering, gold panel, flowers, and coral bookmark remain visible. Used by Android's round icon resources.
- `archive/logo-before-2026-10-13.png` and `archive/logo_round-before-2026-10-13.png`: previous launcher masters preserved before replacement.
- `flat-2d-v1.png`: unselected preview; prompt and history remain in `flat-2d-v1.md`.
- Masters are intentionally absent from `pubspec.yaml`: launcher resources do not need Flutter UI asset registration.

## Native Files

| Purpose | Files |
| --- | --- |
| Android references | `android/app/src/main/AndroidManifest.xml`: existing `android:icon` and `android:roundIcon` references retained. |
| Android legacy icons | `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png` and `ic_launcher_round.png`, at 48, 72, 96, 144, and 192px. |
| Android adaptive artwork | `android/app/src/main/res/drawable-nodpi/ic_launcher_artwork.png` and `ic_launcher_round_artwork.png`, both 432px. |
| Android adaptive configuration | `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`, `ic_launcher_round.xml`, and `android/app/src/main/res/values/ic_launcher_colors.xml`. |
| iOS exports | `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png`: 15 opaque PNGs serving all 19 slots in the unchanged `Contents.json`. |
| iOS build reference | `ios/Runner.xcodeproj/project.pbxproj`: existing `AppIcon` catalog selection retained in all three configurations. |

Android adaptive layers use a white background and a 20% inset, fitting the foreground into 64.8dp of the 108dp layer. The previous 19.444444% inset placed the standard artwork's outermost colored pixels at radius 33.54dp, just outside the guaranteed 33dp circular safe radius. The updated inset reduces that to 32.93dp; the round artwork is within 28.61dp. The inset changes only native placement, not either master image.

iOS uses the approved opaque square image and system masking, not the transparent round master. Android launchers choose their own adaptive masks and may prefer the round resource.

## Export And Verification

Performed on 2026-10-13:

- Mechanically resized native exports with macOS `sips`, deriving and deduplicating iOS dimensions from `Contents.json`; no new dependencies or generator configuration.
- Checked all 27 PNG dimensions, opaque iOS/standard Android images, transparent round corners, exact master/source copies, manifest references, adaptive background/insets, and all three iOS catalog settings.
- Inspected the 192px standard and 48px round exports; checked colored adaptive pixels against the guaranteed circular safe area.
- Android resources compiled with installed `aapt2` 37.0.0.
- iOS asset catalog compiled with `actool --platform iphoneos`, producing `Assets.car` and the expected iPhone/iPad icon metadata. Xcode logged unavailable simulator-service diagnostics, but the asset compilation completed successfully; no simulator was launched.
- No Dart changes, localization changes, new tests, app build, device installation, or simulator run. Installed-device appearance and launcher caching remain to verify after the next build.

## Design History

Square/round previews, exact image-edit prompts, approval history, and remaining review are recorded in `docs/design/app-icon-concepts/README.md`. The round edit changed the rectangular cover into a circular emblem instead of clipping the original book and ribbon.

## Platform References

- [Android adaptive and round icons](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive)
- [Apple app icon masking](https://developer.apple.com/design/human-interface-guidelines/app-icons)
