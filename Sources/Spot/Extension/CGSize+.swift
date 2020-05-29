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
		(ViewContentMode(rawValue: mode.rawValue) ?? .scaleAspectFit)
			.scale(size: base, toFit: fitSize)
	}
	#else
	public func scaled(toFit fitSize: CGSize, by mode: ViewContentMode = .scaleAspectFit) -> CGSize {
		mode.scale(size: base, toFit: fitSize)
	}
	#endif
}
