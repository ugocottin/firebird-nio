//
//  FirebirdNIOConnection.swift
//  
//
//  Created by Ugo Cottin on 24/03/2021.
//

import Firebird
import AsyncKit

public class FirebirdNIOConnection {
		
	public let eventLoop: EventLoop
	
	public let connection: FirebirdConnection
	
	public init(_ connection: FirebirdConnection, on eventLoop: EventLoop) {
		self.connection = connection
		self.eventLoop = eventLoop
	}
	
	public static func connect(_ configuration: FirebirdConnectionConfiguration, logger: Logger = Logger(label: "logging.nio.firebird"), on eventLoop: EventLoop) throws -> EventLoopFuture<FirebirdNIOConnection> {
		return eventLoop.submit {
			let connection = try FirebirdConnection.connect(configuration, logger: logger)
			return FirebirdNIOConnection(connection, on: eventLoop)
		}
		
	}
}
