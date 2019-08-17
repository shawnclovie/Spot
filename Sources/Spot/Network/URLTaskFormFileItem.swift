//
//  URLTaskFormFileItem.swift
//  Spot
//
//  Created by Shawn Clovie on 01/04/2017.
//  Copyright © 2017 Shawn Clovie. All rights reserved.
//

import Foundation
import CoreGraphics

public protocol URLTaskFormFileItem {
	var filename: String {get}
	var contentType: String? {get}
	var source: Data.Source {get}
	var meta: [String: Any] {get}
}

public struct URLTaskFormMediaFileItem: URLTaskFormFileItem {
	public let filename: String
	public var contentType: String?
	public let source: Data.Source
	public var size: CGSize = .zero
	public var duration: TimeInterval = 0
	
	public init(filename: String, _ source: Data.Source) {
		self.filename = filename
		self.source = source
	}
	
	public var meta: [String: Any] {
		var meta: [String: Any] = [:]
		if size != .zero {
			meta["width"] = Int(size.width)
			meta["height"] = Int(size.height)
		}
		if duration != 0 {
			meta["duration"] = duration
		}
		return meta
	}
}
