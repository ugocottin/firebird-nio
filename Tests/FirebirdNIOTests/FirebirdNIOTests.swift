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
	private var hostname: String {
		guard let hostname = ProcessInfo.processInfo.environment["FB_TEST_HOSTNAME"] else {
			fatalError("FB_TEST_HOSTNAME is not defined")
		}
		
		return hostname
	}
	
	private var port: UInt16? {
		guard let port = ProcessInfo.processInfo.environment["FB_TEST_PORT"] else { return nil }
		
		return UInt16(port)
	}
	
	private var username: String {
		guard let username = ProcessInfo.processInfo.environment["FB_TEST_USERNAME"] else {
			fatalError("FB_TEST_USERNAME is not defined")
		}
		
		return username
	}
	
	private var password: String {
		guard let password = ProcessInfo.processInfo.environment["FB_TEST_PASSWORD"] else {
			fatalError("FB_TEST_PASSWORD is not defined")
		}
		
		return password
	}
	
	private var database: String {
		guard let database = ProcessInfo.processInfo.environment["FB_TEST_DATABASE"] else {
			fatalError("FB_TEST_DATABASE is not defined")
		}
		
		return database
	}
	
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
		let conn = try self.connection.wait()
		XCTAssertTrue(conn.connection.isOpened)
		
		let futureResults = self.connection.flatMap { conn in
			conn.query("SELECT emp_no FROM employee")
		}
		
		XCTAssertNoThrow {
			let results = try futureResults.wait()
			XCTAssertGreaterThan(results.count, 0)
		}
	}
	
	func testQuery() throws {
		let rows = try self.connection.flatMap { conn in
			conn.query("SELECT emp_no FROM employee")
		}.wait()

		XCTAssertTrue(rows.count > 0)
	}
	
    static var allTests = [
        ("testConnection", testConnection),
		("testQuery", testQuery),
    ]
}
