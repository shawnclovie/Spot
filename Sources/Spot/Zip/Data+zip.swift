//
//  Data+zip.swift
//  Spot
//
//  Created by Shawn Clovie on 7/17/2018.
//  Copyright © 2018 Shawn Clovie. All rights reserved.
//

import Foundation

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
	public func deflated(level: ZipLevel = .default) throws -> Data {
		try Zip.deflated(base, level: level)
	}
	
	/// Create a new `Data` object by decompressing the receiver using zlib.
	/// - Throws: `ZipError`
	/// - Returns: Unzipped data
	public func inflated() throws -> Data {
		try Zip.inflated(base)
	}
}
