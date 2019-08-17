//
//  KeyValueObserver.swift
//  Spot
//
//  Created by Shawn Clovie on 23/6/2019.
//  Copyright © 2019 Shawn Clovie. All rights reserved.
//

import Foundation

public final class KeyValueObserver {
	
	private let observation: NSKeyValueObservation
	
	public init<ObjectType, Value>(
		object: ObjectType,
		keyPath: KeyPath<ObjectType, Value>,
		options: NSKeyValueObservingOptions = [],
		changeHandler: @escaping (ObjectType, NSKeyValueObservedChange<Value>)->Void) where ObjectType: NSObject {
		observation = object.observe(keyPath, options: options, changeHandler: changeHandler)
	}
	
	public func invalidate() {
		observation.invalidate()
	}
	
	deinit {
		observation.invalidate()
	}
}
