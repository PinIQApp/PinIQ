import Foundation
import WatchConnectivity

final class WatchConnectivityManager: NSObject, WCSessionDelegate {
  static let shared = WatchConnectivityManager()

  private override init() {
    super.init()
  }

  func activateIfAvailable() {
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    session.delegate = self
    session.activate()
  }

  func syncSnapshot(_ payload: [String: Any]) -> Bool {
    guard WCSession.isSupported() else { return false }
    let session = WCSession.default
    guard session.activationState == .activated else { return false }

    do {
      try session.updateApplicationContext(payload)
      return true
    } catch {
      return false
    }
  }

  func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
  }

  #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
      session.activate()
    }
  #endif
}
