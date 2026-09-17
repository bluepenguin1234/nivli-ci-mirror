import Foundation
import XCTest
@testable import Nivli

final class StreakEngineTests: XCTestCase {
    // 2026-09-16 is a Wednesday in the test calendar.
    private let wednesday = day(2026, 9, 16)
    private let tuesday = day(2026, 9, 15)
    private let monday = day(2026, 9, 14)
    private let sunday = day(2026, 9, 13)
    private let saturday = day(2026, 9, 12)

    // MARK: - streak

    func testStreakIsZeroWithNoWorkouts() {
        // Arrange
        let state = makeState()

        // Act
        let streak = StreakEngine.streak(state, today: wednesday, calendar: testCalendar)

        // Assert
        XCTAssertEqual(streak, 0)
    }

    func testStreakCountsThreeConsecutiveQualifyingDays() {
        // Arrange
        let state = makeState(workouts: [
            makeWorkout(on: monday, minutes: 30),
            makeWorkout(on: tuesday, minutes: 25),
            makeWorkout(on: wednesday, minutes: 45),
        ])

        // Act
        let streak = StreakEngine.streak(state, today: wednesday, calendar: testCalendar)

        // Assert
        XCTAssertEqual(streak, 3)
    }

    func testStreakStopsAtAMissedDay() {
        // Arrange — Sunday and Monday done, Tuesday missed, Wednesday done.
        let state = makeState(workouts: [
            makeWorkout(on: sunday, minutes: 30),
            makeWorkout(on: monday, minutes: 30),
            makeWorkout(on: wednesday, minutes: 30),
        ])

        // Act
        let streak = StreakEngine.streak(state, today: wednesday, calendar: testCalendar)

        // Assert
        XCTAssertEqual(streak, 1)
    }

    func testStreakKeepsYesterdaysCountWhenTodayIsNotDoneYet() {
        // Arrange
        let state = makeState(workouts: [
            makeWorkout(on: monday, minutes: 30),
            makeWorkout(on: tuesday, minutes: 30),
        ])

        // Act
        let streak = StreakEngine.streak(state, today: wednesday, calendar: testCalendar)

        // Assert
        XCTAssertEqual(streak, 2)
    }

    func testWeeklyRestDayBridgesTwoWorkoutDaysWithoutCounting() {
        // Arrange — Sunday is a weekly rest day; Saturday and Monday are done.
        let state = makeState(
            weeklyRestDays: [1],
            workouts: [
                makeWorkout(on: saturday, minutes: 30),
                makeWorkout(on: monday, minutes: 30),
            ]
        )

        // Act
        let streak = StreakEngine.streak(state, today: monday, calendar: testCalendar)

        // Assert
        XCTAssertEqual(streak, 2)
    }

    func testOneOffRestDayBridgesTwoWorkoutDaysWithoutCounting() {
        // Arrange — Tuesday was taken off explicitly.
        let state = makeState(
            oneOffRestDays: [tuesday],
            workouts: [
                makeWorkout(on: monday, minutes: 30),
                makeWorkout(on: wednesday, minutes: 30),
            ]
        )

        // Act
        let streak = StreakEngine.streak(state, today: wednesday, calendar: testCalendar)

        // Assert
        XCTAssertEqual(streak, 2)
    }

    func testWorkoutUnderTheMinimumDoesNotCount() {
        // Arrange
        let state = makeState(
            minimumMinutes: 20,
            workouts: [
                makeWorkout(on: tuesday, minutes: 30),
                makeWorkout(on: wednesday, minutes: 15),
            ]
        )

        // Act
        let streak = StreakEngine.streak(state, today: wednesday, calendar: testCalendar)

        // Assert — Wednesday is not done, so the streak is still Tuesday's one day.
        XCTAssertEqual(streak, 1)
    }

    func testWorkoutExactlyAtTheMinimumCounts() {
        // Arrange
        let state = makeState(minimumMinutes: 20, workouts: [makeWorkout(on: wednesday, minutes: 20)])

        // Act
        let streak = StreakEngine.streak(state, today: wednesday, calendar: testCalendar)

        // Assert
        XCTAssertEqual(streak, 1)
    }

    // MARK: - qualifyingWorkout and workouts(on:)

    func testQualifyingWorkoutReturnsTheFirstLongEnoughEntryThatDay() {
        // Arrange
        let short = makeWorkout(on: wednesday, minutes: 10, kind: .walk, hour: 7)
        let long = makeWorkout(on: wednesday, minutes: 40, kind: .run, hour: 8)
        let state = makeState(minimumMinutes: 20, workouts: [short, long])

        // Act
        let qualifying = StreakEngine.qualifyingWorkout(state, day: wednesday)

        // Assert
        XCTAssertEqual(qualifying, long)
    }

    func testQualifyingWorkoutIsNilWhenEverythingIsTooShort() {
        // Arrange
        let state = makeState(minimumMinutes: 20, workouts: [makeWorkout(on: wednesday, minutes: 19)])

        // Act
        let qualifying = StreakEngine.qualifyingWorkout(state, day: wednesday)

        // Assert
        XCTAssertNil(qualifying)
    }

    func testWorkoutsOnDayReturnsOnlyThatDay() {
        // Arrange
        let state = makeState(workouts: [
            makeWorkout(on: tuesday, minutes: 30),
            makeWorkout(on: wednesday, minutes: 30, hour: 7),
            makeWorkout(on: wednesday, minutes: 45, hour: 18),
        ])

        // Act
        let entries = StreakEngine.workouts(state, on: wednesday)

        // Assert
        XCTAssertEqual(entries.count, 2)
        XCTAssertTrue(entries.allSatisfy { $0.day == self.wednesday })
    }

    // MARK: - isRestDay

    func testIsRestDayIsFalseWhenNothingIsConfigured() {
        // Arrange
        let state = makeState()

        // Act & Assert
        XCTAssertFalse(StreakEngine.isRestDay(state, day: sunday, calendar: testCalendar))
    }

    func testIsRestDayMatchesAWeeklyWeekdayNumber() {
        // Arrange — 1 is Sunday.
        let state = makeState(weeklyRestDays: [1])

        // Act & Assert
        XCTAssertTrue(StreakEngine.isRestDay(state, day: sunday, calendar: testCalendar))
        XCTAssertFalse(StreakEngine.isRestDay(state, day: monday, calendar: testCalendar))
    }

    func testIsRestDayMatchesAOneOffDay() {
        // Arrange
        let state = makeState(oneOffRestDays: [wednesday])

        // Act & Assert
        XCTAssertTrue(StreakEngine.isRestDay(state, day: wednesday, calendar: testCalendar))
        XCTAssertFalse(StreakEngine.isRestDay(state, day: tuesday, calendar: testCalendar))
    }

    // MARK: - longestStreak

    func testLongestStreakFindsTheBestRunInHistory() {
        // Arrange — a four-day run in July, a two-day run in September.
        let july = [
            makeWorkout(on: day(2026, 7, 1), minutes: 30),
            makeWorkout(on: day(2026, 7, 2), minutes: 30),
            makeWorkout(on: day(2026, 7, 3), minutes: 30),
            makeWorkout(on: day(2026, 7, 4), minutes: 30),
        ]
        let september = [
            makeWorkout(on: tuesday, minutes: 30),
            makeWorkout(on: wednesday, minutes: 30),
        ]
        let state = makeState(workouts: july + september)

        // Act
        let longest = StreakEngine.longestStreak(state, calendar: testCalendar)

        // Assert
        XCTAssertEqual(longest, 4)
    }

    func testLongestStreakBridgesRestDaysAndIgnoresShortWorkouts() {
        // Arrange — Saturday and Monday done with Sunday as a weekly rest day; the short
        // Wednesday entry is not part of any run.
        let state = makeState(
            minimumMinutes: 20,
            weeklyRestDays: [1],
            workouts: [
                makeWorkout(on: saturday, minutes: 30),
                makeWorkout(on: monday, minutes: 30),
                makeWorkout(on: wednesday, minutes: 5),
            ]
        )

        // Act
        let longest = StreakEngine.longestStreak(state, calendar: testCalendar)

        // Assert
        XCTAssertEqual(longest, 2)
    }

    func testLongestStreakIsZeroWithNoQualifyingWorkouts() {
        // Arrange
        let state = makeState(minimumMinutes: 20, workouts: [makeWorkout(on: wednesday, minutes: 5)])

        // Act
        let longest = StreakEngine.longestStreak(state, calendar: testCalendar)

        // Assert
        XCTAssertEqual(longest, 0)
    }

    func testLongestStreakCountsADayOnlyOnceWhenTwoWorkoutsQualify() {
        // Arrange
        let state = makeState(workouts: [
            makeWorkout(on: wednesday, minutes: 30, hour: 7),
            makeWorkout(on: wednesday, minutes: 40, hour: 19),
        ])

        // Act
        let longest = StreakEngine.longestStreak(state, calendar: testCalendar)

        // Assert
        XCTAssertEqual(longest, 1)
    }

    // MARK: - weekStrip

    func testWeekStripReturnsSevenStatusesOldestFirst() {
        // Arrange
        let state = makeState()

        // Act
        let strip = StreakEngine.weekStrip(state, today: wednesday, calendar: testCalendar)

        // Assert
        XCTAssertEqual(strip.count, 7)
        XCTAssertEqual(strip.last, StreakEngine.DayStatus.today)
        XCTAssertEqual(Array(strip.dropLast()), Array(repeating: StreakEngine.DayStatus.missed, count: 6))
    }

    func testWeekStripMarksDoneRestMissedAndToday() {
        // Arrange — Sunday is a weekly rest day, Monday and Tuesday done, today not yet.
        let state = makeState(
            weeklyRestDays: [1],
            workouts: [
                makeWorkout(on: monday, minutes: 30),
                makeWorkout(on: tuesday, minutes: 30),
            ]
        )

        // Act
        let strip: [StreakEngine.DayStatus] = StreakEngine.weekStrip(state, today: wednesday, calendar: testCalendar)

        // Assert — Thu, Fri, Sat, Sun, Mon, Tue, Wed.
        XCTAssertEqual(strip, [.missed, .missed, .missed, .rest, .done, .done, .today])
    }

    func testWeekStripMarksTodayDoneWhenTodayQualifies() {
        // Arrange
        let state = makeState(workouts: [makeWorkout(on: wednesday, minutes: 30)])

        // Act
        let strip = StreakEngine.weekStrip(state, today: wednesday, calendar: testCalendar)

        // Assert
        XCTAssertEqual(strip.last, StreakEngine.DayStatus.done)
    }

    // MARK: - milestones

    func testMilestoneReachedReturnsTheMatchingMilestone() {
        // Act & Assert
        XCTAssertEqual(StreakEngine.milestoneReached(streak: 7), 7)
        XCTAssertEqual(StreakEngine.milestoneReached(streak: 365), 365)
    }

    func testMilestoneReachedIsNilBetweenMilestones() {
        // Act & Assert
        XCTAssertNil(StreakEngine.milestoneReached(streak: 0))
        XCTAssertNil(StreakEngine.milestoneReached(streak: 8))
        XCTAssertNil(StreakEngine.milestoneReached(streak: 366))
    }

    // MARK: - adding and merging

    func testAddingWorkoutKeepsTheListSortedByStart() {
        // Arrange
        let evening = makeWorkout(on: wednesday, minutes: 30, hour: 19)
        let morning = makeWorkout(on: wednesday, minutes: 20, hour: 6)
        let state = makeState(workouts: [evening])

        // Act
        let updated = StreakEngine.addingWorkout(state, morning)

        // Assert
        XCTAssertEqual(updated.workouts.map(\.id), [morning.id, evening.id])
    }

    func testAddingWorkoutWithAKnownIdReplacesRatherThanDuplicates() {
        // Arrange
        let original = makeWorkout(on: wednesday, minutes: 20)
        let corrected = original.withMinutes(45)
        let state = makeState(workouts: [original])

        // Act
        let updated = StreakEngine.addingWorkout(state, corrected)

        // Assert
        XCTAssertEqual(updated.workouts.count, 1)
        XCTAssertEqual(updated.workouts.first?.minutes, 45)
    }

    func testAddingWorkoutDoesNotMutateTheOriginalState() {
        // Arrange
        let state = makeState()

        // Act
        _ = StreakEngine.addingWorkout(state, makeWorkout(on: wednesday, minutes: 30))

        // Assert
        XCTAssertTrue(state.workouts.isEmpty)
    }

    func testMergingHealthWorkoutsSkipsIdsAlreadyStored() {
        // Arrange
        let known = makeWorkout(on: tuesday, minutes: 30, source: .health)
        let fresh = makeWorkout(on: wednesday, minutes: 40, source: .health)
        let state = makeState(workouts: [known])

        // Act
        let result = StreakEngine.mergingHealthWorkouts(state, [known, fresh])

        // Assert
        XCTAssertEqual(result.added, [fresh])
        XCTAssertEqual(result.state.workouts.count, 2)
    }

    func testMergingHealthWorkoutsReturnsTheSameStateWhenNothingIsNew() {
        // Arrange
        let known = makeWorkout(on: wednesday, minutes: 30, source: .health)
        let state = makeState(workouts: [known])

        // Act
        let result = StreakEngine.mergingHealthWorkouts(state, [known])

        // Assert
        XCTAssertTrue(result.added.isEmpty)
        XCTAssertEqual(result.state, state)
    }

    func testMergingHealthWorkoutsDeduplicatesWithinTheIncomingBatch() {
        // Arrange
        let entry = makeWorkout(on: wednesday, minutes: 30, source: .health)
        let state = makeState()

        // Act
        let result = StreakEngine.mergingHealthWorkouts(state, [entry, entry])

        // Assert
        XCTAssertEqual(result.added.count, 1)
        XCTAssertEqual(result.state.workouts.count, 1)
    }
}
