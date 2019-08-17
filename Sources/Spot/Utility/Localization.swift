//
//  Localization.swift
//  Spot
//
//  Created by Shawn Clovie on 7/5/2019.
//  Copyright © 2019 Shawn Clovie. All rights reserved.
//

import Foundation

private let preferredLanguageItem = UserDefaultsItem("localization.preferred", defaultValue: "")

public final class Localization {
	
	public static let preferredLanguageDidChangeEvent = EventObservable<String?>(name: "Localization.preferredLanguageDidChange")
	
	public static let shared = Localization()
	
	private var currentLanguageBundle: Bundle = .main
	
	private init() {
		didChangeCurrentLanguage()
	}
	
	/// Preferred language
	///
	/// To remove, set it to nil.
	public var preferredLanguage: String? {
		get {
			preferredLanguageItem.optional
		}
		set {
			guard preferredLanguageItem.optional != newValue else {
				return
			}
			if let value = newValue, !value.isEmpty {
				preferredLanguageItem.set(value)
			} else {
				preferredLanguageItem.remove()
			}
			didChangeCurrentLanguage()
			Self.preferredLanguageDidChangeEvent.dispatch(newValue)
		}
	}
	
	private func didChangeCurrentLanguage() {
		if let lang = preferredLanguageItem.optional,
			let new = Bundle(url: Bundle.main.bundleURL.appendingPathComponent("\(lang).lproj")) {
			currentLanguageBundle = new
		} else {
			currentLanguageBundle = .main
		}
	}
	
	public func localizedString(key: String,
								replacement: [String: Any]? = nil,
								table: String? = nil,
								language: String? = nil) -> String {
		let bundle = language.flatMap{Bundle.main.spot.localizedBundle(language: $0)} ?? currentLanguageBundle
		var text = bundle.localizedString(forKey: key, value: nil, table: table)
		if !text.isEmpty, let values = replacement {
			for (name, value) in values {
				let str = value as? String ?? String(describing: value)
				text = text.replacingOccurrences(of: "{" + name + "}", with: str)
			}
		}
		return text
	}
}
