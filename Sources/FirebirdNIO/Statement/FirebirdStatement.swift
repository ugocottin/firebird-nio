//
//  FirebirdStatement.swift
//
//
//  Created by Ugo Cottin on 16/03/2021.
//

import Foundation

public struct FirebirdStatement {
	
	public static let DescriptorAreaVersion: Int16 = 1
	
	public var handle: isc_stmt_handle
	
	public let query: String
	
	public var cursor: Cursor?
	
	public init(_ query: String, handle: isc_db_handle = 0) {
		self.query = query
		self.handle = handle
		self.cursor = nil
	}
	
	public static func makeDescriptorArea(numberOfVariables: Int = 10) -> DescriptorArea {
		let pointer = UnsafeMutableRawPointer
			.allocate(byteCount: DescriptorArea.XSQLDA_LENGTH(numberOfVariables), alignment: 1)
			.assumingMemoryBound(to: XSQLDA.self)
		var descriptorArea = DescriptorArea(fromPointer: pointer)
		
		descriptorArea.version = Self.DescriptorAreaVersion
		descriptorArea.count = Int16(numberOfVariables)
		
		return descriptorArea
	}
}

public struct Cursor {
	
	public let name: String
	
}

extension FirebirdStatement: CustomStringConvertible {
	
	public var description: String {
		"Statement([\(self.query)][\(self.handle)])"
	}
	
}

public struct DescriptorVariable: CustomStringConvertible {
	
	let pointer: UnsafeMutablePointer<XSQLVAR>
	
	internal init(fromPointer pointer: UnsafeMutablePointer<XSQLVAR>) {
		self.pointer = pointer
	}
	
	public var type: FirebirdDataType {
		get {
			FirebirdDataType(rawValue: self.pointer.pointee.sqltype)!
		}
		set {
			self.pointer.pointee.sqltype = ISC_SHORT(newValue.rawValue)
		}
		
	}
	
	public var scale: Int16 {
		self.pointer.pointee.sqlscale
	}
	
	public var subtype: Int16 {
		self.pointer.pointee.sqlsubtype
	}
	
	public var size: Int {
		Int(self.pointer.pointee.sqllen)
	}
	
	public var nullable: Bool {
		(self.pointer.pointee.sqltype & 1) != 0
	}
	
	public var name: String {
		String(cString: &self.pointer.pointee.sqlname.0)
	}
	
	public var relation: String {
		String(cString: &self.pointer.pointee.relname.0)
	}
	
	public var owner: String {
		String(cString: &self.pointer.pointee.ownname.0)
	}
	
	public var alias: String {
		String(cString: &self.pointer.pointee.aliasname.0)
	}
	
	public var nullIndicatorPointer: UnsafeMutablePointer<ISC_SHORT> {
		get {
			self.pointer.pointee.sqlind
		}
		set {
			self.pointer.pointee.sqlind = newValue
		}
	}
	
	public var dataPointer: UnsafeMutablePointer<ISC_SCHAR> {
		get {
			self.pointer.pointee.sqldata
		}
		set {
			self.pointer.pointee.sqldata = newValue
		}
	}
	
	public var data: Data? {
		get {
			if self.nullable && self.pointer.pointee.sqlind.pointee < 0 {
				return nil
			}
			return Data(bytes: self.pointer.pointee.sqldata, count: Int(self.size))
		}
		set {
			if let newValue = newValue {
				self.pointer.pointee.sqlind.pointee = 0
				self.pointer.pointee.sqldata.withMemoryRebound(to: UInt8.self, capacity: Int(self.size)) { buffer in
					newValue.copyBytes(to: buffer, count: min(newValue.count, Int(self.size)))
				}
			} else {
				self.pointer.pointee.sqlind.pointee = -1
			}
		}
	}
	
	public var description: String {
		"\(self.name) [\(self.type) \(self.size) ± \(self.scale)]"
	}
}

public struct FirebirdStatementVariableAllocator {
	
	public func allocateMemory(for variable: inout DescriptorVariable) {
		if variable.nullable {
			variable.nullIndicatorPointer = self.allocateMemory(for: CShort.self, as: ISC_SHORT.self)
		}
		
		switch variable.type {
			case .text:
				variable.dataPointer = self.allocateMemory(for: CChar.self, capacity: variable.size, as: ISC_SCHAR.self)
			case .varying:
				variable.dataPointer = self.allocateMemory(for: CChar.self, capacity: variable.size + 2, as: ISC_SCHAR.self)
				variable.type = .text
			case .long, .d_float, .float:
				variable.dataPointer = self.allocateMemory(for: CLong.self, as: ISC_SCHAR.self)
			case .short:
				variable.dataPointer = self.allocateMemory(for: CShort.self, as: ISC_SCHAR.self)
			case .int64:
				variable.dataPointer = self.allocateMemory(for: Int64.self, as: ISC_SCHAR.self)
			case .timestamp, .time, .date:
				variable.dataPointer = self.allocateMemory(for: ISC_TIMESTAMP.self, as: ISC_SCHAR.self)
			default:
				fatalError("datatype unsupported")
		}
	}
	
	private func allocateMemory<T, S>(for type: T.Type, capacity: Int = 1, as: S.Type) -> UnsafeMutablePointer<S> {
		return UnsafeMutableRawPointer
			.allocate(byteCount: MemoryLayout<T>.stride * capacity, alignment: MemoryLayout<T>.alignment)
			.assumingMemoryBound(to: S.self)
	}
	
}
