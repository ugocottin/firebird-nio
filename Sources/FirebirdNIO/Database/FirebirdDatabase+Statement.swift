//
//  FirebirdDatabase+Statement.swift
//  
//
//  Created by Ugo Cottin on 16/03/2021.
//

extension FirebirdDatabase {
	
	public static var dialect: UInt16 {
		3
	}

	public func allocate(_ statement: FirebirdStatement, on connection: FirebirdConnection) -> Future<FirebirdStatement> {
				
		var status = FirebirdError.statusArray
		var statement = statement
		
		if isc_dsql_allocate_statement(&status, &connection.handle, &statement.handle) > 0 {
			return self.eventLoop.makeFailedFuture(FirebirdError(status))
		}
		
		return self.eventLoop.makeSucceededFuture(statement)
	}
	
	public func prepare(_ query: String, on statement: FirebirdStatement, _ transaction: FirebirdTransaction, dialectVersion: UInt16 = Self.dialect) -> Future<FirebirdStatement> {
		
		var status = FirebirdError.statusArray
		var statement = statement
		var transaction = transaction
		
		if isc_dsql_prepare(&status, &transaction.handle, &statement.handle, 0, query, dialectVersion, nil) > 0 {
			return self.eventLoop.makeFailedFuture(FirebirdError(status))
		}
		
		return self.eventLoop.makeSucceededFuture(statement)
	}
	
	public func describeOutput(of statement: FirebirdStatement, _ size: Int16 = 10) -> Future<DescriptorArea> {
		
		var status = FirebirdError.statusArray
		var statement = statement
		
		let xsqlda = UnsafeMutableRawPointer
			.allocate(byteCount: DescriptorArea.XSQLDA_LENGTH(Int(size)), alignment: 1)
			.assumingMemoryBound(to: XSQLDA.self)

		var descriptorArea = DescriptorArea(fromPointer: xsqlda)
		descriptorArea.version = Int16(DescriptorArea.descriptorVersion)
		descriptorArea.count = size
		
		if isc_dsql_describe(&status, &statement.handle, DescriptorArea.descriptorVersion, descriptorArea.pointer) > 0 {
			return self.eventLoop.makeFailedFuture(FirebirdError(status))
		}
		
		if descriptorArea.requiredCount > descriptorArea.count {
			let size = descriptorArea.requiredCount
			descriptorArea.free()
			return describeOutput(of: statement, size)
		}
		
		let allocator = FirebirdStatementVariableAllocator()
		for (index, var variable) in descriptorArea.variables.enumerated() {
			allocator.allocateMemory(for: &variable)
			descriptorArea[index] = variable
		}
		
		return self.eventLoop.makeSucceededFuture(descriptorArea)
	}
	
	public func execute(_ statement: FirebirdStatement, with transaction: FirebirdTransaction) throws -> Future<Void> {
		var status = FirebirdError.statusArray
		var statement = statement
		var transaction = transaction

		if isc_dsql_execute(&status, &transaction.handle, &statement.handle, DescriptorArea.descriptorVersion, nil) > 0 {
			throw FirebirdError(status)
		}
		
		return self.eventLoop.makeSucceededVoidFuture()
	}
}
