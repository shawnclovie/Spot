//
//  Spot.swift
//  Spot
//
//  Created by Shawn Clovie on 30/09/2016.
//  Copyright © 2016 Shawn Clovie. All rights reserved.
//

import Foundation
import CoreGraphics
#if canImport(UIKit)
import UIKit
#endif

extension Notification: SuffixProtocol {
	public static let spot_errorKey = "error"
	
	public mutating func spot_setUserInfo(key: AnyHashable, value: Any) {
		var info = userInfo ?? [:]
		info[key] = value
		userInfo = info
	}
	
	public mutating func spot_removeUserInfo(key: AnyHashable) -> Any? {
		guard var info = userInfo, let value = info[key] else {return nil}
		info.removeValue(forKey: key)
		userInfo = info
		return value
	}
}

extension Suffix where Base == Notification {

	public subscript(key: AnyHashable) -> Any? {
		base.userInfo?[key]
	}
	
	public var error: Error? {
		self[Notification.spot_errorKey] as? Error
	}
	
	#if os(iOS) || os(tvOS)
	/// Get keyboard height from the notification
	public var keyboardHeight: CGFloat {
		guard let frame = base.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] else {
			return 0
		}
		return (frame as AnyObject).cgRectValue.height
	}
	#endif
}

extension Notification.Name: SuffixProtocol {}

extension Suffix where Base == Notification.Name {
	public func post(error: Swift.Error? = nil,
					 object: Any? = nil,
					 userInfo: [AnyHashable: Any] = [:],
					 by center: NotificationCenter = .default) {
		var note = Notification(name: base, object: object, userInfo: userInfo)
		if let err = error {
			note.spot_setUserInfo(key: Notification.spot_errorKey, value: err)
		}
		center.post(note)
	}
}
