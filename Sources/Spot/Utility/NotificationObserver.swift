//
//  NotificationObserver.swift
//  Spot
//
//  Created by Shawn Clovie on 23/6/2019.
//  Copyright © 2019 Shawn Clovie. All rights reserved.
//

import Foundation

/// The observer can observe notification, and it may remove from NotificationCenter on deinit.
public final class NotificationObserver {
	
	private let center: NotificationCenter
	private let shouldRemoveObserversOnDeinit: Bool
	private var observations: [Notification.Name: NSObjectProtocol] = [:]
	
	public init(by: NotificationCenter = .default,
				shouldRemoveObserversOnDeinit: Bool = true) {
		center = by
		self.shouldRemoveObserversOnDeinit = shouldRemoveObserversOnDeinit
	}
	
	@discardableResult
	public func observe(_ name: Notification.Name,
						object: Any? = nil,
						queue: OperationQueue? = nil,
						using: @escaping (Notification)->Void) -> Self {
		removeObserver(name: name)
		observations[name] = center.addObserver(forName: name, object: object, queue: queue, using: using)
		return self
	}
	
	public func removeObserver(name: Notification.Name) {
		observations.removeValue(forKey: name).map(center.removeObserver)
	}
	
	deinit {
		if shouldRemoveObserversOnDeinit {
			observations.values.forEach(center.removeObserver)
		}
	}
}
