//
//  DescriptorArea.swift
//  
//
//  Created by Ugo Cottin on 23/03/2021.
//

/// Wrapper of the `XSQLDA` structure from Firebird.
/// This structure is used to transport data from and to the database, via input descriptor area and output
/// descriptor area.
public struct DescriptorArea {
	
	public static var descriptorVersion: UInt16 = 1
	
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
	
	/// Number of variables descriptor contained in the area
	public var count: Int16 {
		get {
			self.pointer.pointee.sqln
		}
		set {
			self.pointer.pointee.sqln = newValue
		}
	}
	
	/// Required variables descriptor for the described statement
	public var requiredCount: Int16 {
		self.pointer.pointee.sqld
	}
	
	/// Array of XSQLVAR structures.
	public var variables: Array<DescriptorVariable> {
		return withUnsafeMutablePointer(to: &self.pointer.pointee.sqlvar) { varPtr in
			var array: Array<DescriptorVariable> = []
			for index in 0 ..< Int(min(self.count, self.requiredCount)) {
				array.append(DescriptorVariable(fromPointer: varPtr.advanced(by: index)))
			}
			
			return array
		}
	}
	
	/// Create a descriptor area based of the underlying `XSQLDA` structure
	/// - Parameter pointer: a pointer to a `XSQLDA` structure
	internal init(fromPointer pointer: UnsafeMutablePointer<XSQLDA>) {
		self.pointer = pointer
	}
	
	/// Get a descriptor variable contained in this area, based on this index
	/// - Parameter index: index of the variable
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
	
	/// Free the `XSQLDA` structure referenced by the pointer
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
