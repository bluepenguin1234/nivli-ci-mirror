import Foundation
import HealthKit

extension HealthKitService {
    /// Which of Nivli's nine kinds a Health workout is shown as.
    ///
    /// Pure and total: Health knows roughly eighty activity types and Nivli shows nine, so
    /// anything unrecognised becomes `.other`. The kind only picks an icon and a word — it
    /// never decides whether a workout counts, which is duration alone.
    static func kind(for type: HKWorkoutActivityType) -> WorkoutKind {
        switch type {
        case .running:
            return .run
        case .walking, .hiking:
            return .walk
        case .traditionalStrengthTraining, .functionalStrengthTraining, .coreTraining:
            return .strength
        case .cycling:
            return .cycle
        case .swimming:
            return .swim
        case .yoga, .pilates, .flexibility:
            return .yoga
        case .highIntensityIntervalTraining, .crossTraining, .mixedCardio:
            return .hiit
        case .soccer, .basketball, .tennis, .americanFootball, .australianFootball,
             .badminton, .baseball, .cricket, .golf, .handball, .hockey, .lacrosse,
             .racquetball, .rugby, .softball, .squash, .tableTennis, .volleyball:
            return .sport
        default:
            return .other
        }
    }
}
