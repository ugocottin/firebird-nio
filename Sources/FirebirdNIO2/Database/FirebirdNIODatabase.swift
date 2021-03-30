//
//  FirebirdNIODatabase.swift
//  
//
//  Created by Ugo Cottin on 30/03/2021.
//

public protocol FirebirdNIODatabase {
	
	/// The database logger
	var logger: Logger { get }
	
	var eventLoop: EventLoop { get }
	
	/// Perform a query that dont return data
	/// - Parameters:
	///   - query: a query string
	///   - binds: query parameters
	func simpleQuery(_ query: String, _ binds: [FirebirdData]) -> EventLoopFuture<Void>
	
	/// Perform a query that return datas
	/// - Parameters:
	///   - query: a query string
	///   - binds: query parameters
	/// - Returns: the result rows
	func query(_ query: String, _ binds: [FirebirdData]) -> EventLoopFuture<[FirebirdRow]>
	
	func query(_ query: String, _ binds: [FirebirdData], onRow: @escaping (FirebirdRow) throws -> Void) -> EventLoopFuture<Void>
	
	func withConnection<T>(_ closure: @escaping (FirebirdNIOConnection) throws -> T) rethrows -> T
	
}

public extension FirebirdNIODatabase {
			
	func query(_ query: String, _ binds: [FirebirdData] = []) -> EventLoopFuture<[FirebirdRow]> {
		let promise = eventLoop.makePromise(of: [FirebirdRow].self)
		var rows: [FirebirdRow] = []
		return self.query(query, binds, onRow: { rows.append($0) }).flatMap {_ in
			promise.succeed(rows)
			return promise.futureResult
		}
	}
	
}
