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
		
		onMetadata(FirebirdQueryMetadata(query: string))
		
		let statement = transaction
			.flatMap { _ in self.allocate(FirebirdStatement(string), on: self) }
			.and(transaction).flatMap { self.prepare(string, on: $0, $1) }
			
		let descriptorArea = statement
			.flatMap { self.describeOutput(of: $0) }
		
		let executedStatement = transaction.and(statement).flatMapThrowing { transaction, statement -> Future<Void> in
			return try self.execute(statement, with: transaction)
		}
		
		let openCursor = executedStatement.and(statement).flatMapThrowing { _, statement -> Void in
			
			var status = FirebirdError.statusArray
			var statement = statement
			if isc_dsql_set_cursor_name(&status, &statement.handle, "dyn_cursor", .zero) > 0 {
				throw FirebirdError(status)
			}
		}
		
		return openCursor.and(statement).and(descriptorArea).flatMapThrowing { varArg -> Void in
			var ((_, statement), descriptorArea) = varArg
			var status = FirebirdError.statusArray
			
			var index = 0
			
			while case let fetchStatus = isc_dsql_fetch(&status, &statement.handle, Self.dialect, descriptorArea.pointer), fetchStatus == 0 {
				var values: Dictionary<String, FirebirdData> = Dictionary()
				for variable in descriptorArea.variables {
					let data = FirebirdData(type: variable.type, value: variable.data)
					values[variable.name] = data
				}
				
				let row = FirebirdRow(index: index, values: values)
				try onRow(row)
				index += 1
			}
		}
	}
	

	public func withConnection<T>(_ closure: @escaping (FirebirdConnection) -> Future<T>) -> Future<T> {
		return closure(self)
	}
}
