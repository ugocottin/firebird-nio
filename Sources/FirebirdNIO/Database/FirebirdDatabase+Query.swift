//
//  FirebirdDatabase+Query.swift
//  
//
//  Created by Ugo Cottin on 16/03/2021.
//

extension FirebirdDatabase {
	
	public func query(_ string: String, _ binds: [FirebirdData] = []) -> Future<FirebirdQueryResult> {
		var rows: [FirebirdRow] = []
		var metadata: FirebirdQueryMetadata?

		return self.query(string, binds, onMetadata: { metadata = $0 }, onRow: { rows.append($0) })
			.map { FirebirdQueryResult(metadata: metadata!, rows: rows) }
	}
	
}

public struct FirebirdQueryResult {
	
	public let metadata: FirebirdQueryMetadata
	
	public let rows: [FirebirdRow]
	
}

public struct FirebirdQueryMetadata {
	
	public let query: String
	
}

public struct FirebirdRow {
	
	public let index: Int
	public let values: [String: FirebirdData]
	
}
