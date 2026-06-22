import Foundation
import HealthKit

final class HealthKitManager {
  static let shared = HealthKitManager()

  private let store = HKHealthStore()

  private init() {}

  func requestPermissions(completion: @escaping (Bool) -> Void) {
    guard HKHealthStore.isHealthDataAvailable() else {
      completion(false)
      return
    }

    guard
      let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate),
      let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount),
      let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
    else {
      completion(false)
      return
    }

    let readTypes: Set<HKObjectType> = [heartRate, stepCount, activeEnergy]

    store.requestAuthorization(toShare: [], read: readTypes) { success, _ in
      completion(success)
    }
  }

  func fetchSnapshot(completion: @escaping ([String: Any]) -> Void) {
    guard HKHealthStore.isHealthDataAvailable() else {
      completion([:])
      return
    }

    let group = DispatchGroup()
    var payload: [String: Any] = [:]

    group.enter()
    fetchTodaySteps { value in
      payload["steps"] = value
      group.leave()
    }

    group.enter()
    fetchMostRecentHeartRate { value in
      payload["heartRate"] = value
      group.leave()
    }

    group.enter()
    fetchTodayActiveEnergy { value in
      payload["activeEnergy"] = value
      group.leave()
    }

    group.notify(queue: .main) {
      completion(payload)
    }
  }

  private func fetchTodaySteps(completion: @escaping (Int) -> Void) {
    guard let type = HKObjectType.quantityType(forIdentifier: .stepCount) else {
      completion(0)
      return
    }

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
      let value = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
      completion(Int(value))
    }

    store.execute(query)
  }

  private func fetchMostRecentHeartRate(completion: @escaping (Double) -> Void) {
    guard let type = HKObjectType.quantityType(forIdentifier: .heartRate) else {
      completion(0)
      return
    }

    let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
    let query = HKSampleQuery(
      sampleType: type,
      predicate: nil,
      limit: 1,
      sortDescriptors: [sort]
    ) { _, samples, _ in
      guard let sample = samples?.first as? HKQuantitySample else {
        completion(0)
        return
      }
      let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
      completion(sample.quantity.doubleValue(for: unit))
    }

    store.execute(query)
  }

  private func fetchTodayActiveEnergy(completion: @escaping (Int) -> Void) {
    guard let type = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
      completion(0)
      return
    }

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
      let value = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
      completion(Int(value))
    }

    store.execute(query)
  }
}
