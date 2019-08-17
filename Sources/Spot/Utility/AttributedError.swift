//
//  AttributedError.swift
//  Spot
//
//  Created by Shawn Clovie on 6/10/2018.
//  Copyright © 2018 Shawn Clovie. All rights reserved.
//

public typealias AttributedResult<T> = Result<T, AttributedError>

public struct AttributedError: Error, ErrorConvertable, LocalizedDescriptable {
	public static let localizableTable = "ErrorLocalizable"
	
	public struct Source: Equatable {
		
		public static func ==(l: Source, r: Source) -> Bool {
			l.name == r.name
		}
		
		public let name: String
		
		public init(_ name: String) {
			self.name = name
		}
	}
	
	public let source: Source
	public let object: Any?
	public let userInfo: [AnyHashable: Any]
	public let original: Error?
	
	public init(with err: Error) {
		self.init(with: err, (err as? AttributedError)?.source ?? .unknown)
	}
	
	public init(with err: Error, _ source: Source) {
		if let err = err as? AttributedError {
			self.init(source, object: err.object, original: err.original, userInfo: err.userInfo)
		} else {
			self.init(source, original: err)
		}
	}
	
	public init(_ source: Source, object: Any? = nil, original: Error? = nil, userInfo: [AnyHashable: Any] = [:]) {
		self.source = source
		self.object = object
		self.original = original
		self.userInfo = userInfo
	}
	
	public var localizedKey: String {
		if let ori = original as? AttributedError {
			return source.name + "." + ori.localizedKey
		}
		return source.name
	}
	
	public var localizedDescription: String {
		let result = localizedKey.spot.localize(table: Self.localizableTable)
		if let oriDesc = original?.spot_localizedDescription,
			!oriDesc.isEmpty {
			return "\(result) (\(oriDesc))"
		}
		return result
	}
}

extension AttributedError: CustomStringConvertible, CustomDebugStringConvertible {
	public var description: String {
		source.name
	}
	
	public var debugDescription: String {
		var text = "\(type(of: self))(\(source.name)"
		if let obj = object {
			text += ",object="
			text += String(reflecting: obj)
		}
		if let ori = original {
			text += ",original="
			text += String(reflecting: ori)
		}
		if !userInfo.isEmpty {
			text += ",userInfo="
			text += String(reflecting: userInfo)
		}
		text += ")"
		return text
	}
}

extension AttributedError.Source {
	
	// MARK: General
	
	public static let unknown = AttributedError.Source("unknown")
	public static let cancelled = AttributedError.Source("cancelled")
	public static let timeout = AttributedError.Source("timeout")
	public static let itemNotFound = AttributedError.Source("itemNotFound")
	public static let invalidFormat = AttributedError.Source("invalidFormat")
	public static let invalidStatus = AttributedError.Source("invalidStatus")
	public static let invalidArgument = AttributedError.Source("invalidArgument")
	public static let privilegeLimited = AttributedError.Source("privilegeLimited")
	public static let duplicateOperation = AttributedError.Source("duplicateOperation")
	public static let operationFailed = AttributedError.Source("operationFailed")
	
	// MARK: IO
	
	public static let fileNotFound = AttributedError.Source("fileNotFound")
	public static let fileNotReadable = AttributedError.Source("fileNotReadable")
	public static let fileNotWritable = AttributedError.Source("fileNotWritable")
	public static let fileDidExists = AttributedError.Source("fileDidExists")
	public static let io = AttributedError.Source("io")
	
	// MARK: Network
	
	public static let network = AttributedError.Source("network")
	public static let server = AttributedError.Source("server")
	public static let serviceMissing = AttributedError.Source("serviceMissing")
}
