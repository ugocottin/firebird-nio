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
			
		let inputDescriptorArea = statement.flatMap { self.describeInput(of: $0) }.map { ida -> DescriptorArea in
			for (index, var variable) in ida.variables.enumerated() {
				let bind = binds[index]
				variable.data = bind.value
				
				if (bind.value == nil) {
					variable.nullIndicatorPointer.pointee = 1
				}
			}
			
			return ida
		}
		let descriptorArea = statement
			.flatMap { self.describeOutput(of: $0) }
		
		let executedStatement = transaction.and(statement).and(inputDescriptorArea).flatMapThrowing { varArg -> Future<Void> in
			let ((transaction, statement), ida) = varArg
			return try self.execute(statement, with: transaction, ida)
		}
		
		let statementWithCursor = executedStatement.and(statement).flatMapThrowing { _, statement in
			return try self.openCursor(on: statement)
		}
		
		let fetchedStatement = statementWithCursor.and(descriptorArea).flatMapThrowing { statement, descriptorArea -> Void in
			var statement = statement
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
		
		
		return fetchedStatement.and(inputDescriptorArea).map { _, ida in
			for variable in ida.variables {
				variable.nullIndicatorPointer.deallocate()
				variable.dataPointer.deallocate()
			}
		}.and(descriptorArea).map { _, oda in
			for variable in oda.variables {
				variable.nullIndicatorPointer.deallocate()
				variable.dataPointer.deallocate()
			}
		}
	}
	

	public func withConnection<T>(_ closure: @escaping (FirebirdConnection) -> Future<T>) -> Future<T> {
		return closure(self)
	}
}
