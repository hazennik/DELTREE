//
//  DELTREEUITests.swift
//  DELTREEUITests
//
//  DELTREE UI tests.
//

import XCTest

final class DELTREEUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testMenuBarAgentLaunches() throws {
        let app = XCUIApplication()
        app.launchEnvironment["DELTREE_DISABLE_INITIAL_SCAN"] = "1"
        app.launch()

        XCTAssertTrue(
            app.state == .runningForeground || app.state == .runningBackground,
            "DELTREE should keep running as an LSUIElement menu-bar app.")
    }

    @MainActor
    func testMenuBarAgentDoesNotOpenDashboardByDefault() throws {
        let app = XCUIApplication()
        app.launchEnvironment["DELTREE_DISABLE_INITIAL_SCAN"] = "1"
        app.launch()

        XCTAssertEqual(app.windows.count, 0, "DELTREE should launch as a menu-bar agent without opening a dashboard window.")
    }
}
