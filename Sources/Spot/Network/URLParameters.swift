//
//  URLParameters.swift
//  Spot
//
//  Created by Shawn Clovie on 18/2/2018.
//  Copyright © 2018 Shawn Clovie. All rights reserved.
//

public struct URLParameters {
	
	public var headers: [String: String]
	private var values: [[Any]] = []
	/// [key: values index]
	private var keys: [String: Int] = [:]
	
	public init(_ params: [String: Any] = [:], headers: [String: String] = [:]) {
		self.headers = headers
		for it in params {
			append(it.key, it.value)
		}
	}
	
	/// Access first value for key
	public subscript(key: String) -> Any? {
		get {
			values(key: key)?.first
		}
		set {
			if let newValue = newValue {
				set(key, as: [newValue])
			} else {
				removeValues(key: key)
			}
		}
	}
	
	public func values(key: String) -> [Any]? {
		guard let i = keys[key] else {return nil}
		return values[i]
	}
	
	public var keyValuePairs: URLKeyValuePairs {
		var pairs: URLKeyValuePairs = []
		pairs.reserveCapacity(values.count)
		for it in keys.sorted(by: { (l, r) in l.key < r.key}) {
			for value in values[it.value] {
				pairs.append((it.key, value))
			}
		}
		return pairs
	}
	
	public var encodedDictionary: [String: Any] {
		var dict: [String: Any] = [:]
		dict.reserveCapacity(values.count)
		for it in keys {
			let vs = values[it.value]
			switch vs.count {
			case 1:		dict[it.key] = vs[0]
			case 0:		break
			default:	dict[it.key] = vs
			}
		}
		return dict
	}
	
	public mutating func append(_ key: String, _ value: Any) {
		if let i = keys[key] {
			values[i].append(value)
		} else {
			appendNew(key, [value])
		}
	}
	
	public mutating func append(_ other: URLParameters, allowRepeatKey: Bool = false) {
		for it in other.headers {
			headers[it.key] = it.value
		}
		for (key, i) in other.keys {
			let newValues = other.values[i]
			guard !newValues.isEmpty else {continue}
			if let i = keys[key] {
				if allowRepeatKey {
					values[i].append(contentsOf: newValues)
				} else {
					values[i] = newValues
				}
			} else {
				appendNew(key, newValues)
			}
		}
	}
	
	private mutating func appendNew(_ key: String, _ value: [Any]) {
		keys[key] = values.count
		values.append(value)
	}
	
	public mutating func set(_ key: String, as values: [Any]) {
		if let i = keys[key] {
			self.values[i] = values
		} else {
			appendNew(key, values)
		}
	}
	
	/// Remove all values for key
	///
	/// - Returns: Removed values
	@discardableResult
	public mutating func removeValues(key: String) -> [Any]? {
		guard let i = keys.removeValue(forKey: key) else {return nil}
		return values.remove(at: i)
	}
	
	public var contentType: String? {
		get {headers[URLTask.contentTypeKey]}
		set {
			if let v = newValue {
				headers[URLTask.contentTypeKey] = v
			} else {
				headers.removeValue(forKey: URLTask.contentTypeKey)
			}
		}
	}
}
