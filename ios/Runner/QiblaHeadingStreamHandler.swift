import CoreLocation
import CoreMotion
import Flutter
import UIKit

final class QiblaHeadingStreamHandler: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  private let motion = CMMotionManager()
  private var sink: FlutterEventSink?
  private var declination: Double?
  private var lastMotionSampleAt: Date?
  private var lastCoreLocationHeading: CLHeading?
  private var lastMotionReliable = false
  private var streamRevision = 0

  override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    manager.headingFilter = 1
    manager.headingOrientation = .portrait
    motion.deviceMotionUpdateInterval = 1.0 / 20.0
    motion.showsDeviceMovementDisplay = false
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    streamRevision += 1
    motion.stopDeviceMotionUpdates()
    sink = events
    declination = nil
    lastMotionSampleAt = nil
    lastCoreLocationHeading = nil
    lastMotionReliable = false

    guard CLLocationManager.headingAvailable() else {
      events(FlutterError(code: "no_sensor", message: "Compass heading unavailable.", details: nil))
      return nil
    }

    if manager.authorizationStatus == .notDetermined {
      manager.requestWhenInUseAuthorization()
    }
    manager.startUpdatingLocation()
    manager.startUpdatingHeading()
    startMotionUpdates()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    streamRevision += 1
    motion.stopDeviceMotionUpdates()
    manager.stopUpdatingHeading()
    manager.stopUpdatingLocation()
    sink = nil
    declination = nil
    lastMotionSampleAt = nil
    lastCoreLocationHeading = nil
    lastMotionReliable = false
    return nil
  }

  func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
    false
  }

  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    guard newHeading.headingAccuracy >= 0,
          newHeading.headingAccuracy.isFinite,
          newHeading.magneticHeading.isFinite else { return }
    lastCoreLocationHeading = newHeading
    let hasTrueHeading = newHeading.trueHeading >= 0
      && newHeading.trueHeading.isFinite
    if hasTrueHeading {
      declination = newHeading.trueHeading - newHeading.magneticHeading
    }
    if lastMotionReliable, let lastMotionSampleAt,
       Date().timeIntervalSince(lastMotionSampleAt) < 0.5 {
      return
    }
    let heading = hasTrueHeading ? newHeading.trueHeading : newHeading.magneticHeading
    sink?([
      "heading": normalize(heading + screenHeadingOffset),
      "magneticHeading": normalize(newHeading.magneticHeading),
      "accuracy": newHeading.headingAccuracy,
      "source": hasTrueHeading ? "ios_core_location" : "ios_core_location_magnetic",
    ])
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    if let locationError = error as? CLError,
       locationError.code == .locationUnknown || locationError.code == .denied {
      // Location failure must not stop an otherwise working compass.
      return
    }
    sink?(FlutterError(code: "heading_error", message: error.localizedDescription, details: nil))
  }

  private func startMotionUpdates() {
    guard motion.isDeviceMotionAvailable,
          CMMotionManager.availableAttitudeReferenceFrames().contains(.xMagneticNorthZVertical) else {
      return
    }
    let revision = streamRevision
    motion.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { [weak self] sample, error in
      guard let self, self.sink != nil, self.streamRevision == revision else { return }
      guard error == nil, let sample,
            sample.heading.isFinite, sample.heading >= 0 else { return }
      let correction = self.declination
      self.lastMotionReliable = correction != nil
        && (sample.magneticField.accuracy == .medium || sample.magneticField.accuracy == .high)
      if !self.lastMotionReliable, let heading = self.lastCoreLocationHeading,
         heading.trueHeading >= 0, heading.headingAccuracy <= 20,
         Date().timeIntervalSince(heading.timestamp) < 0.5 {
        return
      }
      self.lastMotionSampleAt = Date()
      let accuracy: String
      switch sample.magneticField.accuracy {
      case .high: accuracy = "high"
      case .medium: accuracy = "medium"
      case .low: accuracy = "low"
      case .uncalibrated: accuracy = "uncalibrated"
      @unknown default: accuracy = "unknown"
      }
      self.sink?([
        "heading": self.normalize(sample.heading + (correction ?? 0) + self.screenHeadingOffset),
        "magneticHeading": self.normalize(sample.heading),
        "accuracyLevel": accuracy,
        "source": correction == nil ? "ios_device_motion_magnetic" : "ios_device_motion",
      ])
    }
  }

  private var screenHeadingOffset: Double {
    let orientation = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }?.interfaceOrientation
    switch orientation {
    case .landscapeRight: return 90
    case .landscapeLeft: return -90
    case .portraitUpsideDown: return 180
    default: return 0
    }
  }

  private func normalize(_ degrees: CLLocationDirection) -> Double {
    let value = degrees.truncatingRemainder(dividingBy: 360)
    return value < 0 ? value + 360 : value
  }
}
