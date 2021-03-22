import XCTest
@testable import FirebirdNIO

final class firebird_nioTests: XCTestCase {
    func testExample() {
		let fir = Firebird()
		let code = fir.status
		XCTAssertNotNil(code)
		print(code)
	}

    static var allTests = [
        ("testExample", testExample),
    ]
}
