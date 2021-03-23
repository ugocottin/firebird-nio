//
//  Exports.swift
//  
//
//  Created by Ugo Cottin on 16/03/2021.
//

@_exported import Firebird
@_exported import Logging
@_exported import AsyncKit

public extension String {
	
	static func randomString(length: Int) -> String {
		let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		return String((0..<length).map{ _ in letters.randomElement()! })
	}
	
}
