//
//  Zip.swift
//  Spot
//
//  Created by Shawn Clovie on 17/8/2019.
//  Copyright © 2019 Spotlit.club. All rights reserved.
//

import Foundation
#if os(Linux)
import zlibLinux
#else
import zlib
#endif

public struct Zip {
	
	/// Zip level whose rawValue is based on the zlib's constants.
	public struct Level: RawRepresentable {
		
		/// Zip level in the range of `0` (no compression) to `9` (maximum compression).
		public let rawValue: Int32
		
		public static let store = Level(Z_NO_COMPRESSION)
		public static let quickly = Level(Z_BEST_SPEED)
		public static let smaller = Level(Z_BEST_COMPRESSION)
		public static let `default` = Level(Z_DEFAULT_COMPRESSION)
		
		public init(rawValue: Int32) {
			self.rawValue = rawValue
		}
		
		public init(_ rawValue: Int32) {
			self.rawValue = rawValue
		}
	}
	
	/// Whether the data is compressed in gzip format (by check magic number).
	public static func isDefalted(_ data: Data) -> Bool {
		data.starts(with: [0x1f, 0x8b])
	}
	
	/// Create a new `Data` object by compressing the receiver using zlib.
	///
	/// - Parameter level: Compression level.
	/// - throws: `ZipError`
	/// - returns: Zipped data
	public static func deflated(_ data: Data, level: Level) throws -> Data {
		guard let contiguousData = data.withUnsafeBytes({ (bytes: UnsafeRawBufferPointer) -> Data? in
			guard let bytes = bytes.baseAddress else {return nil}
			return Data(bytes: UnsafePointer(OpaquePointer(bytes)), count: data.count)
		}), !contiguousData.isEmpty else {
			return Data()
		}
		var stream = makeZStream(for: contiguousData)
		let status = deflateInit2_(&stream, level.rawValue, Z_DEFLATED, MAX_WBITS + 16, MAX_MEM_LEVEL, Z_DEFAULT_STRATEGY, ZLIB_VERSION, streamSize)
		guard status == Z_OK else {
			// deflateInit2 returns:
			// Z_VERSION_ERROR  The zlib library version is incompatible with the version assumed by the caller.
			// Z_MEM_ERROR      There was not enough memory.
			// Z_STREAM_ERROR   A parameter is invalid.
			throw AttributedError(zip: status, msg: stream.msg)
		}
		var data = Data(capacity: chunkSize)
		while stream.avail_out == 0 {
			if Int(stream.total_out) >= data.count {
				data.count += chunkSize
			}
			let len = data.count
			data.withUnsafeMutableBytes { (bytes: UnsafeMutableRawBufferPointer) in
				guard let ptr = bytes.baseAddress else {return}
				let advanced = ptr.advanced(by: Int(stream.total_out))
				stream.next_out = UnsafeMutablePointer(OpaquePointer(advanced))
				stream.avail_out = uInt(len) - uInt(stream.total_out)
				deflate(&stream, Z_FINISH)
			}
		}
		deflateEnd(&stream)
		data.count = Int(stream.total_out)
		return data
	}
	
	/// Create a new `Data` object by decompressing the receiver using zlib.
	/// - Throws: `ZipError`
	/// - Returns: Unzipped data
	public static func inflated(_ data: Data) throws -> Data {
		guard let contiguousData = data.withUnsafeBytes({ (bytes: UnsafeRawBufferPointer) -> Data? in
			guard let bytes = bytes.baseAddress else {return nil}
			return Data(bytes: UnsafePointer(OpaquePointer(bytes)), count: data.count)
		}), !contiguousData.isEmpty else {
			return Data()
		}
		var stream = makeZStream(for: contiguousData)
		var status = inflateInit2_(&stream, MAX_WBITS + 32, ZLIB_VERSION, streamSize)
		guard status == Z_OK else {
			// inflateInit2 returns:
			// Z_VERSION_ERROR   The zlib library version is incompatible with the version assumed by the caller.
			// Z_MEM_ERROR       There was not enough memory.
			// Z_STREAM_ERROR    A parameters are invalid.
			throw AttributedError(zip: status, msg: stream.msg)
		}
		var data = Data(capacity: contiguousData.count * 2)
		repeat {
			if Int(stream.total_out) >= data.count {
				data.count += contiguousData.count / 2
			}
			let len = data.count
			data.withUnsafeMutableBytes { (bytes: UnsafeMutableRawBufferPointer) in
				guard let ptr = bytes.baseAddress else {return}
				let advanced = ptr.advanced(by: Int(stream.total_out))
				stream.next_out = UnsafeMutablePointer(OpaquePointer(advanced))
				stream.avail_out = uInt(len) - uInt(stream.total_out)
				status = inflate(&stream, Z_SYNC_FLUSH)
			}
		} while status == Z_OK
		guard inflateEnd(&stream) == Z_OK && status == Z_STREAM_END else {
			// inflate returns:
			// Z_DATA_ERROR   The input data was corrupted (input stream not conforming to the zlib format or incorrect check value).
			// Z_STREAM_ERROR The stream structure was inconsistent (for example if next_in or next_out was NULL).
			// Z_MEM_ERROR    There was not enough memory.
			// Z_BUF_ERROR    No progress is possible or there was not enough room in the output buffer when Z_FINISH is used.
			throw AttributedError(zip: status, msg: stream.msg)
		}
		data.count = Int(stream.total_out)
		return data
	}
	
	private static func makeZStream(for data: Data) -> z_stream {
		var stream = z_stream()
		data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
			guard let bytes = bytes.baseAddress else {return}
			stream.next_in = UnsafeMutablePointer(OpaquePointer(bytes))
		}
		stream.avail_in = uint(data.count)
		return stream
	}

	private static let chunkSize = 2 ^ 14
	private static let streamSize = Int32(MemoryLayout<z_stream>.size)
	
	private init() {}
}

extension Suffix where Base == Data {
	/// Whether the data is compressed in gzip format (by check magic number).
	public var isDefalted: Bool {
		Zip.isDefalted(base)
	}
	
	/// Create a new `Data` object by compressing the receiver using zlib.
	///
	/// - Parameter level: Compression level.
	/// - throws: `ZipError`
	/// - returns: Zipped data
	public func deflated(level: Zip.Level = .default) throws -> Data {
		try Zip.deflated(base, level: level)
	}
	
	/// Create a new `Data` object by decompressing the receiver using zlib.
	/// - Throws: `ZipError`
	/// - Returns: Unzipped data
	public func inflated() throws -> Data {
		try Zip.inflated(base)
	}
}

/// Errors on gzipping/gunzipping based on the zlib error codes.
extension AttributedError {
	
	fileprivate init(zip code: Int32, msg: UnsafePointer<CChar>?) {
		let desc: String
		if let msg = msg, let message = String(validatingUTF8: msg) {
			desc = message
		} else {
			desc = "Unknown gzip error"
		}
		self.init(.init(zip: code), object: nil, original: nil, userInfo: [NSLocalizedDescriptionKey: desc, "zip.error_code": code])
	}
}

extension AttributedError.Source {
	/// The stream structure was inconsistent.
	/// - underlying zlib error: `Z_STREAM_ERROR` (-2)
	public static let zipStream = AttributedError.Source("zip.stream")
	
	/// The input data was corrupted (input stream not conforming to the zlib format or incorrect check value).
	/// - underlying zlib error: `Z_DATA_ERROR` (-3)
	public static let zipData = AttributedError.Source("zip.data")
	
	/// There was not enough memory.
	/// - underlying zlib error: `Z_MEM_ERROR` (-4)
	public static let zipMemory = AttributedError.Source("zip.memory")
	
	/// No progress is possible or there was not enough room in the output buffer.
	/// - underlying zlib error: `Z_BUF_ERROR` (-5)
	public static let zipBuffer = AttributedError.Source("zip.buffer")
	
	/// The zlib library version is incompatible with the version assumed by the caller.
	/// - underlying zlib error: `Z_VERSION_ERROR` (-6)
	public static let zipVersion = AttributedError.Source("zip.version")
	
	fileprivate init(zip code: Int32) {
		switch code {
		case Z_STREAM_ERROR:
			self = .zipStream
		case Z_DATA_ERROR:
			self = .zipData
		case Z_MEM_ERROR:
			self = .zipMemory
		case Z_BUF_ERROR:
			self = .zipBuffer
		case Z_VERSION_ERROR:
			self = .zipVersion
		default:
			self = .unknown
		}
	}
}
