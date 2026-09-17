import Foundation
import XCTest
@testable import Nivli

final class NivliStateTests: XCTestCase {
    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    // MARK: - forward-compatible decoding

    func testDecodesAnEmptyObjectAsTheDefaultState() throws {
        // Arrange
        let json = try XCTUnwrap("{}".data(using: .utf8))

        // Act
        let state = try decoder().decode(NivliState.self, from: json)

        // Assert
        XCTAssertEqual(state, NivliState())
    }

    func testDecodesAPartialPayloadAndFillsTheRestWithDefaults() throws {
        // Arrange — an older build that only ever wrote these three keys.
        let raw = """
        {"onboardingComplete":true,"minimumMinutes":45,"healthEnabled":true}
        """
        let json = try XCTUnwrap(raw.data(using: .utf8))

        // Act
        let state = try decoder().decode(NivliState.self, from: json)

        // Assert
        XCTAssertTrue(state.onboardingComplete)
        XCTAssertEqual(state.minimumMinutes, 45)
        XCTAssertTrue(state.healthEnabled)
        XCTAssertEqual(state.reminderMinutesFromMidnight, 18 * 60)
        XCTAssertTrue(state.workouts.isEmpty)
        XCTAssertTrue(state.weeklyRestDays.isEmpty)
        XCTAssertNil(state.entitlementValidUntil)
        XCTAssertNil(state.currentFrequency)
        XCTAssertNil(state.dailyPhoneHours)
    }

    func testDecodesUnknownKeysWithoutFailing() throws {
        // Arrange — a key a future build added.
        let raw = """
        {"minimumMinutes":10,"somethingFromTheFuture":{"a":1}}
        """
        let json = try XCTUnwrap(raw.data(using: .utf8))

        // Act
        let state = try decoder().decode(NivliState.self, from: json)

        // Assert
        XCTAssertEqual(state.minimumMinutes, 10)
    }

    func testTheTestOnlySelectionOverrideIsNeverEncoded() throws {
        // Arrange
        let state = NivliState().with { $0.selectionOverrideForTesting = true }

        // Act
        let data = try encoder().encode(state)
        let text = try XCTUnwrap(String(data: data, encoding: .utf8))
        let decoded = try decoder().decode(NivliState.self, from: data)

        // Assert
        XCTAssertFalse(text.contains("selectionOverrideForTesting"))
        XCTAssertNil(decoded.selectionOverrideForTesting)
    }

    func testRoundTripsAFullyPopulatedState() throws {
        // Arrange
        let workout = makeWorkout(on: day(2026, 9, 16), minutes: 30, kind: .yoga, source: .manual)
        let state = makeState(
            minimumMinutes: 15,
            weeklyRestDays: [1, 7],
            oneOffRestDays: [day(2026, 9, 14)],
            workouts: [workout],
            entitlementValidUntil: Date(timeIntervalSince1970: 1_800_000_000),
            goals: [.stronger],
            currentFrequency: .rarely,
            dailyPhoneHours: .two
        )

        // Act
        let decoded = try decoder().decode(NivliState.self, from: encoder().encode(state))

        // Assert — identical once the test-only override is dropped on both sides.
        XCTAssertEqual(decoded, state.with { $0.selectionOverrideForTesting = nil })
    }

    // MARK: - selection

    func testHasSelectionIsFalseForAFreshState() {
        // Arrange
        let state = NivliState()

        // Act & Assert
        XCTAssertFalse(state.hasSelection)
    }

    func testHasSelectionHonoursTheTestOnlyOverride() {
        // Arrange
        let forcedOn = NivliState().with { $0.selectionOverrideForTesting = true }
        let forcedOff = NivliState().with { $0.selectionOverrideForTesting = false }

        // Act & Assert
        XCTAssertTrue(forcedOn.hasSelection)
        XCTAssertFalse(forcedOff.hasSelection)
    }

    func testSelectionSummaryIsAllZerosWhenNothingIsChosen() {
        // Arrange
        let state = NivliState()

        // Act
        let summary = state.selectionSummary

        // Assert
        XCTAssertEqual(summary.apps, 0)
        XCTAssertEqual(summary.categories, 0)
        XCTAssertEqual(summary.sites, 0)
    }

    // MARK: - with

    func testWithReturnsACopyAndLeavesTheOriginalAlone() {
        // Arrange
        let original = NivliState()

        // Act
        let changed = original.with { $0.minimumMinutes = 60 }

        // Assert
        XCTAssertEqual(changed.minimumMinutes, 60)
        XCTAssertEqual(original.minimumMinutes, SharedConstants.defaultMinimumMinutes)
    }

    func testSortedWorkoutsOrdersOldestFirst() {
        // Arrange
        let later = makeWorkout(on: day(2026, 9, 16), minutes: 30, hour: 20)
        let earlier = makeWorkout(on: day(2026, 9, 16), minutes: 30, hour: 6)
        let state = NivliState().with { $0.workouts = [later, earlier] }

        // Act
        let sorted = state.sortedWorkouts()

        // Assert
        XCTAssertEqual(sorted.workouts.map(\.id), [earlier.id, later.id])
    }

    // MARK: - onboarding enums

    func testPhoneHoursDaysPerYear() {
        // Act & Assert
        XCTAssertEqual(PhoneHours.one.daysPerYear, 15)
        XCTAssertEqual(PhoneHours.two.daysPerYear, 30)
        XCTAssertEqual(PhoneHours.threePlus.daysPerYear, 46)
        XCTAssertNil(PhoneHours.unknown.daysPerYear)
    }

    func testPhoneHoursTitles() {
        // Act & Assert
        XCTAssertEqual(PhoneHours.one.title, "About an hour")
        XCTAssertEqual(PhoneHours.two.title, "2 hours")
        XCTAssertEqual(PhoneHours.threePlus.title, "3 hours or more")
        XCTAssertEqual(PhoneHours.unknown.title, "I'd rather not know")
    }

    func testEveryOnboardingEnumOffersEveryChoice() {
        // Act & Assert
        XCTAssertEqual(Goal.allCases.count, 5)
        XCTAssertEqual(Frequency.allCases.count, 4)
        XCTAssertEqual(PhoneHours.allCases.count, 4)
        XCTAssertEqual(WorkoutKind.allCases.count, 9)
    }

    func testGoalTitlesMatchTheOnboardingCopy() {
        // Act & Assert
        XCTAssertEqual(Goal.habit.title, "Build a workout habit")
        XCTAssertEqual(Goal.screenTime.title, "Cut my screen time")
        XCTAssertEqual(Goal.stronger.title, "Get stronger")
        XCTAssertEqual(Goal.feelBetter.title, "Feel better day to day")
        XCTAssertEqual(Goal.sleep.title, "Sleep better")
    }

    // MARK: - workout copy

    func testWorkoutSummaryReadsAsASentenceFragment() {
        // Arrange
        let run = makeWorkout(on: day(2026, 9, 16), minutes: 42, kind: .run, source: .health)
        let hiit = makeWorkout(on: day(2026, 9, 16), minutes: 20, kind: .hiit, source: .manual)

        // Act & Assert
        XCTAssertEqual(run.summary, "42 min run")
        XCTAssertEqual(run.sourceLabel, "Apple Health")
        XCTAssertEqual(hiit.summary, "20 min HIIT")
        XCTAssertEqual(hiit.sourceLabel, "logged by you")
    }

    func testEveryWorkoutKindHasATitleAndASymbol() {
        // Act & Assert
        for kind in WorkoutKind.allCases {
            XCTAssertFalse(kind.title.isEmpty, "\(kind) has no title")
            XCTAssertFalse(kind.symbolName.isEmpty, "\(kind) has no symbol")
        }
    }
}
