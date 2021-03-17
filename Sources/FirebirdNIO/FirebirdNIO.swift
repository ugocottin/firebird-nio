//
//  FirebirdNIO.swift
//  
//
//  Created by Ugo Cottin on 15/03/2021.
//

public typealias Future<T> = EventLoopFuture<T>
public typealias Promise<T> = EventLoopPromise<T>

func withStatus(_ closure: (inout Array<ISC_STATUS>) throws -> ()) rethrows {
	var array: Array<ISC_STATUS> = Array(repeating: 0, count: Int(ISC_STATUS_LENGTH))
	try closure(&array)
}
