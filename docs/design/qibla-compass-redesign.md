# Qibla Compass Redesign

Date: 2026-10-12
Status: implemented; physical-device validation pending.

## Experience

- An upright Kaaba marker travels around the compass toward a fixed target at the top of the phone.
- An arc shows the shortest turn to the target. Cardinal labels rotate with heading while remaining upright.
- The center shows degrees remaining and a turn icon. The guidance below repeats the turn in readable text.
- Holding within 6 degrees for 650 ms fills the center ring, shows a checkmark and green Facing Qibla feedback, and requests one medium haptic.
- Confirmation remains active until deviation exceeds 9 degrees, avoiding flicker at the entry boundary. Haptics are separated by at least three seconds.
- Qibla bearing and current heading remain available below the compass.
- Limited-accuracy and magnetic-only readings remain visibly approximate, even when the displayed offset is zero.
- Missing-sensor, stream-error, and initial-reading timeout states retain the bearing and offer a retry.
- Existing light/dark themes, Manrope typography, app icons, and saved prayer location are reused. No new dependency or content source.

## Architecture And Files

| Responsibility | Files | Change |
| --- | --- | --- |
| Bearing state | `lib/features/qibla/presentation/bloc/qibla_cubit.dart`, `qibla_state.dart` | Existing Cubit and repository contract retained. |
| Bearing calculation | `lib/features/qibla/data/services/qibla_calculation_service.dart`, `data/repositories/qibla_repository_impl.dart` | Existing `adhan_dart` calculation and saved location retained. |
| Native heading | `ios/Runner/QiblaHeadingStreamHandler.swift`, `android/app/src/main/kotlin/com/coreinfinite/quran/MainActivity.kt` | Existing `quran/qibla_heading` channel retained. No native changes. |
| Heading lifecycle and feedback | `lib/features/qibla/presentation/pages/qibla_page.dart` | Accuracy gate, alignment dwell timer, haptic cooldown, timeout/retry, stale-callback rejection, lifecycle cleanup, and accessible guidance. |
| Compass UI | `lib/features/qibla/presentation/widgets/qibla_compass.dart` | New theme-aware dial, Kaaba orbit, shortest-turn arc, upright cardinal labels, center readout, and settling progress. |
| Entry route | `lib/app/router/app_router.dart` | Existing `QiblaPage` route retained; no caller/API changes. |
| Shared styling | `lib/core/theme/quran_theme.dart`, `lib/core/widgets/app_icon.dart` | Existing colors, semantic feedback colors, typography, and icons reused without edits. |

Bearing data remains in the existing Cubit/repository flow. High-frequency sensor animation remains local to the compass presentation, as before; no sensor-driven rebuild of the app shell. The painter listens directly to the heading animation and is isolated by a repaint boundary.

## Accuracy And Lifecycle

- Android confirmation accepts medium/high accuracy (2 or 3). Low, unreliable, unknown, and non-finite accuracy never confirm.
- iOS confirmation requires true north and a non-negative accuracy of at most 20 degrees. This is an application quality threshold, not a guarantee of six-degree physical precision.
- Apple defines negative heading accuracy as invalid; Android defines low accuracy as needing calibration. Sources: [Apple heading accuracy](https://developer.apple.com/documentation/corelocation/clheading/headingaccuracy), [Android sensor accuracy](https://developer.android.com/reference/android/hardware/SensorManager#SENSOR_STATUS_ACCURACY_LOW). The installed CoreLocation `CLHeading.h` was also inspected.
- Calibration hint timing is independent of confirmation eligibility. Suppressing the detailed hint cannot enable a green confirmation.
- The dwell timer is cancelled when readings leave the entry band, become unreliable, or error. Backgrounding, retry, disposal, and location/bearing changes also cancel it.
- Resuming requires a new reading. Stream revision checks reject callbacks from replaced subscriptions.
- A ten-second initial-reading deadline ends an indefinite loading state; late valid readings can recover normally.
- Reduced motion removes visual interpolation and progress animation. It does not bypass the confirmation dwell time.
- Screen-reader live guidance covers confirmation and errors. Decorative dial text is excluded; readable turn guidance and both bearings remain outside it.
- Narrow and large-text layouts scroll naturally; compass geometry is bounded and the graphical readout scales down within its fixed center.

## Bug Fixes And Techniques

BUG-005: previous confirmation used the temporary calibration flag instead of persistent sensor quality. When that hint disappeared, the same unreliable heading could look confirmed. Negative iOS accuracy and stale paused alignment were additional cases.

Fix techniques: explicit platform-specific accuracy validation, separate presentation timing, 6/9-degree hysteresis, a 650 ms dwell, a monotonic haptic cooldown, stream revision guards, timer cleanup, and debug assertions preventing invalid aligned states.

## Verification

- Focused Dart static analysis passed.
- A temporary Flutter web preview compiled the actual Qibla page with a simulated native heading channel and a fixed repository response. Production initialization and real location were not used.
- Browser review covered a 390 px light layout, 320 px dark/low-accuracy layout, and a 320 px layout with 2x text, a long location name, and reduced motion. Large-text metadata remained scrollable without overflow.
- A simulated 359-degree heading toward a 1-degree bearing correctly reached confirmation through the short angular path.
- Left/right guidance, aligned feedback, low-accuracy non-confirmation, and missing-sensor messaging were inspected in the actual page. The final preview had no captured browser console errors. Retry was present in the accessibility tree.
- No test files were authored or run. No Android/iOS simulator was started.
- Browser evidence checks presentation and simulated event handling only. It does not validate real sensor accuracy, native haptic delivery, OS permission flows, or user visual approval.

## Next Steps

1. On a physical phone, rotate both directions and cross north while watching the Kaaba track the fixed target.
2. Hold alignment, leave/re-enter its tolerance, and check that confirmation and vibration remain stable.
3. Check magnetic interference, denied location, sensor recovery, background/resume, and retry.
4. Check real device orientations and screen-reader announcements. Native heading orientation/calibration behavior was not changed in this redesign.
