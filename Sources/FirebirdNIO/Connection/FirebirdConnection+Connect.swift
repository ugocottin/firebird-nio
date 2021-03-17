//
//  FirebirdConnection+Connect.swift
//  
//
//  Created by Ugo Cottin on 16/03/2021.
//

extension FirebirdConnection {
	
	public static func connect(to host: FirebirdDatabaseHost, username: String, password: String, database: String, logger: Logger = .init(label: "firebird"), on eventLoop: EventLoop) -> EventLoopFuture<FirebirdConnection> {
		self.connect(FirebirdDatabaseConfiguration(
						host: host,
						username: username,
						password: password,
						database: database)
					 ,logger: logger,
					 on: eventLoop)
	}
	
	public static func connect(_ configuration: FirebirdDatabaseConfiguration, logger: Logger = .init(label: "firebird"), on eventLoop: EventLoop) -> Future<FirebirdConnection> {
		
		guard let database = configuration.databaseURL.cString(using: .utf8) else {
			return eventLoop.makeFailedFuture("invalid database url format, '\(configuration.databaseURL)' should be an utf8 string")
		}
		
		let dpb = self.populateDatabaseParameterBuffer(configuration)
		
		var status = FirebirdError.statusArray
		var handle: isc_db_handle = 0
		
		if isc_attach_database(&status, 0, database, &handle, Int16(dpb.count), dpb) > 0 {
			return eventLoop.makeFailedFuture(FirebirdError(status))
		}
		
		return eventLoop.makeSucceededFuture(FirebirdConnection(handle: handle, eventLoop: eventLoop, logger: logger))
	}
	
	private static func populateDatabaseParameterBuffer(_ configuration: FirebirdDatabaseConfiguration) -> [ISC_SCHAR] {
		var dpb: [ISC_SCHAR] = []
		dpb.append(ISC_SCHAR(isc_dpb_version1))
		
		dpb.append(ISC_SCHAR(isc_dpb_user_name))
		var username = configuration.username.utf8CString
		
		if let last = username.last, last == 0 {
			username.removeLast()
		}
		
		dpb.append(ISC_SCHAR(username.count))
		dpb.append(contentsOf: username)
		
		dpb.append(ISC_SCHAR(isc_dpb_password))
		var password = configuration.password.utf8CString
		
		if let last = password.last, last == 0 {
			password.removeLast()
		}
		
		dpb.append(ISC_SCHAR(password.count))
		dpb.append(contentsOf: password)
		
		return dpb
	}
	
}

extension String: Error {
	
}
