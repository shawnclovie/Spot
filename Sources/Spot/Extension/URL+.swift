//
//  URL+Extension.swift
//  Spot
//
//  Created by Shawn Clovie on 1/9/2017.
//  Copyright © 2017 Shawn Clovie. All rights reserved.
//

import Foundation

extension URL: SuffixProtocol {
	
	/// Application Documents Path
	/// For OSX, "~/Library/Application Support/{BundleID}"
	/// For iOS/Extension, "~/Documents"
	public static var spot_documentsPath: URL {
		#if os(macOS)
		let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
		let appSupportURL = urls[urls.count - 1]
		return appSupportURL.appendingPathComponent(Bundle.main.bundleIdentifier!)
		#else
		return URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!)
		#endif
	}
	
	/// Application Caches Path
	public static var spot_cachesPath: URL {
		URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!)
	}
}

extension Suffix where Base == URL {
	
	public func isDirectoryExists(by manager: FileManager = .default) -> Bool {
		var isDir: ObjCBool = true
		return manager.fileExists(atPath: base.path, isDirectory: &isDir) && isDir.boolValue
	}
	
	public func fileExists(by manager: FileManager = .default) -> Bool {
		manager.fileExists(atPath: base.path)
	}
	
	public func fileAttribute(by manager: FileManager = .default) -> [FileAttributeKey: Any] {
		let attrs = try? manager.attributesOfItem(atPath: base.path)
		return attrs ?? [:]
	}
	
	/// Compare modify date between two files.
	///
	/// - Parameter other: Other file url
	///
	/// - Returns:
	/// 	- Same: files has same date or not exists.
	/// 	- Descending: file1 is exist and newer, or file2 is not exist.
	/// 	- Ascending: file2 is exist and newer, or file1 is not exist.
	public func compareModifyDate(with other: URL) -> ComparisonResult {
		var result: ComparisonResult = .orderedSame
		let date1 = fileAttribute()[.modificationDate] as? Date
		let date2 = other.spot.fileAttribute()[.modificationDate] as? Date
		if date1 != nil || date2 != nil {
			if let date1 = date1 {
				if let date2 = date2 {
					result = date1.compare(date2)
				} else {
					result = .orderedDescending
				}
			} else {
				result = .orderedAscending
			}
		}
		return result
	}
}
