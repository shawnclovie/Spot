//
//  SynchronizableValue.swift
//  Spot
//
//  Created by Shawn Clovie on 11/8/2019.
//  Copyright © 2019 Shawn Clovie. All rights reserved.
//

import Dispatch

public struct SynchronizableValue<T> {
	private var value: T
	private let lock: DispatchSemaphore
	
	public init(_ v: T, maxAccessCount: Int = 1) {
		value = v
		lock = .init(value: max(1, maxAccessCount))
	}
	
	public func get() -> T {
		return value
	}
	
	public func waitAndGet() -> T {
		lock.wait()
		let v = value
		lock.signal()
		return v
	}
	
	public mutating func waitAndSet(_ v: T) {
		lock.wait()
		value = v
		lock.signal()
	}
	
	public mutating func waitAndSet(_ v: T, timeout: DispatchTime) throws {
		switch lock.wait(timeout: timeout) {
		case .success:
			value = v
			lock.signal()
		case .timedOut:
			throw AttributedError(.timeout)
		}
	}
	
	public mutating func waitAndSet(with fn: (inout T)->Void) {
		lock.wait()
		fn(&value)
		lock.signal()
	}
	
	public mutating func waitAndSet(with fn: (inout T)->Void, timeout: DispatchTime) throws {
		switch lock.wait(timeout: timeout) {
		case .success:
			fn(&value)
			lock.signal()
		case .timedOut:
			throw AttributedError(.timeout)
		}
	}
}
