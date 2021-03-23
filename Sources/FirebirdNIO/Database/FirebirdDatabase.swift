//
//  FirebirdDatabase.swift
//  
//
//  Created by Ugo Cottin on 16/03/2021.
//

public protocol FirebirdDatabase {
	
	/// Logger of the database
	var logger: Logger { get }
	
	/// Eventloop of the database
	var eventLoop: EventLoop { get }
	
	var transaction: FirebirdTransaction? { get }
	
	func withConnection<T>(_ closure: @escaping (FirebirdConnection) -> Future<T>) -> Future<T>
	
	func query(
	_ string: String,
	_ binds: [FirebirdData],
	onMetadata: @escaping (FirebirdQueryMetadata) -> Void,
	onRow: @escaping (FirebirdRow) throws -> Void) -> Future<Void>
}
