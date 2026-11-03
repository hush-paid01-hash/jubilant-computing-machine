import XCTest
@testable import RunnerSmokeTest

final class RunnerCheckTests: XCTestCase {
    func testRunnerCheckStatus() {
        XCTAssertEqual(RunnerCheck.status(), "Universal Project Runner is working")
    }
}
