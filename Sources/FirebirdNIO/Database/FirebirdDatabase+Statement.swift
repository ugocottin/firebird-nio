//
//  FirebirdDatabase+Statement.swift
//  
//
//  Created by Ugo Cottin on 16/03/2021.
//

extension FirebirdDatabase {
	
	public func allocate(_ statement: FirebirdStatement, on connection: FirebirdConnection) -> Future<FirebirdStatement> {
				
		var status = FirebirdError.statusArray
		var statement = statement
		
		if isc_dsql_allocate_statement(&status, &connection.handle, &statement.handle) > 0 {
			return self.eventLoop.makeFailedFuture(FirebirdError(status))
		}
		
		return self.eventLoop.makeSucceededFuture(statement)
	}
	
}
