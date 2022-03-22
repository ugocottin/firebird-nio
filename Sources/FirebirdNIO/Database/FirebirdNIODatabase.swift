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
	
	func withConnection<T>(_ closure: @escaping (FirebirdNIOConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T>
	
	/// Perform a query that dont return data
	/// - Parameters:
	///   - query: a query string
	///   - binds: query parameters
	func simpleQuery(_ query: String, _ binds: [FirebirdDataConvertible]) -> EventLoopFuture<Void>
	
	/// Perform a query that return datas
	/// - Parameters:
	///   - query: a query string
	///   - binds: query parameters
	/// - Returns: the result rows
	func query(_ query: String, _ binds: [FirebirdDataConvertible]) -> EventLoopFuture<[FirebirdRow]>
	
	/// Ferform a query that return data on a callback
	/// - Parameters:
	///   - query: a query string
	///   - binds: query parameters
	///   - onRow: a callback called each time a row is fetched
	func query(_ query: String, _ binds: [FirebirdDataConvertible], onRow: @escaping (FirebirdRow) throws -> Void) -> EventLoopFuture<Void>
	
	
	/// Execute the callback with a transaction. If something went wrong on the callback, the transaction is rolled back, else the transaction is commited
	/// - Parameter closure: a closure on the connection
	func withTransaction<T>(_ closure: @escaping((FirebirdNIOConnection) -> EventLoopFuture<T>)) -> EventLoopFuture<T>
}
