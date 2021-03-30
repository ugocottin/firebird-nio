//
//  FirebirdNIOConnection.swift
//  
//
//  Created by Ugo Cottin on 24/03/2021.
//

//
//  FirebirdConnection.swift
//
//
//  Created by Ugo Cottin on 15/03/2021.
//

public class FirebirdNIOConnection {
	
	public let eventLoop: EventLoop
	
	public let connection: FirebirdConnection
	
	public init(connection: FirebirdConnection, eventLoop: EventLoop, logger: Logger) {
		self.connection = connection
		self.eventLoop = eventLoop
	}
}

extension FirebirdNIOConnection: ConnectionPoolItem {
	public func close() -> EventLoopFuture<Void> {
		let promise = self.eventLoop.makePromise(of: Void.self)
		do {
			try self.connection.close()
			promise.succeed(())
		} catch {
			promise.fail(error)
		}
		
		return promise.futureResult
	}
	
	public var isClosed: Bool {
		!self.connection.isOpened
	}
}


public extension FirebirdNIOConnection {
	
	static func connect(
		_ configuration: FirebirdConnectionConfiguration,
		logger: Logger = Logger(label: "logging.firebird"),
		on eventLoop: EventLoop) -> EventLoopFuture<FirebirdNIOConnection> {
		
		let promise = eventLoop.makePromise(of: FirebirdNIOConnection.self)
		
		do {
			let connection = try FirebirdConnection.connect(configuration, logger: logger)
			promise.succeed(
				FirebirdNIOConnection(
					connection: connection,
					eventLoop: eventLoop,
					logger: logger))
		} catch {
			promise.fail(error)
		}
		
		return promise.futureResult
	}
	
}

extension FirebirdNIOConnection: FirebirdNIODatabase {
	
	public func withConnection<T>(_ closure: @escaping (FirebirdNIOConnection) throws -> T) rethrows -> T {
		try closure(self)
	}
	
	public func query(_ query: String, _ binds: [FirebirdData], onRow: @escaping (FirebirdRow) throws -> Void) -> EventLoopFuture<Void> {
		let promise = self.eventLoop.makePromise(of: Void.self)
		
		do {
			try self.connection.query(query, binds, onRow: onRow)
			promise.succeed(())
		} catch {
			promise.fail(error)
		}
		
		return promise.futureResult
	}
	
	public var logger: Logger {
		self.connection.logger
	}
	
	public func simpleQuery(_ query: String, _ binds: [FirebirdData]) -> EventLoopFuture<Void> {
		let promise = self.eventLoop.makePromise(of: Void.self)
		
		do {
			try self.connection.simpleQuery(query, binds)
			promise.succeed(())
		} catch {
			promise.fail(error)
		}
		
		return promise.futureResult
		
	}
	
}
