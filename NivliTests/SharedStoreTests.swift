import Foundation
import XCTest
@testable import Nivli

final class SharedStoreTests: XCTestCase {
    private var directory = URL(fileURLWithPath: NSTemporaryDirectory())

    override func setUp() {
        super.setUp()
        directory = throwawayDirectory()
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    func testLoadReturnsDefaultsWhenNothingWasEverSaved() {
        // Arrange
        let store = SharedStore(directory: directory)

        // Act
        let state = store.load()

        // Assert
        XCTAssertEqual(state, NivliState())
        XCTAssertFalse(state.onboardingComplete)
        XCTAssertEqual(state.minimumMinutes, SharedConstants.defaultMinimumMinutes)
    }

    func testSaveThenLoadRoundTripsTheState() {
        // Arrange
        let store = SharedStore(directory: directory)
        let workout = makeWorkout(on: day(2026, 9, 16), minutes: 42, kind: .cycle, source: .health)
        let saved = makeState(
            minimumMinutes: 45,
            weeklyRestDays: [1, 7],
            oneOffRestDays: [day(2026, 9, 15)],
            workouts: [workout],
            entitlementValidUntil: nil,
            healthEnabled: true,
            reminderEnabled: true,
            goals: [.habit, .sleep],
            currentFrequency: .threeToFour,
            dailyPhoneHours: .threePlus
        )

        // Act
        store.save(saved)
        let loaded = store.load()

        // Assert — everything but the test-only override, which is deliberately not stored.
        XCTAssertTrue(loaded.onboardingComplete)
        XCTAssertEqual(loaded.minimumMinutes, 45)
        XCTAssertEqual(loaded.weeklyRestDays, [1, 7])
        XCTAssertEqual(loaded.oneOffRestDays, [day(2026, 9, 15)])
        XCTAssertEqual(loaded.workouts.map(\.id), [workout.id])
        XCTAssertEqual(loaded.workouts.first?.minutes, 42)
        XCTAssertEqual(loaded.workouts.first?.kind, .cycle)
        XCTAssertEqual(loaded.workouts.first?.source, .health)
        XCTAssertTrue(loaded.healthEnabled)
        XCTAssertTrue(loaded.reminderEnabled)
        XCTAssertEqual(loaded.goals, [.habit, .sleep])
        XCTAssertEqual(loaded.currentFrequency, .threeToFour)
        XCTAssertEqual(loaded.dailyPhoneHours, .threePlus)
        XCTAssertNil(loaded.selectionOverrideForTesting)
    }

    func testEntitlementDateSurvivesTheRoundTripToTheSecond() {
        // Arrange — the encoder uses ISO-8601, which has no sub-second precision.
        let store = SharedStore(directory: directory)
        let validUntil = Date(timeIntervalSince1970: 1_800_000_000)

        // Act
        store.save(makeState(entitlementValidUntil: validUntil))
        let loaded = store.load()

        // Assert
        XCTAssertEqual(loaded.entitlementValidUntil?.timeIntervalSince1970, validUntil.timeIntervalSince1970)
    }

    func testCorruptDataLoadsAsTheDefaultStateInsteadOfThrowing() throws {
        // Arrange
        let garbage = try XCTUnwrap("this is not JSON".data(using: .utf8))
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try garbage.write(to: directory.appendingPathComponent(SharedConstants.stateFileName))
        let store = SharedStore(directory: directory)

        // Act
        let state = store.load()

        // Assert
        XCTAssertEqual(state, NivliState())
    }

    func testUpdateReturnsAndPersistsTheChangedState() {
        // Arrange
        let store = SharedStore(directory: directory)

        // Act
        let returned = store.update { state in
            state.onboardingComplete = true
            state.minimumMinutes = 60
        }

        // Assert
        XCTAssertTrue(returned.onboardingComplete)
        XCTAssertEqual(returned.minimumMinutes, 60)
        XCTAssertEqual(store.load().minimumMinutes, 60)
    }

    func testUpdateBuildsOnWhatIsAlreadyStored() {
        // Arrange
        let store = SharedStore(directory: directory)
        store.update { $0.minimumMinutes = 30 }

        // Act
        let returned = store.update { $0.healthEnabled = true }

        // Assert
        XCTAssertEqual(returned.minimumMinutes, 30)
        XCTAssertTrue(returned.healthEnabled)
    }

    func testResetForgetsEverything() {
        // Arrange
        let store = SharedStore(directory: directory)
        store.update { $0.onboardingComplete = true }

        // Act
        store.reset()

        // Assert
        XCTAssertEqual(store.load(), NivliState())
    }

    func testTwoStoresOnTheSameFolderSeeEachOthersWrites() {
        // Arrange
        let writer = SharedStore(directory: directory)
        let reader = SharedStore(directory: directory)

        // Act
        writer.update { $0.minimumMinutes = 15 }

        // Assert
        XCTAssertEqual(reader.load().minimumMinutes, 15)
    }
}
