//
//  NSData+Extension.swift
//  Spot
//
//  Created by Shawn Clovie on 5/10/16.
//  Copyright © 2016 Shawn Clovie. All rights reserved.
//

import Foundation

extension Data: SuffixProtocol {
	public enum Source {
		case url(URL)
		case data(Data)
		
		public var url: URL? {
			if case .url(let url) = self {
				return url
			}
			return nil
		}
		
		public var data: Data? {
			switch self {
			case .data(let data):	return data
			case .url(let url):		return (try? Data(contentsOf: url))
			}
		}
	}
}

extension Suffix where Base == Data {
	
	public var hexString: String {
		base.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> String in
			var result = ""
			for byte in bytes {
				result.append(String(format: "%02hhx", byte))
			}
			return result
		}
	}
	
	/// Parse JSON from data with JSONSerialization, the function would avoid NSException since zero length data.
	/// - Throws: SpotError(.invalidFormat) if data.count == 0, or errors from SpotError(.invalidFormat).
	public func parseJSON(options: JSONSerialization.ReadingOptions = []) throws -> Any {
		guard base.count > 0 else {
			throw AttributedError(.invalidFormat)
		}
		return try JSONSerialization.jsonObject(with: base, options: options)
	}
	
	/// XOR every bytes in data with every UTF8 bytes of key.
	///
	/// - Parameter key:  XOR Key
	///
	/// - Returns: Data did maked XOR, or source data if key is empty.
	public func xor(withKey key: String) -> Data {
		guard base.count > 0 else {
			return Data()
		}
		let keyArray = Array(key.utf8)
		let keyLen = keyArray.count
		if keyLen == 0 {
			return Data()
		}
		var pos = 0
		let bytes = UnsafeMutableBufferPointer<UInt8>(start: UnsafeMutablePointer(mutating: (base as NSData).bytes.bindMemory(to: UInt8.self, capacity: base.count)), count: base.count)
		for i in 0..<bytes.count {
			pos = pos < keyLen - 1 ? pos + 1 : 0
			bytes[i] ^= keyArray[pos]
		}
		return Data(bytes: UnsafePointer<UInt8>(bytes.baseAddress!), count: bytes.count)
	}
}
