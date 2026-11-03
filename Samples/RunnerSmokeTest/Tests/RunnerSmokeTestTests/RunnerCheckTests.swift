import XCTest
@testable import RunnerSmokeTestLibrary

final class RunnerCheckTests: XCTestCase {
    func testRunnerCheckStatus() {
        XCTAssertEqual(RunnerCheck.status(), "Universal Project Runner executable is working")
    }
}
