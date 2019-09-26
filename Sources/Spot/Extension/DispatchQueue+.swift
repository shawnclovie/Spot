//
//  DispatchQueue.swift
//  Spot
//
//  Created by Shawn Clovie on 4/5/16.
//  Copyright © 2016 Shawn Clovie. All rights reserved.
//

import Foundation

extension Suffix where Base: DispatchQueue {
	
	public func async<T>(_ value: T, _ closure: @escaping (T)->Void) {
		base.async {
			closure(value)
		}
	}
	
	public func async<T>(_ value: T, _ closure: @escaping (T?)->Void) {
		base.async {
			closure(value)
		}
	}
}
