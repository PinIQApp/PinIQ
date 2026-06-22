import Foundation
import WatchConnectivity
import HealthKit

final class WatchHomeViewModel: NSObject, ObservableObject, WCSessionDelegate {
  @Published var unreadMessages = 0
  @Published var alerts = 0
  @Published var nextEvent = "No event synced"
  @Published var nextWeighIn = "No weigh-in synced"
  @Published var heartRate = "--"
  @Published var steps = "--"

  private let healthStore = HKHealthStore()

  override init() {
    super.init()
    activateConnectivity()
    loadHealthSnapshot()
  }

  func activateConnectivity() {
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    session.delegate = self
    session.activate()
    applySnapshot(session.applicationContext)
  }

  func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
  }

  func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    DispatchQueue.main.async {
      self.applySnapshot(applicationContext)
    }
  }

  private func applySnapshot(_ payload: [String: Any]) {
    unreadMessages = payload["unreadMessages"] as? Int ?? unreadMessages
    alerts = payload["alerts"] as? Int ?? alerts
    nextEvent = payload["nextEvent"] as? String ?? nextEvent
    nextWeighIn = payload["nextWeighIn"] as? String ?? nextWeighIn
  }

  func loadHealthSnapshot() {
    guard HKHealthStore.isHealthDataAvailable() else { return }

    requestHealthPermissionsIfNeeded()
  }

  private func requestHealthPermissionsIfNeeded() {
    guard
      let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
      let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)
    else {
      return
    }

    healthStore.requestAuthorization(toShare: [], read: [heartRateType, stepType]) { success, _ in
      guard success else { return }
      self.fetchSteps()
      self.fetchHeartRate()
    }
  }

  private func fetchSteps() {
    guard let type = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
    let predicate = HKQuery.predicateForSamples(
      withStart: Calendar.current.startOfDay(for: Date()),
      end: Date(),
      options: .strictStartDate
    )
    let query = HKStatisticsQuery(
      quantityType: type,
      quantitySamplePredicate: predicate,
      options: .cumulativeSum
    ) { _, result, _ in
      let value = Int(result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0)
      DispatchQueue.main.async {
        self.steps = "\(value)"
      }
    }
    healthStore.execute(query)
  }

  private func fetchHeartRate() {
    guard let type = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
    let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
    let query = HKSampleQuery(
      sampleType: type,
      predicate: nil,
      limit: 1,
      sortDescriptors: [sort]
    ) { _, samples, _ in
      guard let sample = samples?.first as? HKQuantitySample else { return }
      let value = Int(sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
      DispatchQueue.main.async {
        self.heartRate = "\(value) bpm"
      }
    }
    healthStore.execute(query)
  }
}
