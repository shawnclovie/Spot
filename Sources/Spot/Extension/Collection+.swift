//
//  Dictionary+Extension.swift
//  Spot
//
//  Created by Shawn Clovie on 5/4/16.
//  Copyright © 2016 Shawn Clovie. All rights reserved.
//

import Foundation

extension Dictionary {
	public func spot_value(keys: Key...) -> Any? {
		spot_value(keys: ArraySlice(keys))
	}
	
	public func spot_value(keys: ArraySlice<Key>) -> Any? {
		guard let firstKey = keys.first, let value = self[firstKey] else {
			return nil
		}
		if keys.count == 1 {
			return value
		}
		guard let dict = value as? [Key: Any] else {
			return nil
		}
		return dict.spot_value(keys: keys.dropFirst())
	}
}

extension Array {
	/// Safety get element in array at index.
	public func spot_value(at index: Int) -> Element? {
		indices.contains(index) ? self[index] : nil
	}
}
