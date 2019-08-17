//
//  ZipLevel.swift
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

/// Zip level whose rawValue is based on the zlib's constants.
public struct ZipLevel: RawRepresentable {
	
	/// Zip level in the range of `0` (no compression) to `9` (maximum compression).
	public let rawValue: Int32
	
	public static let store = ZipLevel(Z_NO_COMPRESSION)
	public static let quickly = ZipLevel(Z_BEST_SPEED)
	public static let smaller = ZipLevel(Z_BEST_COMPRESSION)
	public static let `default` = ZipLevel(Z_DEFAULT_COMPRESSION)
	
	public init(rawValue: Int32) {
		self.rawValue = rawValue
	}
	
	public init(_ rawValue: Int32) {
		self.rawValue = rawValue
	}
}
