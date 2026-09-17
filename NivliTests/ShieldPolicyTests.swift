import Foundation
import XCTest
@testable import Nivli

final class ShieldPolicyTests: XCTestCase {
    // 2026-09-16 is a Wednesday in the test calendar.
    private let today = day(2026, 9, 16)
    private lazy var now = noon(on: today)

    // MARK: - each open reason

    func testNeverSubscribedIsOpenBecauseNotSubscribed() {
        // Arrange
        let state = makeState(entitlementValidUntil: nil)

        // Act
        let decision = ShieldPolicy.decision(state, now: now, calendar: testCalendar)

        // Assert
        XCTAssertEqual(decision, .open(.notSubscribed))
        XCTAssertFalse(decision.isLocked)
    }

    func testExpiredEntitlementIsOpenBecauseNotSubscribed() {
        // Arrange
        let state = makeState(entitlementValidUntil: now.addingTimeInterval(-1))

        // Act
        let decision = ShieldPolicy.decision(state, now: now, calendar: testCalendar)

        // Assert
        XCTAssertEqual(decision, .open(.notSubscribed))
    }

    func testEntitlementValidExactlyNowStillCounts() {
        // Arrange
        let state = makeState(entitlementValidUntil: now)

        // Act
        let decision = ShieldPolicy.decision(state, now: now, calendar: testCalendar)

        // Assert — the subscription check passes, so the decision moves on down the list.
        XCTAssertEqual(decision, .locked)
    }

    func testUnfinishedOnboardingIsOpenBecauseNotOnboarded() {
        // Arrange
        let state = makeState(onboardingComplete: false)

        // Act
        let decision = ShieldPolicy.decision(state, now: now, calendar: testCalendar)

        // Assert
        XCTAssertEqual(decision, .open(.notOnboarded))
    }

    func testEmptySelectionIsOpenBecauseNothingSelected() {
        // Arrange
        let state = makeState(hasSelection: false)

        // Act
        let decision = ShieldPolicy.decision(state, now: now, calendar: testCalendar)

        // Assert
        XCTAssertEqual(decision, .open(.nothingSelected))
    }

    func testWeeklyRestDayIsOpenBecauseRestDay() {
        // Arrange — 4 is Wednesday.
        let state = makeState(weeklyRestDays: [4])

        // Act
        let decision = ShieldPolicy.decision(state, now: now, calendar: testCalendar)

        // Assert
        XCTAssertEqual(decision, .open(.restDay))
    }

    func testOneOffRestDayIsOpenBecauseRestDay() {
        // Arrange
        let state = makeState(oneOffRestDays: [today])

        // Act
        let decision = ShieldPolicy.decision(state, now: now, calendar: testCalendar)

        // Assert
        XCTAssertEqual(decision, .open(.restDay))
    }

    func testQualifyingWorkoutTodayIsOpenBecauseWorkedOut() {
        // Arrange
        let workout = makeWorkout(on: today, minutes: 42, kind: .run, source: .health)
        let state = makeState(workouts: [workout])

        // Act
        let decision = ShieldPolicy.decision(state, now: now, calendar: testCalendar)

        // Assert
        XCTAssertEqual(decision, .open(.workedOut(workout)))
    }

    // MARK: - locked

    func testLockedWhenSubscribedOnboardedSelectedNotRestingAndNotDone() {
        // Arrange
        let state = makeState(workouts: [makeWorkout(on: today, minutes: 10)])

        // Act
        let decision = ShieldPolicy.decision(state, now: now, calendar: testCalendar)

        // Assert — the 10-minute log is under the 20-minute minimum, so it does not unlock.
        XCTAssertEqual(decision, .locked)
        XCTAssertTrue(decision.isLocked)
    }

    func testYesterdaysWorkoutDoesNotUnlockToday() {
        // Arrange
        let state = makeState(workouts: [makeWorkout(on: today.previous(in: testCalendar), minutes: 60)])

        // Act
        let decision = ShieldPolicy.decision(state, now: now, calendar: testCalendar)

        // Assert
        XCTAssertEqual(decision, .locked)
    }

    // MARK: - order of precedence

    func testSubscriptionIsCheckedBeforeEverythingElse() {
        // Arrange — every other reason to be open is also true.
        let state = makeState(
            onboardingComplete: false,
            hasSelection: false,
            oneOffRestDays: [today],
            workouts: [makeWorkout(on: today, minutes: 60)],
            entitlementValidUntil: nil
        )

        // Act
        let decision = ShieldPolicy.decision(state, now: now, calendar: testCalendar)

        // Assert
        XCTAssertEqual(decision, .open(.notSubscribed))
    }

    func testOnboardingIsCheckedBeforeSelection() {
        // Arrange
        let state = makeState(onboardingComplete: false, hasSelection: false, oneOffRestDays: [today])

        // Act
        let decision = ShieldPolicy.decision(state, now: now, calendar: testCalendar)

        // Assert
        XCTAssertEqual(decision, .open(.notOnboarded))
    }

    func testSelectionIsCheckedBeforeRestDay() {
        // Arrange
        let state = makeState(
            hasSelection: false,
            oneOffRestDays: [today],
            workouts: [makeWorkout(on: today, minutes: 60)]
        )

        // Act
        let decision = ShieldPolicy.decision(state, now: now, calendar: testCalendar)

        // Assert
        XCTAssertEqual(decision, .open(.nothingSelected))
    }

    func testRestDayIsCheckedBeforeTodaysWorkout() {
        // Arrange
        let state = makeState(oneOffRestDays: [today], workouts: [makeWorkout(on: today, minutes: 60)])

        // Act
        let decision = ShieldPolicy.decision(state, now: now, calendar: testCalendar)

        // Assert
        XCTAssertEqual(decision, .open(.restDay))
    }
}
