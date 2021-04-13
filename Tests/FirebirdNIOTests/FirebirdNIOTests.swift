import XCTest
import Firebird
@testable import FirebirdNIO

final class FirebirdNIOTests: XCTestCase {
	
	// MARK: - NIO stuff
	private static let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
	
	private var eventLoop: EventLoop {
		Self.eventLoopGroup.next()
	}
	
	override class func tearDown() {
		try! self.eventLoopGroup.syncShutdownGracefully()
	}
	
	// MARK: - Connection parameters
	private let hostname: String! = "localhost"
	
	private let port: UInt16? = 3050
	
	private let username: String! = "SYSDBA"
	
	private let password: String! = "MASTERKE"
	
	private let database: String! = "EMPLOYEE"
	
	private var configuration: FirebirdConnectionConfiguration {
		.init(
			hostname: self.hostname,
			port: self.port,
			username: self.username,
			password: self.password,
			database: self.database)
	}
	
	private var connection: EventLoopFuture<FirebirdNIOConnection>!
	
	override func setUp() {
		self.connection = FirebirdNIOConnection
			.connect(
				self.configuration,
				logger: Logger(label: "testing.firebird"),
				on: self.eventLoop)
	}
	
	override func tearDownWithError() throws {
		try self.connection.wait().close().wait()
	}
	
	func testConnection() throws {
		let futureResults = self.connection.flatMap { conn in
			conn.query("SELECT emp_no FROM employee")
		}
		
		XCTAssertNoThrow {
			let results = try futureResults.wait()
			XCTAssertGreaterThan(results.count, 0)
		}
	}
	
    static var allTests = [
        ("testConnection", testConnection),
    ]
}
