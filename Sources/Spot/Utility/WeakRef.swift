//
//  WeakRef.swift
//  Spot
//
//  Created by Shawn Clovie on 25/1/2018.
//  Copyright © 2018 Shawn Clovie. All rights reserved.
//

public struct WeakRef<T: AnyObject> {
	public weak var object: T?
	
	public init(_ obj: T) {
		object = obj
	}
}
