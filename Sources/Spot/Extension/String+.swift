//
//  String+.swift
//  Spot
//
//  Created by Shawn Clovie on 5/10/16.
//  Copyright © 2016 Shawn Clovie. All rights reserved.
//

import Foundation

private let htmlSpecialCharacters: [Character: String] = [
	"<": "&lt;", ">": "&gt;",
	"&": "&amp;", "'": "&apos;", "\"": "&quot;"
]

extension String: SuffixProtocol {
	
	/// Convert parameters dictionary to query string.
	///
	/// - Parameters:
	///   - parameters: Parameters
	///   - encode: If encode parameters
	/// - Returns: Query string with encoded if needed
	public static func spot(queryString parameters: URLKeyValuePairs, encode: Bool = true) -> String {
		let allowedChars: CharacterSet = encode ? .urlQueryAllowed : .whitespaces
		var query: [String] = []
		for (key, value) in parameters {
			guard let key = key.addingPercentEncoding(withAllowedCharacters: allowedChars) else {
				continue
			}
			if let array = value as? [Any] {
				for value in array {
					guard let value = String(describing: value).addingPercentEncoding(withAllowedCharacters: allowedChars) else {
						continue
					}
					query.append(key + "[]=" + value)
				}
			} else {
				guard let value = String(describing: value).addingPercentEncoding(withAllowedCharacters: allowedChars) else {
					continue
				}
				query.append(key + "=" + value)
			}
		}
		return query.joined(separator: "&")
	}
	
	public static func spot(queryString parameters: [AnyHashable: Any], encode: Bool = true) -> String {
		var pairs: URLKeyValuePairs = []
		pairs.reserveCapacity(parameters.count)
		for (key, value) in parameters {
			let key = String(describing: key)
			pairs.append((key, value))
		}
		return spot(queryString: pairs, encode: encode)
	}
	
	public static func spot(jsonObject: Any, encoding: String.Encoding = .utf8) throws -> String {
		let data = try JSONSerialization.data(withJSONObject: jsonObject)
		guard let value = String(data: data, encoding: encoding) else {
			throw AttributedError(.invalidFormat, object: data)
		}
		return value
	}
	
	public static var spot_localizedBundleDisplayName: String {
		"CFBundleDisplayName".spot.localize(table: "InfoPlist")
	}
}

extension Suffix where Base == String {
	public var pathExtension: Substring? {
		lastPart(delimit: ".")
	}
	
	public var lastPathComponent: Substring? {
		lastPart(delimit: "/")
	}
	
	/// Get last delimited part
	public func lastPart(delimit: Character) -> Substring? {
		guard let index = base.reversed().firstIndex(of: delimit) else {
			return nil
		}
		return base[index.base...]
	}
	
	/// Get substring in range.
	///
	/// Negative argument would index from end, -1 means next of last character.
	///
	/// Large number would become 0 or index of last character.
	///
	/// - Parameters:
	///   - from: From index.
	///   - to: To index, the charactor won't be included.
	/// - Returns: Substring
	public func substring(from: Int = 0, to: Int = -1) -> Substring {
		let len = base.count
		guard len > 0 && from < len else {
			return ""
		}
		let _from = from < 0 ? (-from <= len ? len + from + 1 : 0) : from
		let _to = to < 0
			? (-to <= len ? len + to + 1 : 0)
			: (to < len ? to : len)
		guard _from < _to else {
			return ""
		}
		let range = base.index(base.startIndex, offsetBy: _from) ..< base.index(base.startIndex, offsetBy: _to)
		return base[range]
	}
	
	/// Get character at index in string.
	/// - Parameter index: Index
	/// - Returns: Character if index in characters range.
	public func char(at index: Int) -> Character? {
		guard index >= 0 && index < base.count else {return nil}
		return base[base.index(base.startIndex, offsetBy: index)]
	}
	
	public var encodedHTMLSpecialCharacters: String {
		var encoded = ""
		encoded.reserveCapacity(base.count)
		for it in base {
			if let replacement = htmlSpecialCharacters[it] {
				encoded += replacement
			} else {
				encoded.append(it)
			}
		}
		return encoded
	}
	
	/// Get localized string, alias of Localization.shared.localizedString()
	public func localize(values: [String: Any]? = nil,
						 table: String? = nil,
						 language: String? = nil) -> String {
		Localization.shared.localizedString(key: base, replacement: values, table: table, language: language)
	}
	
	public var md5: String {
		MD5Digest.create(base).stringValue
	}
	
	public var md5HashCode: Int64 {
		let digest = MD5Digest.create(base)
		var code: Int64 = 0
		for (index, byte) in digest.digest.enumerated() where index < 8 {
			code += Int64(byte) << (index * 8)
		}
		code &= 0x7FFF_FFFF_FFFF_FFFF
		return code
	}
	
	public var parsedQueryString: [Substring: Substring] {
		Substring(base).spot.parsedQueryString
	}
	
	public var boolValue: Bool {
		Substring(base).spot.boolValue
	}
	
	// MARK: URL Safe Base64
	
	public var encodedURLSafeBase64: String {
		base
			.replacingOccurrences(of: "+", with: "-")
			.replacingOccurrences(of: "/", with: "_")
			.replacingOccurrences(of: "=", with: "")
	}
	
	public var decodedURLSafeBase64: String {
		let rem = base.count % 4
		let ending = rem > 0 ? String(repeating: "=", count: 4 - rem) : ""
		return base
			.replacingOccurrences(of: "-", with: "+")
			.replacingOccurrences(of: "_", with: "/") + ending
	}
}
