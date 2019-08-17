//
//  Substring+.swift
//  Spot
//
//  Created by Shawn Clovie on 31/3/2019.
//  Copyright © 2019 Shawn Clovie. All rights reserved.
//

import Foundation

extension Substring: SuffixProtocol {}

extension Suffix where Base == Substring {
	
	public var parsedQueryString: [Substring: Substring] {
		var args: [Substring: Substring] = [:]
		for item in base.components(separatedBy: "&") {
			if let pos = item.firstIndex(of: "=") {
				let key = item[..<pos]
				args[key] = item[item.index(after: pos)...]
			}
		}
		return args
	}
	
	public var boolValue: Bool {
		guard let first = base.first else {
			return false
		}
		switch first {
		case "t", "T", "1", "y", "Y":
			return true
		default:
			return false
		}
	}
}
