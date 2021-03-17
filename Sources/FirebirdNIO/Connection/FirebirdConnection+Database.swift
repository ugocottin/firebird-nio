//
//  FirebirdConnection+Database.swift
//  
//
//  Created by Ugo Cottin on 16/03/2021.
//

extension FirebirdConnection: FirebirdDatabase {
	
	public func query(_ string: String, _ binds: [FirebirdData], onMetadata: @escaping (FirebirdQueryMetadata) -> Void, onRow: @escaping (FirebirdRow) throws -> Void) -> Future<Void> {
		
		let transaction: Future<FirebirdTransaction>
		if self.transaction != nil {
			transaction = self.eventLoop.makeSucceededFuture(self.transaction!)
		} else {
			transaction = self.startTransaction(on: self)
		}
		
		let statement = transaction.flatMap { transaction in
			self.allocate(FirebirdStatement(string), on: self)
		}
		
		return self.eventLoop.makeSucceededVoidFuture()
	}
	

	public func withConnection<T>(_ closure: @escaping (FirebirdConnection) -> Future<T>) -> Future<T> {
		return closure(self)
	}
}
