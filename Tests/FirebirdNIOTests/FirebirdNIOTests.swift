import XCTest
@testable import FirebirdNIO2
import Firebird
import AsyncKit

final class FirebirdNIOTests: XCTestCase {
	
	private let configuration = FirebirdConnectionConfiguration(
		hostname: "localhost",
		port: 3051,
		username: "SYSDBA",
		password: "MASTERKEY",
		database: "EMPLOYEE")
	
    func testExample() throws {
		let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
		try FirebirdNIOConnection.connect(self.configuration, on: eventLoop).whenSuccess { print($0.connection) }
		print("fini!")
		sleep(10)
	}

    static var allTests = [
        ("testExample", testExample),
    ]
}
