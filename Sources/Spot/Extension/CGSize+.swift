//
//  CGSize+.swift
//  Spot
//
//  Created by Shawn Clovie on 5/3/2018.
//  Copyright © 2018 Shawn Clovie. All rights reserved.
//

import CoreGraphics
#if canImport(UIKit)
import UIKit
#endif

extension CGSize: SuffixProtocol {}

extension Suffix where Base == CGSize {
	/// Calculate scaled size to fit size of bounds in mode.
	///
	/// - Parameters:
	///   - fitSize: Bounds' size
	///   - mode: Content mode to fit
	/// - Returns: Scaled size
	#if canImport(UIKit)
	public func scaled(toFit fitSize: CGSize, by mode: UIView.ContentMode = .scaleAspectFit) -> CGSize {
		_scaled(toFit: fitSize, by: ViewContentMode(rawValue: mode.rawValue) ?? .scaleAspectFit)
	}
	#else
	public func scaled(toFit fitSize: CGSize, by mode: ViewContentMode = .scaleAspectFit) -> CGSize {
		_scaled(toFit: fitSize, by: mode)
	}
	#endif
	
	private func _scaled(toFit fitSize: CGSize, by mode: ViewContentMode = .scaleAspectFit) -> CGSize {
		if base == .zero {
			return base
		}
		let raito = CGSize(width: fitSize.width / base.width,
						   height: fitSize.height / base.height)
		var fixedRaito = raito
		switch mode {
		case .scaleAspectFit:
			let minRaito = min(raito.width, raito.height)
			fixedRaito.width = minRaito
			fixedRaito.height = minRaito
		case .scaleAspectFill:
			let maxRaito = max(raito.width, raito.height)
			fixedRaito.width = maxRaito
			fixedRaito.height = maxRaito
		default:break
		}
		return CGSize(width: Int(base.width * fixedRaito.width),
					  height: Int(base.height * fixedRaito.height))
	}
}
