//
//  FirebirdTransaction.swift
//  
//
//  Created by Ugo Cottin on 16/03/2021.
//

public struct FirebirdTransaction {
	
	var handle: isc_tr_handle
	
	internal init(handle: isc_db_handle = 0) {
		self.handle = handle
	}
}


extension FirebirdTransaction: CustomStringConvertible {
	
	public var description: String {
		"Transaction(\(self.handle))"
	}
	
}
