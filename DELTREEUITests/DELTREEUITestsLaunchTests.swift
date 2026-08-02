//
//  DELTREEUITestsLaunchTests.swift
//  DELTREEUITests
//
//  Created by Ryan Nicoletti on 8/1/26.
//

import XCTest

final class DELTREEUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchEnvironment["DELTREE_DISABLE_INITIAL_SCAN"] = "1"
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Menu Bar Agent Launch"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
