//
//  SymmetricCryptor
//  CommonCryptoInSwift
//
//  Created by Ignacio Nieto Carvajal on 9/8/15.
//  Copyright © 2015 Ignacio Nieto Carvajal. All rights reserved.
//

import Foundation
import CommonCrypto

private let RandomStringGeneratorCharset: [Character] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".map({$0})

public enum SymmetricCryptorError: Error {
	case missingIV
	case operationFailed(status: CCCryptorStatus)
	case wrongInputData
}

public struct SymmetricCryptor {

	public enum Algorithm {
		case des		// DES standard, 64 bits key
		case des40		// DES, 40 bits key
		case tripledes	// 3DES, 192 bits key
		case rc4_40		// RC4, 40 bits key
		case rc4_128	// RC4, 128 bits key
		case rc2_40		// RC2, 40 bits key
		case rc2_128	// RC2, 128 bits key
		case aes128		// AES, 128 bits key
		case aes256		// AES, 256 bits key
		
		var ccAlgorithm: CCAlgorithm {
			switch (self) {
			case .des, .des40:		return CCAlgorithm(kCCAlgorithmDES)
			case .tripledes:		return CCAlgorithm(kCCAlgorithm3DES)
			case .rc4_40, .rc4_128:	return CCAlgorithm(kCCAlgorithmRC4)
			case .rc2_40, .rc2_128:	return CCAlgorithm(kCCAlgorithmRC2)
			case .aes128, .aes256:	return CCAlgorithm(kCCAlgorithmAES)
			}
		}
		
		// Returns the needed size for the IV to be used in the algorithm (0 if no IV is needed).
		public func requiredIVSize(_ options: Options) -> Int {
			// if kCCOptionECBMode is specified, no IV is needed.
			guard !options.contains(.ecbMode) else {
				return 0
			}
			// else depends on algorithm
			switch (self) {
			case .des, .des40:		return kCCBlockSizeDES
			case .tripledes:		return kCCBlockSize3DES
			case .rc4_40, .rc4_128:	return 0
			case .rc2_40, .rc2_128:	return kCCBlockSizeRC2
			case .aes128, .aes256:	return kCCBlockSizeAES128
				// AES256 still requires 256 bits IV
			}
		}
		
		public var requiredKeySize: Int {
			switch (self) {
			case .des:		return kCCKeySizeDES
			case .des40:	return 5 // 40 bits = 5x8
			case .tripledes:return kCCKeySize3DES
			case .rc4_40:	return 5
			case .rc4_128:	return 16 // RC4 128 bits = 16 bytes
			case .rc2_40:	return 5
			case .rc2_128:	return kCCKeySizeMaxRC2 // 128 bits
			case .aes128:	return kCCKeySizeAES128
			case .aes256:	return kCCKeySizeAES256
			}
		}
		
		public var requiredBlockSize: Int {
			switch (self) {
			case .des, .des40:		return kCCBlockSizeDES
			case .tripledes:		return kCCBlockSize3DES
			case .rc4_40, .rc4_128:	return 0
			case .rc2_40, .rc2_128:	return kCCBlockSizeRC2
			case .aes128, .aes256:	return kCCBlockSizeAES128
				// AES256 still requires 128 bits IV
			}
		}
	}
	
	public struct Options: OptionSet {
		
		public let rawValue: UInt32
		
		public init(rawValue: UInt32) {
			self.rawValue = rawValue
		}
		
		public static let pkcs7Padding = Options(rawValue: 1 << 0)
		public static let ecbMode = Options(rawValue: 1 << 1)
		
		public static var allCases: [Options] {
			return [.pkcs7Padding, .ecbMode]
		}
		
		var ccOptions: CCOptions {
			var value: CCOptions = 0
			for it in Options.allCases {
				guard contains(it) else {continue}
				switch it {
				case .ecbMode:		value |= CCOptions(kCCOptionECBMode)
				case .pkcs7Padding:	value |= CCOptions(kCCOptionPKCS7Padding)
				default:break
				}
			}
			return value
		}
	}
	
	public let algorithm: Algorithm
	
	// Options (i.e: kCCOptionECBMode + kCCOptionPKCS7Padding)
	public let options: Options
	
	// Initialization Vector
	public private(set) var iv: Data?
	
	/// - Parameters:
	///   - algorithm: Algorithm
	///   - options: Options for mode and padding, CBC mode and PKCS7 by default
	///   - iv: Initialization Vector for CBC mode
	public init(algorithm: Algorithm, options: Options = [.pkcs7Padding], iv: Data? = nil) {
		self.algorithm = algorithm
		self.options = options
		self.iv = iv
	}
	
	public mutating func setRandomIV() {
		let length = algorithm.requiredIVSize(options)
		iv = SymmetricCryptor.randomData(of: length)
	}
	
	public func encrypt(_ string: String, key: Data) throws -> Data {
		try cryptoOperation(Data(string.utf8), key: key, operation: CCOperation(kCCEncrypt))
	}
	
	public func encrypt(_ data: Data, key: Data) throws -> Data {
		try cryptoOperation(data, key: key, operation: CCOperation(kCCEncrypt))
	}
	
	public func decrypt(_ data: Data, key: Data) throws -> Data  {
		try cryptoOperation(data, key: key, operation: CCOperation(kCCDecrypt))
	}
	
	private func cryptoOperation(_ input: Data, key: Data, operation: CCOperation) throws -> Data {
		// Validation checks.
		if iv == nil && !options.contains(.ecbMode) {
			throw SymmetricCryptorError.missingIV
		}
		var bytesDecrypted = 0
		let bufCount = input.count + algorithm.requiredBlockSize
		var bufData = Data(count: bufCount)
		let cryptStatus = key.withUnsafeBytes { (keyBytes: UnsafeRawBufferPointer) -> CCCryptorStatus in
			guard let keyBytes = keyBytes.baseAddress else {return CCCryptorStatus(kCCMemoryFailure)}
			return input.withUnsafeBytes { (dataBytes: UnsafeRawBufferPointer) in
				guard let dataBytes = dataBytes.baseAddress else {return CCCryptorStatus(kCCMemoryFailure)}
				return bufData.withUnsafeMutableBytes{ (bufBytes: UnsafeMutableRawBufferPointer) in
					guard let bufBytes = bufBytes.baseAddress else {return CCCryptorStatus(kCCMemoryFailure)}
					return CCCrypt(
						operation,
						algorithm.ccAlgorithm,
						options.ccOptions,
						keyBytes,
						algorithm.requiredKeySize,
						(iv as NSData?)?.bytes,	// IV buffer
						dataBytes,				// input data
						input.count,			// input length
						bufBytes,				// output buffer
						bufCount,				// output buffer length
						&bytesDecrypted
					)
				}
			}
		}
		guard cryptStatus == Int32(kCCSuccess) else {
			throw SymmetricCryptorError.operationFailed(status: cryptStatus)
		}
		// Adjust buffer size to real bytes
		bufData.count = bytesDecrypted
		return bufData
	}
	
	// MARK: - Random methods
	
	public static func randomData(of length: Int) -> Data? {
		var data = Data(count: length)
		let status = data.withUnsafeMutableBytes({ (bytes: UnsafeMutableRawBufferPointer) -> Int32 in
			guard let addr = bytes.baseAddress else {return 1}
			return SecRandomCopyBytes(kSecRandomDefault, length, addr)
		})
		return status == 0 ? data : nil
	}
	
	public static func randomString(of length:Int) -> String {
		var string = ""
		let range = 0..<RandomStringGeneratorCharset.count
		for _ in (1...length) {
			string.append(RandomStringGeneratorCharset[Int.random(in: range)])
		}
		return string
	}
}
