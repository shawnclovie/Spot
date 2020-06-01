//
//  TypeConvertion.swift
//  Spot
//
//  Created by Shawn Clovie on 24/9/2019.
//  Copyright © 2019 Shawn Clovie. All rights reserved.
//

import Foundation
import struct CoreGraphics.CGFloat

public func AnyToString(_ v: Any?) -> String? {
	switch v {
	case let v as Int64:		return String(v)
	case let v as Int:			return String(v)
	case let v as Int8:			return String(v)
	case let v as Int16:		return String(v)
	case let v as Int32:		return String(v)
	case let v as UInt:			return String(v)
	case let v as UInt8:		return String(v)
	case let v as UInt16:		return String(v)
	case let v as UInt32:		return String(v)
	case let v as UInt64:		return String(v)
	case let v as Double:		return String(v)
	case let v as Float:		return String(v)
	case let v as CGFloat:		return String(v.native)
	case let v as Bool:			return v ? "true" : "false"
	case let v as String:		return v
	case let v as Substring:	return String(v)
	case let v as CustomStringConvertible:
		return v.description
	case let v as CustomDebugStringConvertible:
		return v.debugDescription
	default:return nil
	}
}

public func AnyToInt64(_ v: Any?) -> Int64? {
	switch v {
	case let v as Int64:		return v
	case let v as Int:			return Int64(v)
	case let v as Int8:			return Int64(v)
	case let v as Int16:		return Int64(v)
	case let v as Int32:		return Int64(v)
	case let v as UInt:			return Int64(v)
	case let v as UInt8:		return Int64(v)
	case let v as UInt16:		return Int64(v)
	case let v as UInt32:		return Int64(v)
	case let v as UInt64:		return Int64(v)
	case let v as Double:		return Int64(v)
	case let v as Float:		return Int64(v)
	case let v as CGFloat:		return Int64(v)
	case let v as Bool:			return v ? 1 : 0
	case let v as String:		return Int64(v)
	case let v as Substring:	return Int64(v)
	default:return nil
	}
}

public func AnyToInt(_ v: Any?) -> Int? {
	AnyToInt64(v).map(Int.init)
}

public func AnyToDouble(_ v: Any?) -> Double? {
	switch v {
	case let v as Int:			return Double(v)
	case let v as Int8:			return Double(v)
	case let v as Int16:		return Double(v)
	case let v as Int32:		return Double(v)
	case let v as UInt:			return Double(v)
	case let v as UInt8:		return Double(v)
	case let v as UInt16:		return Double(v)
	case let v as UInt32:		return Double(v)
	case let v as UInt64:		return Double(v)
	case let v as Double:		return v
	case let v as Float:		return Double(v)
	case let v as CGFloat:		return Double(v)
	case let v as Bool:			return v ? 1 : 0
	case let v as String:		return Double(v)
	case let v as Substring:	return Double(v)
	default:return nil
	}
}

public func AnyToBool(_ v: Any?) -> Bool? {
	switch v {
	case let v as Bool:			return v
	case let v as Int:			return v != 0
	case let v as UInt:			return v != 0
	case let v as Float:		return v != 0
	case let v as Double:		return v != 0
	case let v as String:		return v.first?.boolValue
	case let v as Substring:	return v.first?.boolValue
	default:return nil
	}
}

private extension Character {
	var boolValue: Bool {
		["t", "T", "y", "Y", "1"].contains(self)
	}
}
