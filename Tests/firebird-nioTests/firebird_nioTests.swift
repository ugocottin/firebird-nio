import XCTest
@testable import firebird_nio

final class firebird_nioTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(firebird_nio().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
