import Foundation
import XCTest
@testable import Nivli

final class OnboardingModelTests: XCTestCase {
    func testWelcomeAlwaysContinues() {
        // Arrange
        let draft = OnboardingDraft()

        // Act
        let allowed = OnboardingModel.canContinue(step: 0, draft: draft, selectionOK: false)

        // Assert
        XCTAssertTrue(allowed)
    }

    func testGoalsNeedAtLeastOneChoice() {
        // Arrange
        var draft = OnboardingDraft()

        // Act
        let before = OnboardingModel.canContinue(step: 1, draft: draft, selectionOK: false)
        draft.goals = [.habit]
        let after = OnboardingModel.canContinue(step: 1, draft: draft, selectionOK: false)

        // Assert
        XCTAssertFalse(before)
        XCTAssertTrue(after)
    }

    func testFrequencyAndPhoneHoursNeedAnAnswer() {
        // Arrange
        var draft = OnboardingDraft()

        // Act & Assert
        XCTAssertFalse(OnboardingModel.canContinue(step: 2, draft: draft, selectionOK: false))
        draft.frequency = .rarely
        XCTAssertTrue(OnboardingModel.canContinue(step: 2, draft: draft, selectionOK: false))

        XCTAssertFalse(OnboardingModel.canContinue(step: 3, draft: draft, selectionOK: false))
        draft.phoneHours = .unknown
        XCTAssertTrue(OnboardingModel.canContinue(step: 3, draft: draft, selectionOK: false))
    }

    func testAppsPageIsGatedOnlyByTheSelection() {
        // Arrange
        let draft = OnboardingDraft()

        // Act & Assert
        XCTAssertFalse(OnboardingModel.canContinue(step: 4, draft: draft, selectionOK: false))
        XCTAssertTrue(OnboardingModel.canContinue(step: 4, draft: draft, selectionOK: true))
    }

    func testLaterPagesAlwaysContinue() {
        // Arrange
        let draft = OnboardingDraft()

        // Act & Assert
        for step in 5..<OnboardingModel.pageCount {
            XCTAssertTrue(OnboardingModel.canContinue(step: step, draft: draft, selectionOK: false), "step \(step)")
        }
    }

    func testButtonTitlesMatchThePages() {
        // Assert
        XCTAssertEqual(OnboardingModel.primaryTitle(step: 0), "Get started")
        XCTAssertEqual(OnboardingModel.primaryTitle(step: 6), "Turn on reminders")
        XCTAssertEqual(OnboardingModel.primaryTitle(step: 7), "Continue")
        XCTAssertEqual(OnboardingModel.secondaryTitle(step: 6), "Not now")
        XCTAssertNil(OnboardingModel.secondaryTitle(step: 5))
    }

    func testReminderTimeRoundTripsThroughMinutes() {
        // Arrange
        let minutes = 18 * 60 + 30

        // Act
        let date = OnboardingModel.date(fromMinutesFromMidnight: minutes, calendar: testCalendar)
        let back = OnboardingModel.minutesFromMidnight(for: date, calendar: testCalendar)

        // Assert
        XCTAssertEqual(back, minutes)
    }

    func testReminderMinutesAreClampedToOneDay() {
        // Act
        let date = OnboardingModel.date(fromMinutesFromMidnight: 99_999, calendar: testCalendar)
        let back = OnboardingModel.minutesFromMidnight(for: date, calendar: testCalendar)

        // Assert
        XCTAssertEqual(back, 23 * 60 + 59)
    }
}
