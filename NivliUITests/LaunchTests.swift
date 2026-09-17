import XCTest

/// One smoke test: a fresh install launches and shows the first onboarding page.
///
/// `-nivli-reset` empties the App Group before the model is built, so the run never depends
/// on what a previous run left behind.
final class LaunchTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsTheFirstOnboardingPage() {
        // Arrange
        let app = XCUIApplication()
        app.launchArguments = ["-nivli-reset"]

        // Act
        app.launch()

        // Assert
        XCTAssertTrue(app.buttons["onboardingPrimaryButton"].waitForExistence(timeout: 10))
    }
}
