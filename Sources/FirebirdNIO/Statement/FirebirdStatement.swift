//
//  FirebirdStatement.swift
//
//
//  Created by Ugo Cottin on 16/03/2021.
//

import CFirebird
import Foundation

public struct FirebirdStatement {
	
	public static let DescriptorAreaVersion: Int16 = 1
	
	public var handle: isc_stmt_handle
	
	public let query: String
	
	public init(_ query: String, handle: isc_db_handle = 0) {
		self.query = query
		self.handle = handle
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

public struct DescriptorArea {
	
	/// Return the required size for storing `size` columns descriptors
	/// - Parameter size: number of columns descriptors needed
	/// - Returns: the memory space for storing the descriptors
	public static func XSQLDA_LENGTH(_ size: Int) -> Int {
		MemoryLayout<XSQLDA>.size + (size - 1) * MemoryLayout<XSQLVAR>.size
	}
	
	// Mark: Variables
	internal let pointer: UnsafeMutablePointer<XSQLDA>
	
	// Mark: Computed variables
	
	/// Indicate the version of the descriptor structure (see "XSQLDA structure version")
	public var version: Int16 {
		get {
			return self.pointer.pointee.version
		}
		set {
			self.pointer.pointee.version = newValue
		}
	}
	
	public var count: Int16 {
		get {
			self.pointer.pointee.sqln
		}
		set {
			self.pointer.pointee.sqln = newValue
		}
	}
	
	public var requiredCount: Int16 {
		self.pointer.pointee.sqld
	}
	
	/// Array of XSQLVAR structures.
	/// Theses structures are a copy of the structures contained in the
	public var variables: Array<DescriptorVariable> {
		return withUnsafeMutablePointer(to: &self.pointer.pointee.sqlvar) { varPtr in
			var array: Array<DescriptorVariable> = []
			for index in 0 ..< Int(min(self.count, self.requiredCount)) {
				array.append(DescriptorVariable(fromPointer: varPtr.advanced(by: index)))
			}
			
			return array
		}
	}
	
	// Mark: Init
	internal init(fromPointer pointer: UnsafeMutablePointer<XSQLDA>) {
		self.pointer = pointer
	}
	
	// Mark: subscript
	subscript(index: Int) -> DescriptorVariable {
		get {
			self.variables[index]
		}
		set {
			withUnsafeMutablePointer(to: &self.pointer.pointee.sqlvar) { varPtr in
				varPtr.advanced(by: index).pointee = newValue.pointer.pointee
			}
		}
	}
	
	// Mark: functions
	public func free() {
		self.pointer.deallocate()
	}
}

extension DescriptorArea: CustomStringConvertible {
	public var description: String {
		"""
Descriptor v\(self.version), area of \(self.count) variables, required \(self.requiredCount):
\(self.variables.map { "\t- " + $0.description }.joined(separator: "\n"))
"""
	}
}

extension FirebirdStatement: CustomStringConvertible {
	
	public var description: String {
		"Statement([\(self.query)][\(self.handle)])"
	}
	
}

public struct DescriptorVariable: CustomStringConvertible {
	
	fileprivate let pointer: UnsafeMutablePointer<XSQLVAR>
	
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
