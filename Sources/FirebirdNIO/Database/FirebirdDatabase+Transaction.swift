//
//  FirebirdDatabase+Transaction.swift
//  
//
//  Created by Ugo Cottin on 16/03/2021.
//

fileprivate struct teb {
	var dbHandle: UnsafePointer<isc_db_handle>
	var bufferLength: CLong
	var bufferHandle: UnsafePointer<ISC_SCHAR>
	
	internal init(dbHandle: UnsafePointer<isc_db_handle>, bufferLength: CLong, bufferHandle: UnsafePointer<ISC_SCHAR>) {
		self.dbHandle = dbHandle
		self.bufferLength = bufferLength
		self.bufferHandle = bufferHandle
	}
}

extension FirebirdDatabase {
	
	public var inTransaction: Bool {
		return self.transaction != nil
	}
	
	public func startTransaction(on connection: FirebirdConnection) -> Future<FirebirdTransaction> {
		
		var tebVector: [teb] = []
		var buffer = [ISC_SCHAR(isc_tpb_version3), ISC_SCHAR(isc_tpb_write)]
		
		var status = FirebirdError.statusArray
		var handle: isc_tr_handle = 0
		
		let block = teb(
			dbHandle: &connection.handle,
			bufferLength: buffer.count,
			bufferHandle: &buffer)
		tebVector.append(block)
		
		if isc_start_multiple(&status, &handle, 1, &tebVector) > 0 || handle <= 0 {
			return self.eventLoop.makeFailedFuture(FirebirdError(status))
		}
		
		return self.eventLoop.makeSucceededFuture(FirebirdTransaction(handle: handle))
	}
	
	public func commitTransaction(_ transaction: FirebirdTransaction) -> Future<Void> {
		var transaction = transaction
		var status = FirebirdError.statusArray
		
		if isc_commit_transaction(&status, &transaction.handle) > 0 {
			return self.eventLoop.makeFailedFuture(FirebirdError(status))
		}
		
		return self.eventLoop.makeSucceededVoidFuture()
	}
	
	public func rollbackTransaction(_ transaction: FirebirdTransaction) -> Future<Void> {
		var transaction = transaction
		var status = FirebirdError.statusArray
		
		if isc_rollback_transaction(&status, &transaction.handle) > 0 {
			return self.eventLoop.makeFailedFuture(FirebirdError(status))
		}
		
		return self.eventLoop.makeSucceededVoidFuture()
	}
	
	
	/// Execute the callback with a transaction.
	/// If a transaction is already started on this database, it will be used.
	/// Else, a new transaction will be created, used and commited to the database immediately
	/// - Parameter callback: a callback with a transaction
	/// - Returns: the result of the callback
	public func withTransaction<T>(on connection: FirebirdConnection, _ callback: @escaping (FirebirdTransaction) throws -> T) -> Future<T> {
		let transaction: Future<FirebirdTransaction>
		let isLocalTransaction: Bool
		if self.inTransaction {
			transaction = self.eventLoop.makeSucceededFuture(self.transaction!)
			isLocalTransaction = false
		} else {
			transaction = self.startTransaction(on: connection)
			isLocalTransaction = true
		}
		
		return transaction.flatMap { transaction in
			do {
				let result = try callback(transaction)
				
				if isLocalTransaction {
					return self.commitTransaction(transaction).map { result }
				}
				
				return self.eventLoop.makeSucceededFuture(result)
			} catch {
				return self.eventLoop.makeFailedFuture(error)
			}
		}
	}
}

