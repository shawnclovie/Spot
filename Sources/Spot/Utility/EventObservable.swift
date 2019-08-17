//
//  EventObservable.swift
//  Spot
//
//  Created by Shawn Clovie on 24/6/2019.
//  Copyright © 2019 Shawn Clovie. All rights reserved.
//

import Foundation

public protocol EventObserver {
	func invalidate()
}

extension Array where Element == EventObserver {
	public mutating func invalidateAndRemoveAll() {
		for it in self {
			it.invalidate()
		}
		removeAll()
	}
}

public final class EventObservable<T> {
	
	private typealias TargetActionSelectorIMP = @convention(c) (AnyObject, Selector, Any)->Void

	private struct Observer: EventObserver {
		
		let index: Int
		weak var dispatcher: EventObservable?
		
		func invalidate() {
			dispatcher?.invalidate(observer: self)
		}
	}
	
	private enum Closure {
		case closure((T)->Void)
		case weakTargetAction(target: WeakRef<AnyObject>, action: Selector)
	}
	
	private var seed = 0
	private var closures: [Int: Closure] = [:]
	private let syncQueue: DispatchQueue
	
	public init(name: String = "") {
		syncQueue = .init(label: "\(EventObservable.self).\(name.isEmpty ? UUID().uuidString : name)")
	}
	
	public func subscribe(_ fn: @escaping (T)->Void) -> EventObserver {
		let index = subscribe(.closure(fn))
		return Observer(index: index, dispatcher: self)
	}
	
	/// Subscribe event with weak referenced object and selector.
	/// MAKE SURE selector have same argument with the observer's type.
	///
	/// - Parameters:
	///   - weakRef: Object would be weak referenced.
	///   - action: Selector to calling.
	public func subscribe(weakTarget: AnyObject, action: Selector) {
		_ = subscribe(.weakTargetAction(target: .init(weakTarget), action: action))
	}
	
	private func subscribe(_ closure: Closure) -> Int {
		syncQueue.sync {
			let index = seed + 1
			seed = index
			closures[index] = closure
			return index
		}
	}
	
	public func invalidate(target: AnyObject) {
		syncQueue.sync {
			for (key, closure) in closures {
				guard case .weakTargetAction(let it) = closure,
					it.target.object === target else {continue}
				closures.removeValue(forKey: key)
			}
		}
	}
	
	public func invalidateAllObservers() {
		syncQueue.sync {
			closures.removeAll()
		}
	}
	
	private func invalidate(observer: Observer) {
		syncQueue.sync {
			_ = closures.removeValue(forKey: observer.index)
		}
	}
	
	public func dispatch(_ v: T) {
		closures.values.forEach {
			switch $0 {
			case .closure(let fn):
				fn(v)
			case .weakTargetAction(let it):
				guard let target = it.target.object,
					target.responds(to: it.action),
					let imp = target.method(for: it.action) else {break}
				let method = unsafeBitCast(imp, to: TargetActionSelectorIMP.self)
				method(target, it.action, v)
			}
		}
	}
	
	public func dispatch(_ v: T, queue: DispatchQueue) {
		guard !closures.isEmpty else {return}
		queue.spot.async(v, dispatch(_:))
	}
}
