import Foundation
import HealthKit
import XCTest
@testable import Nivli

/// Health's activity types, reduced to Nivli's nine kinds. Pure lookup, so it runs anywhere.
final class HealthKitMappingTests: XCTestCase {
    func testCommonActivityTypesMapToTheirKind() {
        // Arrange
        let expected: [(HKWorkoutActivityType, WorkoutKind)] = [
            (.running, .run),
            (.walking, .walk),
            (.hiking, .walk),
            (.traditionalStrengthTraining, .strength),
            (.functionalStrengthTraining, .strength),
            (.coreTraining, .strength),
            (.cycling, .cycle),
            (.swimming, .swim),
            (.yoga, .yoga),
            (.pilates, .yoga),
            (.flexibility, .yoga),
            (.highIntensityIntervalTraining, .hiit),
            (.crossTraining, .hiit),
            (.mixedCardio, .hiit),
            (.soccer, .sport),
            (.basketball, .sport),
            (.tennis, .sport),
        ]

        for (type, kind) in expected {
            // Act
            let mapped = HealthKitService.kind(for: type)

            // Assert
            XCTAssertEqual(mapped, kind, "\(type.rawValue) should map to \(kind.rawValue)")
        }
    }

    func testAnythingElseIsOther() {
        // Arrange
        let unmapped: [HKWorkoutActivityType] = [.archery, .bowling, .curling, .fishing, .other]

        for type in unmapped {
            // Act
            let mapped = HealthKitService.kind(for: type)

            // Assert
            XCTAssertEqual(mapped, .other, "\(type.rawValue) should fall back to .other")
        }
    }
}
