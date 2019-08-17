//
//  Suffix.swift
//  Spot
//
//  Created by Shawn Clovie on 20/02/2017.
//  Copyright © 2017 Shawn Clovie. All rights reserved.
//

import Foundation

public struct Suffix<Base> {
	public let base: Base
	
	public init(_ base: Base) {
		self.base = base
	}
}

public protocol SuffixProtocol {
}

extension SuffixProtocol {
	public var spot: Suffix<Self> {
		Suffix(self)
	}
}

extension NSObjectProtocol {
	public var spot: Suffix<Self> {
		Suffix(self)
	}
}
