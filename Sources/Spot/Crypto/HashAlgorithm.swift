//
//  HashAlgorithm.swift
//  
//
//  Created by Shawn Clovie on 6/5/2020.
//

import Foundation
import CommonCrypto

public enum HashAlgorithm {
	case md5
	case sha1, sha224, sha256, sha384, sha512
	
	public var digestLength: Int32 {
		switch self {
		case .md5:		return CC_MD5_DIGEST_LENGTH
		case .sha1:		return CC_SHA1_DIGEST_LENGTH
		case .sha224:	return CC_SHA224_DIGEST_LENGTH
		case .sha256:	return CC_SHA256_DIGEST_LENGTH
		case .sha384:	return CC_SHA384_DIGEST_LENGTH
		case .sha512:	return CC_SHA512_DIGEST_LENGTH
		}
	}
	
	private var function: (UnsafeRawPointer?, CC_LONG, UnsafeMutablePointer<UInt8>?) -> UnsafeMutablePointer<UInt8>? {
		switch self {
		case .md5:		return CC_MD5
		case .sha1:		return CC_SHA1
		case .sha224:	return CC_SHA224
		case .sha256:	return CC_SHA256
		case .sha384:	return CC_SHA384
		case .sha512:	return CC_SHA512
		}
	}
	
	public func hash(_ data: Data) -> Data {
		let len = digestLength
		var hash = [UInt8](repeating: 0, count: Int(len))
		_ = data.withUnsafeBytes { (bytes) in
			function(bytes.baseAddress, UInt32(len), &hash)
		}
		return Data(hash)
	}
}
