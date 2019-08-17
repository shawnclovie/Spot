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

struct Zip {
	/// Whether the data is compressed in gzip format (by check magic number).
	public static func isDefalted(_ data: Data) -> Bool {
		data.starts(with: [0x1f, 0x8b])
	}
	
	/// Create a new `Data` object by compressing the receiver using zlib.
	///
	/// - Parameter level: Compression level.
	/// - throws: `ZipError`
	/// - returns: Zipped data
	public static func deflated(_ data: Data, level: ZipLevel) throws -> Data {
		guard let contiguousData = data.withUnsafeBytes({ (bytes: UnsafeRawBufferPointer) -> Data? in
			guard let bytes = bytes.baseAddress else {return nil}
			return Data(bytes: UnsafePointer(OpaquePointer(bytes)), count: data.count)
		}), !contiguousData.isEmpty else {
			return Data()
		}
		var stream = makeZStream(for: contiguousData)
		let status = deflateInit2_(&stream, level.rawValue, Z_DEFLATED, MAX_WBITS + 16, MAX_MEM_LEVEL, Z_DEFAULT_STRATEGY, ZLIB_VERSION, ZipStreamSize)
		guard status == Z_OK else {
			// deflateInit2 returns:
			// Z_VERSION_ERROR  The zlib library version is incompatible with the version assumed by the caller.
			// Z_MEM_ERROR      There was not enough memory.
			// Z_STREAM_ERROR   A parameter is invalid.
			throw ZipError(code: status, msg: stream.msg)
		}
		var data = Data(capacity: ZipChunkSize)
		while stream.avail_out == 0 {
			if Int(stream.total_out) >= data.count {
				data.count += ZipChunkSize
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
		var status = inflateInit2_(&stream, MAX_WBITS + 32, ZLIB_VERSION, ZipStreamSize)
		guard status == Z_OK else {
			// inflateInit2 returns:
			// Z_VERSION_ERROR   The zlib library version is incompatible with the version assumed by the caller.
			// Z_MEM_ERROR       There was not enough memory.
			// Z_STREAM_ERROR    A parameters are invalid.
			throw ZipError(code: status, msg: stream.msg)
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
			throw ZipError(code: status, msg: stream.msg)
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
}

private let ZipChunkSize = 2 ^ 14
private let ZipStreamSize = Int32(MemoryLayout<z_stream>.size)
