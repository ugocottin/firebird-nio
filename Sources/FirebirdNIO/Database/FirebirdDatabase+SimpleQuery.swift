//
//  FirebirdDatabase+SimpleQuery.swift
//  
//
//  Created by Ugo Cottin on 23/03/2021.
//

public extension FirebirdDatabase {
	
	func simpleQuery(_ query: String) -> Future<Void> {
		self.withConnection { connection in
			self.withTransaction(on: connection) { transaction in
				var status = FirebirdError.statusArray
				var transaction = transaction
				if isc_dsql_execute_immediate(&status, &connection.handle, &transaction.handle, 0, query, 1, nil) > 0 {
					let error = FirebirdError(status)
					self.logger.error("\(error.description)")
					throw error
				}
			}
		}
	}
	
}
