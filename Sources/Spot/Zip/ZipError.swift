//
//  ZipError.swift
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

/// Errors on gzipping/gunzipping based on the zlib error codes.
public struct ZipError: Error {
	public enum Kind {
		/// The stream structure was inconsistent.
		/// - underlying zlib error: `Z_STREAM_ERROR` (-2)
		case stream
		
		/// The input data was corrupted (input stream not conforming to the zlib format or incorrect check value).
		/// - underlying zlib error: `Z_DATA_ERROR` (-3)
		case data
		
		/// There was not enough memory.
		/// - underlying zlib error: `Z_MEM_ERROR` (-4)
		case memory
		
		/// No progress is possible or there was not enough room in the output buffer.
		/// - underlying zlib error: `Z_BUF_ERROR` (-5)
		case buffer
		
		/// The zlib library version is incompatible with the version assumed by the caller.
		/// - underlying zlib error: `Z_VERSION_ERROR` (-6)
		case version
		
		/// An unknown error occurred.
		/// - parameter code: return error by zlib
		case unknown(code: Int)
		
		init(code: Int32) {
			switch code {
			case Z_STREAM_ERROR:
				self = .stream
			case Z_DATA_ERROR:
				self = .data
			case Z_MEM_ERROR:
				self = .memory
			case Z_BUF_ERROR:
				self = .buffer
			case Z_VERSION_ERROR:
				self = .version
			default:
				self = .unknown(code: Int(code))
			}
		}
	}
	
	/// Error kind.
	public let kind: Kind
	
	/// Returned message by zlib.
	public let message: String
	
	internal init(code: Int32, msg: UnsafePointer<CChar>?) {
		if let msg = msg, let message = String(validatingUTF8: msg) {
			self.message = message
		} else {
			message = "Unknown gzip error"
		}
		kind = .init(code: code)
	}
	
	public var localizedDescription: String {
		message
	}
}
