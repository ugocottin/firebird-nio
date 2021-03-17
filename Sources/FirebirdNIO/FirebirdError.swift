//
//  FirebirdError.swift
//  
//
//  Created by Ugo Cottin on 15/03/2021.
//

public class FirebirdError: Error {
	
	public static var statusArray: Array<ISC_STATUS> {
		Array(repeating: 0, count: Int(ISC_STATUS_LENGTH))
	}
	
	public var statusArray: Array<ISC_STATUS>
	
	public init(_ array: Array<Int>) {
		self.statusArray = array
	}
}

extension FirebirdError: CustomStringConvertible {
	
	public var bufferSize: Int {
		256
	}
	
	public var description: String {
		let errorCode = isc_sqlcode(&self.statusArray)
		var buffer: Array<Int8> = Array<Int8>(repeating: 0, count: self.bufferSize)
		isc_sql_interprete(Int16(errorCode), &buffer, Int16(self.bufferSize))
		
		return "FirebirdError: " + (String(cString: buffer, encoding: .utf8) ?? "error code \(errorCode)")
	}
	
}

