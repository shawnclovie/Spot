//
//  UIImage+.swift
//  SpotLight
//
//  Created by Shawn Clovie on 3/11/16.
//  Copyright © 2016 Shawn Clovie. All rights reserved.
//

import CoreGraphics
#if canImport(UIKit)
import UIKit

extension Suffix where Base: UIImage {
	public var hasAlpha: Bool {
		guard let cg = base.cgImage else {
			return false
		}
		let alpha = cg.alphaInfo
		switch alpha {
		case .first, .last, .premultipliedFirst, .premultipliedLast, .alphaOnly:
			return true
		case .none, .noneSkipFirst, .noneSkipLast:
			return false
		@unknown default:
			return false
		}
	}
	
	public func encode(as encoding: ImageEncoding) -> Data? {
		base.cgImage?.spot.encode(as: encoding, orientation: base.imageOrientation)
	}
	
	/// Create new image by new orientation by flip or rotate.
	///
	/// - Parameter orientation: New orientation
	/// - Returns: New image if no error.
	public func oriented(by orientation: UIImage.Orientation) -> UIImage? {
		if orientation == .up {
			return base
		}
		guard let cg = base.cgImage,
			let newCG = cg.spot.oriented(by: orientation) else {
				return nil
		}
		return .init(cgImage: newCG, scale: base.scale, orientation: .up)
	}
	
	/// Calculate scaled size to fit size of bounds in mode.
	///
	/// - Parameters:
	///   - fitSize: Bounds' size
	///   - mode: Content mode to fit
	/// - Returns: Scaled size
	public func scaledSize(toFit fitSize: CGSize, by mode: UIView.ContentMode = .scaleAspectFit) -> CGSize {
		base.size.spot.scaled(toFit: fitSize, by: mode)
	}
	
	/// Create scaled image to fit size of bounds.
	///
	/// - Parameters:
	///   - fitSize: Bounds' size
	///   - mode: Content mode to fit
	/// - Returns: Scaled image
	public func scaled(toFit fitSize: CGSize, by mode: UIView.ContentMode = .scaleAspectFit) -> UIImage? {
		let scaledSize = self.scaledSize(toFit: fitSize, by: mode)
		if scaledSize.width <= 0 || scaledSize.height <= 0 {
			return nil
		}
		guard let cgImage = base.cgImage else {
			return nil
		}
		guard let newImage = cgImage.spot.resizingImage(to: scaledSize, scale: base.scale) else {
			return nil
		}
		return .init(cgImage: newImage, scale: base.scale, orientation: .up)
	}
}
#endif
