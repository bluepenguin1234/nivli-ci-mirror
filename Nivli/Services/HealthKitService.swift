import Foundation
import HealthKit
import os

/// Read-only access to Apple Health workouts.
///
/// Nivli asks for one thing — workouts — and writes nothing back. The point is that a run
/// recorded by the Watch, or a session logged in any other fitness app, unlocks today
/// without anybody opening Nivli: `startObserving(_:)` plus background delivery wakes the
/// app, and `AppModel` merges what it finds.
///
/// Every failure is silent to the person and visible in the log: Health denied, unavailable
/// or empty simply means manual logging is the only way in, which still works.
final class HealthKitService: @unchecked Sendable {
    private let store = HKHealthStore()
    private let logger = Logger(subsystem: "com.bluepenguin.nivli", category: "health")
    /// The live observer query, so `startObserving(_:)` can replace rather than stack them.
    /// Only ever touched from the main actor, by `AppModel`.
    private var observerQuery: HKObserverQuery?

    /// `false` on a device without Health — an iPad, or the simulator's stripped build.
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    init() {}

    /// Asks for read access to workouts. `false` when Health is unavailable or the request
    /// itself failed; note that iOS deliberately does not reveal a refusal, so `true` only
    /// means the sheet was answered.
    func requestAccess() async -> Bool {
        guard isAvailable else { return false }
        let workoutType = HKObjectType.workoutType()
        return await withCheckedContinuation { continuation in
            store.requestAuthorization(toShare: Set<HKSampleType>(), read: [workoutType]) { [logger] granted, error in
                if let error {
                    logger.error("Health authorization failed: \(error.localizedDescription, privacy: .public)")
                }
                continuation.resume(returning: granted)
            }
        }
    }

    /// Every workout that started today, oldest first. An empty array covers every failure:
    /// unavailable, not authorized, or nothing recorded yet.
    func workoutsToday(calendar: Calendar = .current) async -> [WorkoutEntry] {
        guard isAvailable else { return [] }
        let startOfToday = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfToday,
            end: nil,
            options: .strictStartDate
        )
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { [logger] _, samples, error in
                if let error {
                    logger.error("Today's workouts could not be read: \(error.localizedDescription, privacy: .public)")
                }
                let workouts = (samples ?? []).compactMap { $0 as? HKWorkout }
                let entries = workouts.map { workout in
                    WorkoutEntry(
                        id: workout.uuid,
                        start: workout.startDate,
                        minutes: Int((workout.duration / 60).rounded()),
                        kind: HealthKitService.kind(for: workout.workoutActivityType),
                        source: .health,
                        calendar: calendar
                    )
                }
                continuation.resume(returning: entries)
            }
            store.execute(query)
        }
    }

    /// Calls `onChange` whenever Health records a new workout, including while Nivli is in
    /// the background. Idempotent: an existing observer is stopped first.
    func startObserving(_ onChange: @escaping @Sendable () async -> Void) {
        guard isAvailable else { return }
        let workoutType = HKObjectType.workoutType()
        if let existing = observerQuery {
            store.stop(existing)
            observerQuery = nil
        }

        let query = HKObserverQuery(sampleType: workoutType, predicate: nil) { [logger] _, completionHandler, error in
            if let error {
                logger.error("Health observer failed: \(error.localizedDescription, privacy: .public)")
            }
            Task {
                await onChange()
                completionHandler()
            }
        }
        observerQuery = query
        store.execute(query)

        store.enableBackgroundDelivery(for: workoutType, frequency: .immediate) { [logger] enabled, error in
            if let error {
                logger.error("Background delivery failed: \(error.localizedDescription, privacy: .public)")
            } else {
                logger.log("Health background delivery enabled=\(enabled, privacy: .private)")
            }
        }
    }

    /// The off switch. Stops the observer and hands background delivery back to iOS, so
    /// turning Apple Health off in Settings really does stop Nivli waking for workouts —
    /// iOS keeps delivering to an app that never disabled it, whatever the app's own
    /// settings say. Safe to call when nothing is running.
    func stopObserving() {
        if let existing = observerQuery {
            store.stop(existing)
            observerQuery = nil
        }
        store.disableAllBackgroundDelivery { [logger] _, error in
            if let error {
                logger.error("Background delivery could not be disabled: \(error.localizedDescription, privacy: .public)")
            } else {
                logger.log("Health background delivery disabled")
            }
        }
    }
}
