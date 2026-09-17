import Foundation
import XCTest
@testable import Nivli

final class DayKeyTests: XCTestCase {
    func testInitFromDateUsesTheLocalCalendarDay() throws {
        // Arrange
        let components = DateComponents(year: 2026, month: 9, day: 16, hour: 23, minute: 30)

        // Act
        let date = try XCTUnwrap(testCalendar.date(from: components))
        let key = DayKey(date, calendar: testCalendar)

        // Assert
        XCTAssertEqual(key, day(2026, 9, 16))
    }

    func testDescriptionIsZeroPaddedISOStyle() {
        // Arrange
        let key = day(2026, 9, 6)

        // Act
        let text = key.description

        // Assert
        XCTAssertEqual(text, "2026-09-06")
    }

    func testDateInCalendarIsTheStartOfTheDay() {
        // Arrange
        let key = day(2026, 9, 16)

        // Act
        let start = key.date(in: testCalendar)

        // Assert
        let parts = testCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: start)
        XCTAssertEqual(parts.year, 2026)
        XCTAssertEqual(parts.month, 9)
        XCTAssertEqual(parts.day, 16)
        XCTAssertEqual(parts.hour, 0)
        XCTAssertEqual(parts.minute, 0)
        XCTAssertEqual(parts.second, 0)
    }

    func testPreviousCrossesAMonthBoundary() {
        // Arrange
        let first = day(2026, 9, 1)

        // Act
        let earlier = first.previous(in: testCalendar)

        // Assert
        XCTAssertEqual(earlier, day(2026, 8, 31))
    }

    func testNextCrossesAYearBoundary() {
        // Arrange
        let lastDay = day(2026, 12, 31)

        // Act
        let later = lastDay.next(in: testCalendar)

        // Assert
        XCTAssertEqual(later, day(2027, 1, 1))
    }

    func testPreviousCrossesALeapDay() {
        // Arrange
        let firstOfMarch = day(2028, 3, 1)

        // Act
        let earlier = firstOfMarch.previous(in: testCalendar)

        // Assert
        XCTAssertEqual(earlier, day(2028, 2, 29))
    }

    func testWeekdayUsesCalendarNumbering() {
        // Arrange
        let sunday = day(2026, 9, 13)
        let wednesday = day(2026, 9, 16)

        // Act
        let sundayNumber = sunday.weekday(in: testCalendar)
        let wednesdayNumber = wednesday.weekday(in: testCalendar)

        // Assert
        XCTAssertEqual(sundayNumber, 1)
        XCTAssertEqual(wednesdayNumber, 4)
    }

    func testComparableOrdersChronologically() {
        // Arrange
        let earlier = day(2026, 9, 16)
        let sameMonthLater = day(2026, 9, 17)
        let laterMonth = day(2026, 10, 1)
        let laterYear = day(2027, 1, 1)

        // Act
        let sorted = [laterYear, laterMonth, sameMonthLater, earlier].sorted()

        // Assert
        XCTAssertEqual(sorted, [earlier, sameMonthLater, laterMonth, laterYear])
        XCTAssertTrue(earlier < sameMonthLater)
        XCTAssertFalse(laterMonth < sameMonthLater)
    }

    func testTodayMatchesTheGivenNow() {
        // Arrange
        let now = noon(on: day(2026, 9, 16))

        // Act
        let today = DayKey.today(calendar: testCalendar, now: now)

        // Assert
        XCTAssertEqual(today, day(2026, 9, 16))
    }

    func testRoundTripsThroughJSON() throws {
        // Arrange
        let key = day(2026, 9, 16)

        // Act
        let data = try JSONEncoder().encode(key)
        let decoded = try JSONDecoder().decode(DayKey.self, from: data)

        // Assert
        XCTAssertEqual(decoded, key)
    }
}
