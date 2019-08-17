//
//  UserDefaultsItem.swift
//  Spot
//
//  Created by Shawn Clovie on 6/4/16.
//  Copyright © 2016 Shawn Clovie. All rights reserved.
//

import Foundation

/// Data item stored with NSUserDefaults.
public struct UserDefaultsItem<T: Any> {
	public let key: String
	public let defaultValue: ()->T
	private let storage: UserDefaults
	
	public init(_ key: String, defaultValue: @autoclosure @escaping ()->T, in user: UserDefaults = .standard) {
		self.key = key
		self.defaultValue = defaultValue
		storage = user
	}
	
	public var optional: T? {
		storage.object(forKey: key) as? T
	}
	
	public var value: T {
		optional ?? defaultValue()
	}
	
	public func set(_ value: T) {
		storage.set(value, forKey: key)
		storage.synchronize()
	}
	
	public func remove() {
		storage.removeObject(forKey: key)
	}
}
