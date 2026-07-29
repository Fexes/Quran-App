import CoreLocation
import Flutter
import UIKit

final class QiblaHeadingStreamHandler: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  private var sink: FlutterEventSink?

  override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    manager.headingFilter = 1
    manager.headingOrientation = .portrait
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    sink = events

    guard CLLocationManager.headingAvailable() else {
      events(FlutterError(code: "no_sensor", message: "Compass heading unavailable.", details: nil))
      return nil
    }

    manager.requestWhenInUseAuthorization()
    manager.startUpdatingLocation()
    manager.startUpdatingHeading()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    manager.stopUpdatingHeading()
    manager.stopUpdatingLocation()
    sink = nil
    return nil
  }

  func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
    false
  }

  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    let hasTrueHeading = newHeading.trueHeading >= 0
    let heading = hasTrueHeading ? newHeading.trueHeading : newHeading.magneticHeading
    sink?([
      "heading": normalize(heading),
      "magneticHeading": normalize(newHeading.magneticHeading),
      "accuracy": newHeading.headingAccuracy,
      "source": hasTrueHeading ? "ios_core_location" : "ios_core_location_magnetic",
    ])
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    sink?(FlutterError(code: "heading_error", message: error.localizedDescription, details: nil))
  }

  private func normalize(_ degrees: CLLocationDirection) -> Double {
    let value = degrees.truncatingRemainder(dividingBy: 360)
    return value < 0 ? value + 360 : value
  }
}
