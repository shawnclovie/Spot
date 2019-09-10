//
//  WeakTimer.swift
//  Spot
//
//  Created by Shawn Clovie on 4/29/16.
//  Copyright © 2016 Shawn Clovie. All rights reserved.
//

import Foundation

private typealias SelectorIMP = @convention(c) (AnyObject, Selector, AnyObject)->Void

/// Timer with weak reference to target.
public final class WeakTimer: NSObject {
	private enum Invoker {
		case closure((WeakTimer)->Void)
		case target(ref: WeakRef<AnyObject>, action: Selector)
	}
	
	private var timer: Timer?
	private var invoker: Invoker?
	
	public init(interval: TimeInterval, repeats: Bool, userInfo: Any? = nil, handler: @escaping (WeakTimer)->Void) {
		invoker = .closure(handler)
		super.init()
		resetTimer(interval, repeats: repeats, userInfo: userInfo)
	}
	
	public init(interval: TimeInterval, repeats: Bool, userInfo: Any? = nil, target: AnyObject, selector: Selector) {
		invoker = .target(ref: WeakRef(target), action: selector)
		super.init()
		resetTimer(interval, repeats: repeats, userInfo: userInfo)
	}
	
	public var isValid: Bool {timer?.isValid ?? false}
	
	public var tolerance: TimeInterval {timer?.tolerance ?? 0}
	
	public var userInfo: Any? {timer?.userInfo}
	
	public func invalidate() {
		timer?.invalidate()
		invoker = nil
	}
	
	public func resetTimer(_ interval: TimeInterval, repeats: Bool, userInfo: Any? = nil) {
		timer?.invalidate()
		timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(fired(_:)), userInfo: userInfo, repeats: repeats)
	}
	
	@objc func fired(_ timer: Timer) {
		guard let invoker = invoker else {
			invalidate()
			return
		}
		switch invoker {
		case .closure(let handler):
			handler(self)
		case .target(let it):
			if let target = it.ref.object, target.responds(to: it.action) {
				let method = unsafeBitCast(target.method(for: it.action), to: SelectorIMP.self)
				method(target, it.action, self)
			}
		}
	}
}
