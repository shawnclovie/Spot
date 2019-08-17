//
//  CFDictionary+.swift
//  Spot
//
//  Created by Shawn Clovie on 20/2/2019.
//  Copyright © 2019 Shawn Clovie. All rights reserved.
//

import Foundation

extension CFDictionary: SuffixProtocol {
}

extension Suffix where Base == CFDictionary {
	
	public func value(forKey key: AnyObject) -> UnsafeRawPointer? {
		CFDictionaryGetValue(base, Unmanaged.passUnretained(key).toOpaque())
	}
	
	public func unsafeCastValue<T>(forKey key: AnyObject) -> T? {
		let value = self.value(forKey: key)
		return value == nil ? nil : unsafeBitCast(value, to: T.self)
	}
}
