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
	
}

