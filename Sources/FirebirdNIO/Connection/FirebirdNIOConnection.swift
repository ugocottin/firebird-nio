//
//  FirebirdNIOConnection.swift
//  
//
//  Created by Ugo Cottin on 24/03/2021.
//

import Firebird

/// Wrapper of blocking Firebird Connection
public class FirebirdNIOConnection {
	
	/// Event loop of the connection
	public let eventLoop: EventLoop
	
	/// Logger of the connection
	public let logger: Logger
	
	/// Underlying blocking Firebird connection
	public let connection: FirebirdConnection
	
	/// Create a non blocking Firebird connection based of an existing Firebird connection, on an event loop
	/// - Parameters:
	///   - connection: the Firebird (blocking) connection
	///   - eventLoop: the event loop of the connection
	///   - logger: the logger used to log informations
	public init(connection: FirebirdConnection, eventLoop: EventLoop, logger: Logger) {
		self.connection = connection
		self.eventLoop = eventLoop
		self.logger = logger
	}
	
	/// Close the connection
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
}


public extension FirebirdNIOConnection {
	
	/// Connect to a Firebird database server with given configuration
	/// - Parameters:
	///   - configuration: <#configuration description#>
	///   - logger: <#logger description#>
	///   - eventLoop: <#eventLoop description#>
	/// - Returns: <#description#>
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
	public func withTransaction<T>(_ closure: @escaping ((FirebirdNIOConnection) -> EventLoopFuture<T>)) -> EventLoopFuture<T> {
		do {
			return try self.connection.withTransaction {
				return closure(self)
			}
		} catch {
			return self.eventLoop.makeFailedFuture(error)
		}
	}
	
	public func withConnection<T>(_ closure: @escaping (FirebirdNIOConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
		return closure(self)
	}
	
	
	public func simpleQuery(_ query: String, _ binds: [FirebirdDataConvertible] = []) -> EventLoopFuture<Void> {
		let promise = self.eventLoop.makePromise(of: Void.self)
		
		do {
			try self.connection.simpleQuery(query, binds)
			promise.succeed(())
		} catch {
			promise.fail(error)
		}
		
		return promise.futureResult
	}
	
	public func query(_ query: String, _ binds: [FirebirdDataConvertible] = []) -> EventLoopFuture<[FirebirdRow]> {
		let promise = self.eventLoop.makePromise(of: [FirebirdRow].self)
		
		do {
			let rows = try self.connection.query(query, binds)
			promise.succeed(rows)
		} catch {
			promise.fail(error)
		}
		
		return promise.futureResult
	}
	
	public func query(_ query: String, _ binds: [FirebirdDataConvertible] = [], onRow: @escaping (FirebirdRow) throws -> Void) -> EventLoopFuture<Void> {
		let promise = eventLoop.makePromise(of: Void.self)
	
		do {
			try self.connection.query(query, binds, onRow: onRow)
			promise.succeed(())
		} catch {
			promise.fail(error)
		}

		return promise.futureResult
	}
}
