//
//  FirebirdConnectionSource.swift
//  
//
//  Created by Ugo Cottin on 15/03/2021.
//

public struct FirebirdConnectionSource: ConnectionPoolSource {
	
	public typealias Connection = FirebirdConnection
	
	public let configuration: FirebirdDatabaseConfiguration
	
	public init(_ configuration: FirebirdDatabaseConfiguration) {
		self.configuration = configuration
	}
	
	public func makeConnection(logger: Logger, on eventLoop: EventLoop) -> EventLoopFuture<FirebirdConnection> {
		return FirebirdConnection.connect(self.configuration, logger: logger, on: eventLoop)
	}
	
}
