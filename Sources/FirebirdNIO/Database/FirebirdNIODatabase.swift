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
	func simpleQuery(_ query: String, _ binds: [FirebirdData]) -> EventLoopFuture<Void>
	
	/// Perform a query that return datas
	/// - Parameters:
	///   - query: a query string
	///   - binds: query parameters
	/// - Returns: the result rows
	func query(_ query: String, _ binds: [FirebirdData]) -> EventLoopFuture<[FirebirdRow]>

	func query(_ query: String, _ binds: [FirebirdData], onRow: @escaping (FirebirdRow) throws -> Void) -> EventLoopFuture<Void>
	
	func withTransaction<T>(_ closure: @escaping((FirebirdNIOConnection) -> EventLoopFuture<T>)) -> EventLoopFuture<T>
}
