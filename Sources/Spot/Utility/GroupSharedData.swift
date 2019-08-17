//
//  GroupSharedData.swift
//  Spot
//
//  Created by Shawn Clovie on 4/29/16.
//  Copyright © 2016 Shawn Clovie. All rights reserved.
//

import Foundation

public let GroupSharedDataAppHasLaunchedKey = "GroupSharedData.AppHasLaunched"
public let GroupSharedDataOpenAccessKey = "GroupSharedData.OpenAccess"
public let GroupSharedDataTimestampKey = "GroupSharedData.Timestamp"

/// Data item stored with GroupSharedData.
public struct GroupSharedDataItem<T> {
	public let key: String
	public let defaultValue: ()->T
	private let data: GroupSharedData

	public init(_ key: String, defaultValue: @autoclosure @escaping ()->T, in data: GroupSharedData) {
		self.key = key
		self.defaultValue = defaultValue
		self.data = data
	}
	
	public var optional: T? {
		data.object(key: key) as? T
	}
	
	public var value: T {
		optional ?? defaultValue()
	}
	
	public func set(_ value: T) {
		data.set(object: value, key: key)
	}
}

/// Group shared data manager.
public final class GroupSharedData {
	
	public struct SynchronizeInfo {
		public let changedKeys: [String]
		public let oldData: [String: Any]
	}
	
	public let sharedUserDefaults: UserDefaults?
	
	public let synchronizeDidFinishEvent = EventObservable<SynchronizeInfo>(name: "GroupSharedData.synchronizeDidFinish")

	public var hasOpenAccess: Bool {
		sharedUserDefaults?.bool(forKey: GroupSharedDataOpenAccessKey)
			?? false
	}
	
	public var appHasLaunched: Bool {
		sharedUserDefaults?.bool(forKey: GroupSharedDataAppHasLaunchedKey)
			?? false
	}
	
	public init(name: String) {
		sharedUserDefaults = UserDefaults(suiteName: name)
	}
	
	public func setAppHasLaunched() {
		guard !Bundle.main.spot.isPlugin else {
			return
		}
		if let user = sharedUserDefaults {
			user.set(true, forKey: GroupSharedDataAppHasLaunchedKey)
			user.synchronize()
		}
	}
	
	/// Access data stored in UserDefaults (extension bundle) or sharedUserDefaults (app)
	/// - parameter key: Key
	/// - returns: Stored data
	public func object(key: String) -> Any? {
		Bundle.main.spot.isPlugin
			? UserDefaults.standard.object(forKey: key)
			: sharedUserDefaults?.object(forKey: key)
	}
	
	public func set(object: Any, key: String) {
		let runOnExt = Bundle.main.spot.isPlugin
		let time = Date()
		if runOnExt {
			set(value: object, key: key, timestamp: time)
		}
		if !runOnExt || hasOpenAccess,
			let user = sharedUserDefaults {
			set(value: object, key: key, timestamp: time, in: user)
		}
	}
	
	private func set(value: Any?, key: String,
					 timestamp: Date = Date(), in user: UserDefaults = .standard) {
		user.set(value, forKey: key)
		set(timestamp: timestamp, key: key, in: user)
		user.synchronize()
	}
	
	public func timestamps(in user: UserDefaults) -> [String: Any]? {
		user.dictionary(forKey: GroupSharedDataTimestampKey)
	}
	
	public func timestamp(keyed key: String, in user: UserDefaults) -> Date? {
		timestamps(in: user)?[key] as? Date
	}
	
	public func set(timestamp: Date, key: String, in user: UserDefaults) {
		var dict = timestamps(in: user) ?? [:]
		dict[key] = timestamp
		user.set(dict, forKey: GroupSharedDataTimestampKey)
	}
	
	/// Synchronize data between local UserDefaults and group shared UserDefaults.
	/// - parameter complation: Callback while completion.
	public func synchronizeSharedData() {
		guard let userShared = sharedUserDefaults else {
			return
		}
		var valueChangedKeys: [String] = []
		var oldData: [String: Any] = [:]
		let userLocal = UserDefaults.standard
		if let timestamps = timestamps(in: userShared) {
			for (key, value) in timestamps {
				guard let dateShared = value as? Date else {
					continue
				}
				let dateLocal = timestamp(keyed: key, in: userLocal)
				if dateLocal == nil || dateShared.compare(dateLocal!) == .orderedDescending {
					valueChangedKeys.append(key)
					if let data = userLocal.object(forKey: key) {
						oldData[key] = data
					}
					userLocal.set(userShared.object(forKey: key), forKey: key)
					set(timestamp: dateShared, key: key, in: userLocal)
				}
			}
		}
		userLocal.synchronize()
		
		if hasOpenAccess, let timestamps = timestamps(in: userLocal) {
			for (key, value) in timestamps {
				guard let dateLocal = value as? Date else {
					continue
				}
				let dateShared = timestamp(keyed: key, in: userShared)
				if dateShared == nil || dateLocal.compare(dateShared!) == .orderedDescending {
					userShared.set(userLocal.object(forKey: key), forKey: key)
					set(timestamp: dateLocal, key: key, in: userShared)
				}
			}
			userShared.synchronize()
		}
		DispatchQueue.main.async {
			self.synchronizeDidFinishEvent.dispatch(.init(changedKeys: valueChangedKeys, oldData: oldData))
		}
	}
}
