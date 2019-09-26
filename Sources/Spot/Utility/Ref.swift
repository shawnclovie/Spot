//
//  Ref.swift
//  Spot
//
//  Created by Shawn Clovie on 4/7/2018.
//  Copyright © 2018 Shawn Clovie. All rights reserved.
//

public final class Ref<T> {
	public var value: T
	
	public init(_ v: T) {
		value = v
	}
}
