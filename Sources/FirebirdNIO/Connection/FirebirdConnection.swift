//
//  FirebirdConnection.swift
//  
//
//  Created by Ugo Cottin on 15/03/2021.
//

public class FirebirdConnection {
	
	public var eventLoop: EventLoop
	
	public var handle: isc_db_handle
	
	public var logger: Logger
	
	public var transaction: FirebirdTransaction? = nil
	
	public init(handle: isc_db_handle, eventLoop: EventLoop, logger: Logger) {
		self.handle = handle
		self.eventLoop = eventLoop
		self.logger = logger
	}
}

extension FirebirdConnection: ConnectionPoolItem {
	public func close() -> EventLoopFuture<Void> {
		self.logger.trace("closing connection with handle \(self.handle)")
		guard !self.isClosed else {
			self.logger.info("connection already closed")
			return self.eventLoop.makeSucceededVoidFuture()
		}
		
		var status = FirebirdError.statusArray
		
		if isc_detach_database(&status, &self.handle) > 0 {
			self.logger.error("unable to close connection with handle \(self.handle)")
			return self.eventLoop.makeFailedFuture(FirebirdError(status))
		}
		
		self.logger.info("connection closed")
		return self.eventLoop.makeSucceededVoidFuture()
	}
	
	public var isClosed: Bool {
		!(self.handle > 0)
	}
}
