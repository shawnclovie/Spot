//
//  Bundle+Extension.swift
//  Spot
//
//  Created by Shawn Clovie on 22/12/2016.
//  Copyright © 2016 Shawn Clovie. All rights reserved.
//

import Foundation

extension Suffix where Base: Bundle {
	public var isPlugin: Bool {
		base.bundlePath.hasSuffix(".appex")
	}
	
	/// Get bundle property.
	///
	/// - Parameter name: Key name in Info.plist
	/// - Returns: Value if found.
	public func property(named name: String) -> String? {
		base.object(forInfoDictionaryKey: name) as? String
	}
	
	public var identify: String {
		property(named: kCFBundleIdentifierKey as String) ?? ""
	}
	
	public var version: String {
		property(named: kCFBundleVersionKey as String) ?? ""
	}
	
	public var name: String {
		property(named: kCFBundleNameKey as String) ?? ""
	}
	
	public var shortVersion: String {
		property(named: "CFBundleShortVersionString") ?? ""
	}
	
	public func localizedBundle(language: String) -> Bundle? {
		Bundle(url: base.bundleURL.appendingPathComponent("\(language).lproj"))
	}
}

extension Bundle {
	public static var spot_app: Bundle {
		let bundle = main
		if bundle.spot.isPlugin {
			let url = bundle.bundleURL
				.deletingLastPathComponent()
				.deletingLastPathComponent()
			return Bundle(url: url)!
		}
		return bundle
	}
}
